import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

import '../config.dart';
import '../content/answer.dart';
import '../content/ids.dart';

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
/// It is a [ChangeNotifier] so that a widget reading progress through
/// [AttemptScope] rebuilds when an attempt is recorded. Screens used to refresh
/// only because they happened to call `setState` for their own reasons, which
/// left any other widget showing a stale count until it was rebuilt for some
/// unrelated reason.
class AttemptStore extends ChangeNotifier {
  AttemptStore._(this._db, this._attempts, {this.unreadableAttempts = 0}) {
    _attempts.forEach(_index);
  }

  final Database _db;

  /// How many stored attempts could not be read at open, and so are missing
  /// from everything below.
  ///
  /// Zero in every ordinary session. It is not zero when the log holds rows
  /// this build cannot name, and then the student's history is short by that
  /// many with nothing on screen to say so — so the number is kept rather than
  /// only logged, for whatever wants to tell them.
  final int unreadableAttempts;

  /// The whole log, in memory: every statistic reads it in full, and a year of
  /// daily practice is a few thousand rows. SQLite is the durable copy here,
  /// not the query engine.
  final List<Attempt> _attempts;

  /// Which questions have been answered correctly, by topic and overall.
  ///
  /// Derived from [_attempts], kept beside it rather than recomputed: the store
  /// notifies on every recorded attempt, and every mounted tile reads its
  /// progress in `build`. Scanning the whole log for each of those turned one
  /// answer into a pass over every attempt ever made, per tile.
  final Set<QuestionId> _correct = {};
  final Map<TopicId, Set<QuestionId>> _correctByTopic = {};

  void _index(Attempt attempt) {
    if (!attempt.correct) return;
    _correct.add(attempt.questionId);
    (_correctByTopic[attempt.topic] ??= {}).add(attempt.questionId);
  }

  /// Rebuilds the derived sets from the log. Cheap enough at this size, and
  /// only reached when a write failed and its attempt was taken back out.
  void _reindex() {
    _correct.clear();
    _correctByTopic.clear();
    _attempts.forEach(_index);
  }

  static const _table = 'attempts';

  /// Bumping this without adding the matching step to [_migrations] is caught
  /// at open time rather than becoming a missing-column error later.
  static const _version = 1;

  /// How to get from schema `n - 1` to schema `n`, keyed by `n`. Empty while
  /// there has only ever been one schema.
  ///
  /// A store that cannot be migrated must not be silently recreated: the log is
  /// the only copy of a student's progress, and `onCreate` would not run on an
  /// existing file anyway. Failing here means [open] throws, which `main` already
  /// treats as "practise without recording" rather than as a failure to start.
  static const Map<int, String> _migrations = {};

  static Future<AttemptStore> open() async {
    final dir = await getApplicationDocumentsDirectory();
    return openAt('${dir.path}/${AppConfig.current.databaseFile}');
  }

  /// Opens a store at a specific path. Tests use this with an ffi factory,
  /// having no platform channels to reach the documents directory.
  static Future<AttemptStore> openAt(String path) async {
    final db = await openDatabase(
      path,
      version: _version,
      onUpgrade: (db, from, to) async {
        for (var step = from + 1; step <= to; step++) {
          final migration = _migrations[step];
          if (migration == null) {
            throw StateError(
              'no migration to schema $step: the attempt log on this device is '
              'at $from and this build expects $to',
            );
          }
          await db.execute(migration);
        }
      },
      // A build older than the file on disk cannot know what the newer schema
      // added. Refusing is the only safe answer; the alternative sqflite offers
      // is deleting the log.
      onDowngrade: (db, from, to) async => throw StateError(
        'the attempt log on this device is at schema $from, newer than the $to '
        'this build expects',
      ),
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

    // Row by row, so one the app cannot read costs that row rather than the
    // log. `type` reaches the database as a plain string, so a question type
    // renamed in a later release meets its own old rows and cannot name them
    // — read all at once, that threw, open failed, and a student lost every
    // attempt they had ever made, along with the recording of any more.
    final attempts = <Attempt>[];
    var unreadable = 0;
    for (final row in rows) {
      try {
        attempts.add(Attempt.fromRow(row));
      } on Object catch (error) {
        unreadable++;
        debugPrint('skipping an unreadable attempt: $error');
      }
    }
    if (unreadable > 0) {
      debugPrint('$unreadable of ${rows.length} attempts could not be read');
    }
    return AttemptStore._(db, attempts, unreadableAttempts: unreadable);
  }

  List<Attempt> get all => List.unmodifiable(_attempts);

  /// Records an attempt, in memory first so the UI can show it immediately.
  ///
  /// If the write fails the attempt is taken back out again, rather than
  /// leaving a green check on screen that a restart would silently undo. The
  /// returned future completes once committed; UI callers may ignore it.
  Future<void> record(Attempt attempt) async {
    // Replaying an attempt already held is a no-op, matching what the insert
    // below does with the row. Adding it a second time would leave memory
    // holding two of what the log holds one of, and a restart would silently
    // change the count back.
    if (_attempts.any((a) => a.id == attempt.id)) return;

    _attempts.add(attempt);
    _index(attempt);
    notifyListeners();
    try {
      final rowId = await _db.insert(
        _table,
        attempt.toRow(),
        // Replaying the same attempt is a no-op rather than an error.
        conflictAlgorithm: ConflictAlgorithm.ignore,
      );
      // Ignoring a conflict is silent, and the row it collided with need not
      // be one held in memory: a row skipped at open as unreadable still holds
      // its id here. Left unchecked, the answer was shown as recorded and was
      // gone at the next restart.
      if (rowId == 0) {
        throw StateError(
          'the attempt log already holds a row with id ${attempt.id}',
        );
      }
    } on Object {
      _attempts.remove(attempt);
      _reindex();
      notifyListeners();
      rethrow;
    }
  }

  Future<void> clear() async {
    _attempts.clear();
    _reindex();
    notifyListeners();
    await _db.delete(_table);
  }

  /// Closes the database and drops any listeners. The store is unusable after.
  Future<void> close() async {
    dispose();
    await _db.close();
  }

  /// Whether this question has ever been answered correctly.
  bool isDone(QuestionId questionId) => _correct.contains(questionId);

  TopicProgress progressFor(TopicId topic) => TopicProgress(
    topic: topic,
    done: Set.unmodifiable(_correctByTopic[topic] ?? const {}),
  );
}
