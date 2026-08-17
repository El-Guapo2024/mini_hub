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

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MathKeyboardViewInsets(
              // A PageView, as the practice tab uses: each question is given
              // the whole page, which is the layout that has to hold up.
              child: PageView.builder(
                itemCount: questions.length,
                itemBuilder: (context, index) =>
                    QuestionWidget(question: questions[index]),
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      expect(tester.takeException(), isNull);
      expect(find.byType(QuestionWidget), findsWidgets);
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
