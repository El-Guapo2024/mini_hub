import 'dart:math';

import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

import '../config.dart';

/// One graded response. The log is the only thing stored; what the app shows
/// is derived from it, so changing what progress means is a recompute rather
/// than a migration. More is recorded than is read today for that reason.
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

/// What a student has finished in one lesson.
class TopicProgress {
  const TopicProgress({required this.topic, required this.done});

  final String topic;

  /// Ids of the questions answered correctly at least once. A question is done
  /// or it is not; how many tries it took is in the log if it is ever wanted.
  final Set<String> done;

  int get count => done.length;
}

/// An append-only log of attempts, stored in SQLite.
///
/// SQLite is here for durability, not speed: at this size no query needs an
/// index, but every write is a transaction, so a process killed mid-write leaves
/// the log intact rather than truncated. Rows are never updated or deleted.
class AttemptStore {
  AttemptStore._(this._db, this._attempts);

  final Database _db;

  /// The whole log, in memory: every statistic reads it in full, and a year of
  /// daily practice is a few thousand rows. SQLite is the durable copy here,
  /// not the query engine.
  final List<Attempt> _attempts;

  static const _table = 'attempts';

  static Future<AttemptStore> open() async {
    final dir = await getApplicationDocumentsDirectory();
    return openAt('${dir.path}/${AppConfig.current.databaseFile}');
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

  /// The returned future completes once committed; UI callers may ignore it,
  /// since the in-memory list updates first.
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

  /// Whether this question has ever been answered correctly.
  bool isDone(String questionId) =>
      _attempts.any((a) => a.questionId == questionId && a.correct);

  TopicProgress progressFor(String topic) => TopicProgress(
    topic: topic,
    done: {
      for (final a in _attempts)
        if (a.topic == topic && a.correct) a.questionId,
    },
  );
}
