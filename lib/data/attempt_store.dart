import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:path_provider/path_provider.dart';

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

  factory Attempt.fromJson(Map<String, dynamic> json) => Attempt(
    id: json['id'] as String?,
    questionId: json['q'] as String,
    topic: json['t'] as String,
    type: json['k'] as String? ?? 'numerical',
    correct: json['c'] as bool,
    at: DateTime.fromMillisecondsSinceEpoch(json['at'] as int, isUtc: true),
    given: json['g'] as String?,
    elapsedMs: json['ms'] as int?,
  );

  // Keys are terse because this file grows one entry per answered question and
  // is read in full on launch.
  Map<String, dynamic> toJson() => {
    'id': id,
    'q': questionId,
    't': topic,
    'k': type,
    'c': correct,
    'at': at.toUtc().millisecondsSinceEpoch,
    if (given != null) 'g': given,
    if (elapsedMs != null) 'ms': elapsedMs,
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

/// An append-only log of attempts, one JSON object per line.
///
/// Deliberately not SQLite. The log is a few hundred KB even after a year of
/// daily practice, it is only ever appended to and read whole, and there is no
/// query a database would answer faster than a loop over a list. SQLite would
/// add a schema, migrations and an async open for no gain at this size.
///
/// One object per line rather than one JSON array, for two reasons: recording an
/// answer appends a single line instead of re-encoding the entire history, and a
/// write cut short by the process dying costs the last line rather than the
/// whole file.
class AttemptStore {
  AttemptStore._(this._file, this._attempts, this.skippedRows);

  final File _file;
  final List<Attempt> _attempts;

  /// Lines that could not be read back, from a torn write or a hand-edited
  /// file. Surfaced rather than hidden so a bug here can't pass for a student
  /// who simply hasn't practised.
  final int skippedRows;

  /// Serializes writes. [record] is called from the UI without awaiting, so two
  /// quick answers can otherwise overlap mid-append and interleave their bytes.
  Future<void> _writes = Future.value();

  /// Attempts counted by [TopicStats.recent].
  static const rollingWindow = 10;

  /// Days after which a lesson counts as fully stale.
  static const staleAfterDays = 30;

  static Future<AttemptStore> open() async {
    final dir = await getApplicationDocumentsDirectory();
    return openAt(File('${dir.path}/attempts.jsonl'));
  }

  /// Opens a store backed by a specific file. Used by tests, which have no
  /// platform channels and so cannot ask for the documents directory.
  static Future<AttemptStore> openAt(File file) async {
    final attempts = <Attempt>[];
    var skipped = 0;

    if (file.existsSync()) {
      for (final line in const LineSplitter().convert(
        await file.readAsString(),
      )) {
        if (line.trim().isEmpty) continue;
        try {
          attempts.add(
            Attempt.fromJson(jsonDecode(line) as Map<String, dynamic>),
          );
        } on Object {
          // One unreadable line must not cost the rest of the history, and must
          // never stop the app from starting. Anything malformed is dropped:
          // a bad row is not worth a crash on launch.
          skipped++;
        }
      }
      attempts.sort((a, b) => a.at.compareTo(b.at));
    }
    return AttemptStore._(file, attempts, skipped);
  }

  List<Attempt> get all => List.unmodifiable(_attempts);

  /// Appends an attempt. The returned future completes once it is on disk;
  /// callers in the UI may safely ignore it, since the in-memory list is
  /// updated first and writes are ordered.
  Future<void> record(Attempt attempt) {
    _attempts.add(attempt);
    return _enqueue(
      () => _file.writeAsString(
        '${jsonEncode(attempt.toJson())}\n',
        mode: FileMode.append,
        flush: true,
      ),
    );
  }

  Future<void> clear() {
    _attempts.clear();
    return _enqueue(() => _file.writeAsString('', flush: true));
  }

  /// Runs [write] after every write already queued, whether or not those
  /// succeeded — one failed append must not wedge the queue forever.
  Future<void> _enqueue(Future<void> Function() write) {
    final next = _writes.then((_) => write(), onError: (_) => write());
    _writes = next.catchError((_) {});
    return next;
  }

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
