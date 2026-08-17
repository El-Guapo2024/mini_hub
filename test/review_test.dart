import 'package:flutter_test/flutter_test.dart';
import 'package:mini_hub/config.dart';
import 'package:mini_hub/content/answer.dart';
import 'package:mini_hub/content/ids.dart';
import 'package:mini_hub/progress/attempt_store.dart';
import 'package:mini_hub/progress/review.dart';

final _epoch = DateTime.utc(2026, 1, 1);

Attempt _attempt({required bool correct, required Duration after}) => Attempt(
  questionId: const QuestionId('bh.1.1.q1'),
  topic: const TopicId('adding'),
  type: QuestionType.numeric,
  correct: correct,
  at: _epoch.add(after),
);

void main() {
  final intervals = AppConfig.current.reviewIntervals;

  test('a question never attempted is due, and says so', () {
    const review = Review(streak: 0, lastSeen: null);

    expect(review.isNew, isTrue);
    expect(review.isDue(_epoch), isTrue);
  });

  test('a new question sorts ahead of anything merely overdue', () {
    const unseen = Review(streak: 0, lastSeen: null);
    final ancient = Review.of([
      _attempt(correct: true, after: Duration.zero),
    ]);

    expect(
      unseen.overdueAt(_epoch),
      greaterThan(ancient.overdueAt(_epoch.add(const Duration(days: 365)))),
    );
  });

  test('each correct answer in a row moves up the ladder', () {
    for (var streak = 1; streak <= intervals.length; streak++) {
      final review = Review.of([
        for (var i = 0; i < streak; i++)
          _attempt(correct: true, after: Duration(minutes: i)),
      ]);

      expect(review.streak, streak);
      expect(
        review.dueAt,
        _epoch
            .add(Duration(minutes: streak - 1))
            .add(intervals[streak.clamp(0, intervals.length - 1)]),
      );
    }
  });

  test('a wrong answer resets the ladder however long the streak was', () {
    final review = Review.of([
      _attempt(correct: true, after: Duration.zero),
      _attempt(correct: true, after: const Duration(days: 1)),
      _attempt(correct: true, after: const Duration(days: 4)),
      _attempt(correct: false, after: const Duration(days: 11)),
    ]);

    expect(review.streak, 0);
    // Back to the shortest interval, so it returns within the session rather
    // than keeping the spacing it had earned before getting it wrong.
    expect(review.dueAt, _epoch.add(const Duration(days: 11)).add(intervals[0]));
  });

  test('a streak past the last interval stays on it rather than overflowing', () {
    final review = Review.of([
      for (var i = 0; i < intervals.length + 5; i++)
        _attempt(correct: true, after: Duration(minutes: i)),
    ]);

    expect(review.isRetired, isTrue);
    expect(
      review.dueAt,
      _epoch
          .add(Duration(minutes: intervals.length + 4))
          .add(intervals.last),
    );
  });

  test('a question is not due until its interval has passed', () {
    final review = Review.of([
      _attempt(correct: true, after: Duration.zero),
    ]);
    final due = review.dueAt!;

    expect(review.isDue(due.subtract(const Duration(seconds: 1))), isFalse);
    expect(review.isDue(due), isTrue);
    expect(review.isDue(due.add(const Duration(days: 1))), isTrue);
  });
}
