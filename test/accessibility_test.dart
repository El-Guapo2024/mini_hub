import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:math_keyboard/math_keyboard.dart';
import 'package:mini_hub/content/answer.dart';
import 'package:mini_hub/content/fraction.dart';
import 'package:mini_hub/content/ids.dart';
import 'package:mini_hub/content/question.dart';
import 'package:mini_hub/ui/widgets/question_widget.dart';

/// What the app asks of a student who cannot see it well, or at all.
///
/// The placeholder in the answer field was white38, which is 3.44:1 against
/// this background — under the 4.5:1 a reader needs — and it is the only thing
/// in the field before an answer is typed.
void main() {
  Widget asking(Answer answer) => MaterialApp(
    theme: ThemeData.dark(),
    home: Scaffold(
      backgroundColor: Colors.black,
      body: MathKeyboardViewInsets(
        child: QuestionWidget(
          question: Question(
            id: const QuestionId('q'),
            prompt: '2+2=',
            topic: const TopicId('squares'),
            answer: answer,
          ),
        ),
      ),
    ),
  );

  Widget practising() => MaterialApp(
    theme: ThemeData.dark(),
    home: Scaffold(
      backgroundColor: Colors.black,
      body: MathKeyboardViewInsets(
        child: QuestionWidget(
          question: const Question(
            id: QuestionId('q'),
            prompt: '2+2=',
            topic: TopicId('squares'),
            answer: NumericAnswer(value: 4),
          ),
        ),
      ),
    ),
  );

  testWidgets('a question screen is readable', (tester) async {
    await tester.pumpWidget(practising());
    await tester.pump(const Duration(milliseconds: 300));

    await expectLater(tester, meetsGuideline(textContrastGuideline));
  });

  testWidgets('a question screen can be operated', (tester) async {
    await tester.pumpWidget(practising());
    await tester.pump(const Duration(milliseconds: 300));

    await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
    await expectLater(tester, meetsGuideline(iOSTapTargetGuideline));
  });

  testWidgets('the typing-direction toggle announces itself', (tester) async {
    final semantics = tester.ensureSemantics();

    var rightToLeft = false;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: StatefulBuilder(
            builder: (context, setState) => Row(
              children: [
                const Text('1 of 59   ·   0 done'),
                const Spacer(),
                MergeSemantics(
                  child: Semantics(
                    container: true,
                    toggled: rightToLeft,
                    label: 'Type right to left',
                    child: IconButton(
                      onPressed: () =>
                          setState(() => rightToLeft = !rightToLeft),
                      icon: const Icon(Icons.swap_horiz, size: 20),
                      tooltip: 'Typing left to right',
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    // The name, the state and the tap have to reach the reader together. Split
    // apart, it stops on the half that can be pressed and finds it nameless;
    // merged upwards, they land on a node covering the whole pane, read out
    // with the counter beside it.
    expect(
      tester.getSemantics(find.byType(IconButton)),
      matchesSemantics(
        label: 'Type right to left',
        tooltip: 'Typing left to right',
        isButton: true,
        hasToggledState: true,
        isToggled: false,
        isEnabled: true,
        isFocusable: true,
        hasEnabledState: true,
        hasTapAction: true,
        hasFocusAction: true,
      ),
    );

    semantics.dispose();
  });

  // Every answer that says how it will be graded says it in this text, and a
  // fixture whose hint is null never renders it — which is how it stayed
  // unreadable after the placeholder beside it was fixed.
  for (final answer in const <Answer>[
    ApproxAnswer(low: 1, high: 2),
    FractionAnswer(value: Fraction(1, 2)),
    ComplexAnswer(real: 16, imaginary: 16),
    BaseAnswer(value: 16, base: 8),
  ]) {
    testWidgets('the ${answer.kind.name} grading rule is readable', (
      tester,
    ) async {
      await tester.pumpWidget(asking(answer));
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text(answer.inputHint!), findsOneWidget);
      await expectLater(tester, meetsGuideline(textContrastGuideline));
    });
  }
}
