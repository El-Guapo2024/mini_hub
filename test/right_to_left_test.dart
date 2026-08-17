import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:math_keyboard/math_keyboard.dart';
import 'package:mini_hub/content/answer.dart';
import 'package:mini_hub/content/ids.dart';
import 'package:mini_hub/content/question.dart';
import 'package:mini_hub/ui/widgets/question_view.dart';
import 'package:mini_hub/ui/widgets/question_widget.dart';

const _question = Question(
  id: QuestionId('bh.1.1.q1'),
  prompt: r'54 \times 11 =',
  topic: TopicId('multiplying_by_11_trick'),
  answer: NumericAnswer(value: 594),
);

void main() {
  group('when to step the cursor back', () {
    test('typing right to left steps back over what was entered', () {
      expect(
        stepsBack(rightToLeft: true, before: '4', after: '94'),
        isTrue,
      );
    });

    test('typing left to right never steps back', () {
      expect(
        stepsBack(rightToLeft: false, before: '4', after: '94'),
        isFalse,
      );
    });

    test('deleting does not step back, whichever way round', () {
      // Backspace already moves left. Stepping again would walk the cursor
      // through the answer a character at a time for every key pressed.
      expect(
        stepsBack(rightToLeft: true, before: '594', after: '59'),
        isFalse,
      );
    });

    test('a change that adds nothing does not step back', () {
      // Moving the cursor notifies without changing the value.
      expect(
        stepsBack(rightToLeft: true, before: '594', after: '594'),
        isFalse,
      );
    });
  });

  testWidgets('direction is the input\'s business, not grading\'s', (
    tester,
  ) async {
    for (final rightToLeft in [false, true]) {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MathKeyboardViewInsets(
              child: QuestionView(
                question: _question,
                rightToLeft: rightToLeft,
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      expect(tester.takeException(), isNull);
      expect(find.byType(MathField), findsOneWidget);
    }

    // The answer is 594 in either direction: which end it was typed from is
    // not something the grader can or should see.
    expect(_question.answer.accepts('594'), isTrue);
    expect(_question.answer.accepts('495'), isFalse);
  });
}
