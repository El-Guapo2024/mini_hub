import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:math_keyboard/math_keyboard.dart';
import 'package:mini_hub/content/answer.dart';
import 'package:mini_hub/content/ids.dart';
import 'package:mini_hub/content/question.dart';
import 'package:mini_hub/ui/widgets/question_widget.dart';

/// What the app asks of a student who cannot see it well, or at all.
///
/// The placeholder in the answer field was white38, which is 3.44:1 against
/// this background — under the 4.5:1 a reader needs — and it is the only thing
/// in the field before an answer is typed.
void main() {
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
}
