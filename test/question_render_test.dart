import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:math_keyboard/math_keyboard.dart';
import 'package:mini_hub/content/answer.dart';
import 'package:mini_hub/content/fraction.dart';
import 'package:mini_hub/content/ids.dart';
import 'package:mini_hub/content/question.dart';
import 'package:mini_hub/ui/widgets/question_widget.dart';

/// Renders real generated questions the way the practice tab does, so a
/// question the view cannot build fails here rather than on a device.
void main() {
  final topics = Directory('assets/content')
      .listSync(recursive: true)
      .whereType<File>()
      .where((f) => f.path.endsWith('questions.json'))
      .toList();

  test('there are generated topics to render', () {
    expect(topics, isNotEmpty);
  });

  for (final file in topics) {
    testWidgets('every question in ${file.parent.path} renders', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(393, 852));

      final questions = (jsonDecode(file.readAsStringSync()) as List<dynamic>)
          .map((q) => Question.fromJson(q as Map<String, dynamic>))
          .toList();

      // Built one at a time rather than handed to a PageView. The practice tab
      // uses a PageView, and this test used to as well — but it builds only the
      // visible page and its neighbour, so a test named for every question was
      // rendering one of them, and a question the view could not build passed
      // here and failed on a device.
      //
      // Each is given the whole page, which is what the PageView gives it, so
      // the layout under test is still the real one.
      var built = 0;
      for (final question in questions) {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: MathKeyboardViewInsets(
                child: QuestionWidget(
                  key: ValueKey(question.id.value),
                  question: question,
                ),
              ),
            ),
          ),
        );
        await tester.pump();

        expect(
          tester.takeException(),
          isNull,
          reason: '${question.id.value} does not render',
        );
        built++;
      }

      expect(
        built,
        questions.length,
        reason: 'every question in the file was rendered',
      );
    });
  }

  testWidgets('every answer type in the bank renders', (tester) async {
    // The names attempts are recorded under. They reach the statistics as
    // plain strings, so a rename here would silently split a topic's history
    // in two rather than fail to compile.
    const types = {
      QuestionType.numeric: NumericAnswer(value: 4),
      QuestionType.estimate: ApproxAnswer(low: 1, high: 2),
      QuestionType.complex: ComplexAnswer(real: 16, imaginary: 16),
      QuestionType.fraction: FractionAnswer(value: Fraction(1, 2)),
      QuestionType.base: BaseAnswer(value: 16, base: 8),
    };
    expect(types.keys, containsAll(QuestionType.values));

    for (final entry in types.entries) {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MathKeyboardViewInsets(
              child: QuestionWidget(
                question: Question(
                  id: const QuestionId('q'),
                  prompt: '2+2=',
                  topic: const TopicId('squares'),
                  answer: entry.value,
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      expect(entry.value.kind, entry.key);
      expect(find.byType(MathField), findsOneWidget);
    }
  });
}
