import 'dart:math';

import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

/// One graded response. Everything the statistics need is derived from these
/// rows, so nothing aggregated is ever stored — a rolling average that turns
/// out to be defined wrong is a recompute, not a migration.
class Attempt {
  Attempt({
    required this.questionId,
    required this.topic,
    required this.type,
    required this.correct,
    required this.at,
    this.given,
    this.elapsedMs,
    String? id,
  }) : id = id ?? _newId(questionId, at);

  /// Unique and assigned once, at the moment the answer is graded, so the same
  /// attempt can never be counted twice — after a restored backup, say.
  final String id;

  final String questionId;
  final String topic;

  /// The question's shape, so accuracy can be broken down per type.
  final String type;
  final bool correct;
  final DateTime at;

  /// What the student actually entered, as LaTeX. Kept for reviewing wrong
  /// answers — a consistent near-miss means something different from a guess.
  final String? given;
  final int? elapsedMs;

  static String _newId(String questionId, DateTime at) =>
      '$questionId.${at.toUtc().microsecondsSinceEpoch}.'
      '${Random().nextInt(1 << 32).toRadixString(36)}';

  factory Attempt.fromRow(Map<String, Object?> row) => Attempt(
    id: row['id'] as String,
    questionId: row['question_id'] as String,
    topic: row['topic'] as String,
    type: row['type'] as String,
    // SQLite has no boolean type.
    correct: (row['correct'] as int) == 1,
    at: DateTime.fromMillisecondsSinceEpoch(row['at'] as int, isUtc: true),
    given: row['given_tex'] as String?,
    elapsedMs: row['elapsed_ms'] as int?,
  );

  Map<String, Object?> toRow() => {
    'id': id,
    'question_id': questionId,
    'topic': topic,
    'type': type,
    'correct': correct ? 1 : 0,
    'at': at.toUtc().millisecondsSinceEpoch,
    'given_tex': given,
    'elapsed_ms': elapsedMs,
  };
}

/// Accuracy and recency for one lesson, derived on demand.
class TopicStats {
  const TopicStats({
    required this.topic,
    required this.attempts,
    required this.correct,
    required this.recent,
    required this.lastSeen,
    required this.streak,
  });

  final String topic;
  final int attempts;
  final int correct;

  /// Accuracy over the last [AttemptStore.rollingWindow] attempts. This is what
  /// a student feels as "how am I doing now"; lifetime accuracy lags for weeks
  /// after they've actually improved.
  final double recent;
  final DateTime? lastSeen;

  /// Consecutive correct answers, most recent first.
  final int streak;

  double get accuracy => attempts == 0 ? 0 : correct / attempts;

  /// How stale this lesson is, 0 (just practised) to 1 (due). Drives review
  /// ordering: a weak topic untouched for a month should outrank a strong one
  /// practised yesterday.
  double freshness(DateTime now) {
    if (lastSeen == null) return 1;
    final days = now.difference(lastSeen!).inMinutes / (60 * 24);
    final decay = days / AttemptStore.staleAfterDays;
    return decay.clamp(0.0, 1.0);
  }

  /// Higher means more worth practising: weak and stale beats strong and fresh.
  double priority(DateTime now) =>
      attempts == 0 ? 1 : (1 - recent) * 0.6 + freshness(now) * 0.4;
}

/// An append-only log of attempts, stored in SQLite.
///
/// SQLite earns its place here for durability rather than speed: at this size no
/// query needs an index, but every write is a transaction, so a process killed
/// mid-write leaves the log intact instead of truncated. Hand-rolling that over
/// a text file means owning the failure modes yourself.
///
/// Rows are never updated or deleted in normal use. The statistics below all
/// derive from them, so nothing aggregated is stored and redefining a figure is
/// a recompute rather than a migration.
class AttemptStore {
  AttemptStore._(this._db, this._attempts);

  final Database _db;

  /// The whole log, held in memory. It is read in full for every statistic and
  /// is small enough to keep — a year of daily practice is a few thousand rows.
  /// SQLite is the durable copy, not the query engine.
  final List<Attempt> _attempts;

  /// Attempts counted by [TopicStats.recent].
  static const rollingWindow = 10;

