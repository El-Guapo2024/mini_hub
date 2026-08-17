import '../config.dart';
import 'attempt_store.dart';

/// When a question should next be practised, worked out from its attempts.
///
/// Nothing here is stored. The attempt log is the only truth, and a schedule
/// is a reading of it — so changing how scheduling works is a recompute rather
/// than a migration, and a scheduler can be changed without invalidating a
/// history recorded under the old one.
class Review {
  const Review({required this.streak, required this.lastSeen, this.dueAt});

  /// Consecutive correct answers, most recent last. A wrong answer sends it
  /// back to zero: getting it wrong today means today is what counts, however
  /// well it went a month ago.
  final int streak;

  /// When it was last answered, right or wrong. Null if never.
  final DateTime? lastSeen;

  /// When it comes up again. Null for a question never seen, which is due in
  /// the sense that it has never been done at all.
  final DateTime? dueAt;

  bool get isNew => lastSeen == null;

  /// Learned as far as the ladder goes. Still reviewed, just rarely.
  bool get isRetired => streak >= AppConfig.current.reviewIntervals.length;

  bool isDue(DateTime now) => dueAt == null || !dueAt!.isAfter(now);

  /// How overdue, for ordering a session. Negative once it is not yet due.
  Duration overdueAt(DateTime now) =>
      dueAt == null ? const Duration(days: 3650) : now.difference(dueAt!);

  /// The schedule [attempts] imply for one question, oldest attempt first.
  ///
  /// Expects the attempts of a single question; it does not filter, because
  /// the caller already knows which question it is asking about.
  factory Review.of(Iterable<Attempt> attempts) {
    DateTime? lastSeen;
    var streak = 0;

    for (final attempt in attempts) {
      streak = attempt.correct ? streak + 1 : 0;
      lastSeen = attempt.at;
    }

    if (lastSeen == null) {
      return const Review(streak: 0, lastSeen: null);
    }

    final intervals = AppConfig.current.reviewIntervals;
    // A wrong answer has a streak of zero and so takes the first interval,
    // which is short on purpose: it comes back in this session.
    final interval = intervals[streak.clamp(0, intervals.length - 1)];
    return Review(
      streak: streak,
      lastSeen: lastSeen,
      dueAt: lastSeen.add(interval),
    );
  }
}
