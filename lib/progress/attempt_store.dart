import 'dart:math';

import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

import '../config.dart';
import '../content/answer.dart';
import '../content/ids.dart';
import 'review.dart';

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
    this.elapsed,
    String? id,
  }) : id = id ?? _newId(questionId, at);

  /// Unique and assigned once, at the moment the answer is graded, so the same
  /// attempt can never be counted twice — after a restored backup, say.
  final String id;

  final QuestionId questionId;
  final TopicId topic;

  /// The question's shape. Stored by name, so the enum's names are stored
  /// data: renaming a case splits a question's history in two.
  final QuestionType type;
  final bool correct;
  final DateTime at;

  /// What the student actually entered, as LaTeX. Kept for reviewing wrong
  /// answers — a consistent near-miss means something different from a guess.
  final String? given;

  /// How long the answer took, or null if it took longer than
  /// [AppConfig.maxAnswerTime] — a question left open is not a slow answer.
  final Duration? elapsed;

  static String _newId(QuestionId questionId, DateTime at) =>
      '${questionId.value}.${at.toUtc().microsecondsSinceEpoch}.'
      '${Random().nextInt(1 << 32).toRadixString(36)}';

  factory Attempt.fromRow(Map<String, Object?> row) => Attempt(
    id: row['id'] as String,
    questionId: QuestionId(row['question_id'] as String),
    topic: TopicId(row['topic'] as String),
    type: QuestionType.values.byName(row['type'] as String),
    // SQLite has no boolean type.
    correct: (row['correct'] as int) == 1,
    at: DateTime.fromMillisecondsSinceEpoch(row['at'] as int, isUtc: true),
    given: row['given_tex'] as String?,
    elapsed: switch (row['elapsed_ms'] as int?) {
      final ms? => Duration(milliseconds: ms),
      null => null,
    },
  );

  Map<String, Object?> toRow() => {
    'id': id,
    'question_id': questionId.value,
    'topic': topic.value,
    'type': type.name,
    'correct': correct ? 1 : 0,
    'at': at.toUtc().millisecondsSinceEpoch,
    'given_tex': given,
    'elapsed_ms': elapsed?.inMilliseconds,
  };
}

/// What a student has finished in one lesson.
class TopicProgress {
  const TopicProgress({required this.topic, required this.done});

  final TopicId topic;

  /// Ids of the questions answered correctly at least once. A question is done
  /// or it is not; how many tries it took is in the log if it is ever wanted.
  final Set<QuestionId> done;

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
  bool isDone(QuestionId questionId) =>
      _attempts.any((a) => a.questionId == questionId && a.correct);

  /// When [questionId] is next due, derived from its attempts.
  ///
  /// The log is held oldest first — the query orders by time and new attempts
  /// are appended — which is the order a streak has to be read in.
  Review reviewOf(QuestionId questionId) =>
      Review.of(_attempts.where((a) => a.questionId == questionId));

  TopicProgress progressFor(TopicId topic) => TopicProgress(
    topic: topic,
    done: {
      for (final a in _attempts)
        if (a.topic == topic && a.correct) a.questionId,
    },
  );
}
