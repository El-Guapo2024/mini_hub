import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:math_keyboard/math_keyboard.dart';
import 'package:mini_hub/content/answer.dart';
import 'package:mini_hub/content/ids.dart';
import 'package:mini_hub/content/question.dart';
import 'package:mini_hub/ui/widgets/question_widget.dart';

/// A question you cannot get must still be a question you can leave.
///
/// A miss used to print `Answer: 54` under the field, which meant every
/// question had a way out — and the fastest way through the bank was to
/// guess, read the answer and move on, which is not practice. Taking the
/// reveal away without putting something back would strand a student on a
/// card they cannot answer, first in the deck every time they open the
/// topic. Skip is that something.
void main() {
  final question = Question(
    id: const QuestionId('bh.test.q1'),
    topic: const TopicId('t'),
    prompt: '2 + 2 =',
    answer: const NumericAnswer(value: 4),
  );

  /// The card as the practice screen builds it, with somewhere to skip to.
  Future<void> pumpCard(WidgetTester tester, {VoidCallback? onSkip}) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: MathKeyboardViewInsets(
            child: QuestionWidget(question: question, onSkip: onSkip),
          ),
        ),
      ),
    );
    await tester.pump();
  }

  /// Types an answer and submits it, driving the field's callbacks rather
  /// than tapping — tapping opens the maths keyboard, whose animation never
  /// settles under the test binding.
  Future<void> answer(WidgetTester tester, String text) async {
    final field = tester.widget<MathField>(find.byType(MathField));
    field.onChanged!(text);
    await tester.pump();
    field.onSubmitted!(text);
    await tester.pump();
    await tester.runAsync(() => Future<void>.delayed(Duration.zero));
    await tester.pump();
  }

  testWidgets('a miss does not print the answer', (tester) async {
    await pumpCard(tester, onSkip: () {});

    await answer(tester, '99');

    expect(find.byIcon(Icons.close), findsOneWidget, reason: 'marked wrong');
    expect(
      find.textContaining('Answer:'),
      findsNothing,
      reason: 'the answer is the thing being asked for',
    );
    // Nor anywhere else on the card, under another label.
    expect(find.text('4'), findsNothing);
  });

  testWidgets('a miss leaves the field answerable again', (tester) async {
    await pumpCard(tester, onSkip: () {});

    await answer(tester, '99');
    expect(find.byIcon(Icons.close), findsOneWidget);

    // Typing clears the result, so the second go starts clean rather than
    // under a red border from the first.
    await answer(tester, '4');
    expect(find.byIcon(Icons.check), findsOneWidget);
    expect(find.byIcon(Icons.close), findsNothing);
  });

  testWidgets('skip calls back without answering the question', (tester) async {
    var skipped = 0;
    await pumpCard(tester, onSkip: () => skipped++);

    await tester.tap(find.text('Skip'));
    await tester.pump();

    expect(skipped, 1);
    // A skip is the absence of an answer, not a wrong one: nothing is graded,
    // so nothing is marked and nothing is recorded.
    expect(find.byIcon(Icons.close), findsNothing);
    expect(find.byIcon(Icons.check), findsNothing);
  });

  testWidgets('skip is offered after a miss, when it is most wanted', (
    tester,
  ) async {
    await pumpCard(tester, onSkip: () {});

    await answer(tester, '99');

    expect(
      find.text('Skip'),
      findsOneWidget,
      reason:
          'the reveal used to occupy this row after a miss. It is the moment '
          'a student is most stuck, so it is the moment the way out must be '
          'on screen.',
    );
  });

  testWidgets('no skip where there is nowhere to skip to', (tester) async {
    await pumpCard(tester);

    expect(
      find.text('Skip'),
      findsNothing,
      reason: 'the last card in a deck has nothing after it',
    );
  });
}
