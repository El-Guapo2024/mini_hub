import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:flutter_markdown_plus_latex/flutter_markdown_plus_latex.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mini_hub/models/fraction.dart';
import 'package:mini_hub/models/ids.dart';
import 'package:markdown/markdown.dart' as md;
import 'package:math_keyboard/math_keyboard.dart';
import 'package:mini_hub/markdown/question_markdown.dart';
import 'package:mini_hub/models/answer.dart';
import 'package:mini_hub/models/question.dart';
import 'package:mini_hub/widgets/question_view.dart';

/// Renders a real generated lesson the way TopicScreen does, so a tag that fails
/// to match, or a question type the view rejects, fails here rather than on a
/// device.
void main() {
  testWidgets('a generated lesson renders its questions', (tester) async {
    await tester.binding.setSurfaceSize(const Size(393, 852));
    const dir = 'assets/content/number_sense/multiplying_by_11_trick';

    final questions =
        (jsonDecode(File('$dir/questions.json').readAsStringSync())
                as List<dynamic>)
            .map((q) => Question.fromJson(q as Map<String, dynamic>))
            .toList();
    final pool = {for (final q in questions) q.id: q};

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: MathKeyboardViewInsets(
            child: SingleChildScrollView(
              child: MarkdownBody(
                data: File('$dir/lesson.md').readAsStringSync(),
                extensionSet: md.ExtensionSet(
                  [LatexBlockSyntax(), QuestionBlockSyntax()],
                  [LatexInlineSyntax()],
                ),
                builders: {
                  'latex': LatexElementBuilder(),
                  'question': QuestionElementBuilder(pool: pool),
                },
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    expect(tester.takeException(), isNull);
    // Every tag became a question rather than literal text or an error.
    expect(find.byType(QuestionView), findsNWidgets(questions.length));
    expect(find.textContaining('missing question'), findsNothing);
    expect(find.textContaining('[[question:'), findsNothing);
    expect(find.textContaining('unsupported question type'), findsNothing);
  });

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
              child: QuestionView(
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
