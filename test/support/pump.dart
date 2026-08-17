import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:math_keyboard/math_keyboard.dart';
import 'package:mini_hub/content/question.dart';
import 'package:mini_hub/progress/attempt_scope.dart';
import 'package:mini_hub/progress/attempt_store.dart';
import 'package:mini_hub/ui/widgets/question_widget.dart';

/// Puts a single question on screen the way the practice tab does.
///
/// [MathKeyboardViewInsets] is not optional: the field looks for it on the way
/// up and throws without one. Never [WidgetTester.pumpAndSettle] — the field's
/// cursor blinks forever, so settling never finishes.
Future<void> pumpQuestion(
  WidgetTester tester,
  Question question, {
  AttemptStore? store,
  bool rightToLeft = false,
}) async {
  final app = MaterialApp(
    home: Scaffold(
      body: MathKeyboardViewInsets(
        child: QuestionWidget(question: question, rightToLeft: rightToLeft),
      ),
    ),
  );
  await tester.pumpWidget(
    store == null ? app : AttemptScope(store: store, child: app),
  );
  await tester.pump();
}

/// Types an answer and submits it.
///
/// Drives the field's callbacks rather than tapping it: tapping opens the
/// on-screen math keyboard, whose animation never settles under the test
/// binding. This still exercises the whole grade-and-record path.
Future<void> answer(WidgetTester tester, String text) async {
  final field = tester.widget<MathField>(find.byType(MathField));
  field.onChanged!(text);
  await tester.pump();
  field.onSubmitted!(text);
  await tester.pump();
  // record() writes the log asynchronously.
  await tester.runAsync(() => Future<void>.delayed(Duration.zero));
}