  /// Days after which a lesson counts as fully stale.
  static const staleAfterDays = 30;

  static const _table = 'attempts';

  static Future<AttemptStore> open() async {
    final dir = await getApplicationDocumentsDirectory();
    return openAt('${dir.path}/attempts.db');
  }

  /// Opens a store at a specific path. Tests use this with an ffi factory,
  /// having no platform channels to reach the documents directory.
  static Future<AttemptStore> openAt(String path) async {
    final db = await openDatabase(
      path,
      version: 1,
      onCreate: (db, _) async {
        // `id` is the primary key, so the same attempt can never land twice.
        await db.execute('''
          CREATE TABLE $_table (
            id TEXT PRIMARY KEY,
            question_id TEXT NOT NULL,
            topic TEXT NOT NULL,
            type TEXT NOT NULL,
            correct INTEGER NOT NULL,
            at INTEGER NOT NULL,
            given_tex TEXT,
            elapsed_ms INTEGER
          )
        ''');
        await db.execute('CREATE INDEX idx_topic ON $_table (topic)');
      },
    );

    final rows = await db.query(_table, orderBy: 'at ASC');
    return AttemptStore._(db, rows.map(Attempt.fromRow).toList());
  }

  List<Attempt> get all => List.unmodifiable(_attempts);

  /// Records an attempt. The returned future completes once it is committed;
  /// callers in the UI may ignore it, since the in-memory list updates first.
  Future<void> record(Attempt attempt) async {
    _attempts.add(attempt);
    await _db.insert(
      _table,
      attempt.toRow(),
      // Replaying the same attempt is a no-op rather than an error.
      conflictAlgorithm: ConflictAlgorithm.ignore,
    );
  }

  Future<void> clear() async {
    _attempts.clear();
    await _db.delete(_table);
  }

  Future<void> close() => _db.close();

  TopicStats statsFor(String topic) {
    final rows = _attempts.where((a) => a.topic == topic).toList();
    return _statsFrom(topic, rows);
  }

  Map<String, TopicStats> statsByTopic() {
    final grouped = <String, List<Attempt>>{};
    for (final a in _attempts) {
      grouped.putIfAbsent(a.topic, () => []).add(a);
    }
    return {
      for (final entry in grouped.entries)
        entry.key: _statsFrom(entry.key, entry.value),
    };
  }

  /// Accuracy per question type, for spotting a shape that is uniformly weak
  /// regardless of topic — estimation problems, say.
  Map<String, double> accuracyByType() {
    final total = <String, int>{};
    final right = <String, int>{};
    for (final a in _attempts) {
      total[a.type] = (total[a.type] ?? 0) + 1;
      if (a.correct) right[a.type] = (right[a.type] ?? 0) + 1;
    }
    return {
      for (final type in total.keys) type: (right[type] ?? 0) / total[type]!,
    };
  }

  /// Topics most worth practising next, weakest and stalest first. Topics with
  /// no attempts are absent — the caller knows the full lesson list, this only
  /// knows what has been tried.
  List<TopicStats> reviewQueue(DateTime now) {
    final stats = statsByTopic().values.toList();
    stats.sort((a, b) => b.priority(now).compareTo(a.priority(now)));
    return stats;
  }

  static TopicStats _statsFrom(String topic, List<Attempt> rows) {
    if (rows.isEmpty) {
      return TopicStats(
        topic: topic,
        attempts: 0,
        correct: 0,
        recent: 0,
        lastSeen: null,
        streak: 0,
      );
    }
    rows.sort((a, b) => a.at.compareTo(b.at));

    final window = rows.length <= rollingWindow
        ? rows
        : rows.sublist(rows.length - rollingWindow);
    final windowCorrect = window.where((a) => a.correct).length;

    var streak = 0;
    for (final a in rows.reversed) {
      if (!a.correct) break;
      streak++;
    }

    return TopicStats(
      topic: topic,
      attempts: rows.length,
      correct: rows.where((a) => a.correct).length,
      recent: windowCorrect / window.length,
      lastSeen: rows.last.at,
      streak: streak,
    );
  }
}
