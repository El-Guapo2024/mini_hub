import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:math_keyboard/math_keyboard.dart';
import 'package:mini_hub/config.dart';
import 'package:mini_hub/content/answer.dart';
import 'package:mini_hub/content/ids.dart';
import 'package:mini_hub/content/question.dart';
import 'package:mini_hub/ui/widgets/question_widget.dart';

import 'support/pump.dart';

const _question = Question(
  id: QuestionId('bh.1.2.1.q1'),
  prompt: '2+2=',
  answer: NumericAnswer(value: 4),
  topic: TopicId('multiplying_by_11_trick'),
);

/// Past the pause, so any pending advance has had its chance to fire.
final _afterTheWait = AppConfig.current.advanceAfter * 2;

void main() {
  testWidgets('a correct answer advances, once', (tester) async {
    var advances = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: MathKeyboardViewInsets(
            child: QuestionWidget(
              question: _question,
              onCorrect: () => advances++,
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    // Answered right twice inside the pause — a student correcting a typo.
    // Each answer restarts the wait rather than queueing a second hop.
    await answer(tester, '4');
    await answer(tester, '4');
    expect(advances, 0, reason: 'not until the student has seen the green');

    await tester.pump(_afterTheWait);
    expect(advances, 1);
  });

  testWidgets('a card swiped away does not advance the deck', (tester) async {
    // The card is answered, then disposed before the pause is up — swiped
    // past, or the topic closed. Its pending advance must go with it, or the
    // deck jumps from wherever the student has since got to.
    var advances = 0;
    Widget host({required bool showing}) => MaterialApp(
      home: Scaffold(
        body: MathKeyboardViewInsets(
          child: showing
              ? QuestionWidget(question: _question, onCorrect: () => advances++)
              : const SizedBox.shrink(),
        ),
      ),
    );

    await tester.pumpWidget(host(showing: true));
    await tester.pump();
    await answer(tester, '4');

    await tester.pumpWidget(host(showing: false));
    await tester.pump(_afterTheWait);

    expect(advances, 0);
    expect(tester.takeException(), isNull);
  });

  testWidgets('a wrong answer stays put', (tester) async {
    var advances = 0;
    await pumpQuestion(tester, _question);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: MathKeyboardViewInsets(
            child: QuestionWidget(
              question: _question,
              onCorrect: () => advances++,
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    await answer(tester, '5');
    await tester.pump(_afterTheWait);

    expect(advances, 0, reason: 'the answer is still on screen to be read');
  });
}
