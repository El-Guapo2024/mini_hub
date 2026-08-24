import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:math_keyboard/math_keyboard.dart';
import 'package:mini_hub/content/answer.dart';
import 'package:mini_hub/content/ids.dart';
import 'package:mini_hub/content/question.dart';
import 'package:mini_hub/progress/attempt_scope.dart';
import 'package:mini_hub/progress/attempt_store.dart';
import 'package:mini_hub/ui/widgets/question_widget.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

/// One answer is one attempt, however many times the submit event arrives.
void main() {
  late Directory dir;
  late String file;

  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  setUp(() {
    dir = Directory.systemTemp.createTempSync('answer_submission_test');
    file = '${dir.path}/attempts.db';
  });

  tearDown(() => dir.deleteSync(recursive: true));

  const question = Question(
    id: QuestionId('q1'),
    topic: TopicId('adding'),
    prompt: '1+1',
    answer: NumericAnswer(value: 2),
  );

  testWidgets('editing after a correct answer cancels the advance', (
    tester,
  ) async {
    final store = (await tester.runAsync(() => AttemptStore.openAt(file)))!;
    addTearDown(() => tester.runAsync(store.close));

    var advanced = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: AttemptScope(
          store: store,
          child: Scaffold(
            body: QuestionWidget(
              question: question,
              onCorrect: () => advanced++,
            ),
          ),
        ),
      ),
    );

    final field = tester.widget<MathField>(find.byType(MathField));
    field.onSubmitted!('2');
    await tester.pump();

    // Still inside the window the green is shown for.
    await tester.pump(const Duration(milliseconds: 200));
    field.onChanged!('21');
    await tester.pump();

    // Long past when the hop would have fired.
    await tester.pump(const Duration(seconds: 2));
    expect(advanced, 0, reason: 'the student was still typing');

    await tester.pumpAndSettle();
  });
}
