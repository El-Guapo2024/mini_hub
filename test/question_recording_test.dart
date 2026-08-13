import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:math_keyboard/math_keyboard.dart';
import 'package:mini_hub/data/attempt_scope.dart';
import 'package:mini_hub/data/attempt_store.dart';
import 'package:mini_hub/models/answer.dart';
import 'package:mini_hub/models/question.dart';
import 'package:mini_hub/widgets/question_widget.dart';

void main() {
  late Directory dir;
  late AttemptStore store;

  setUp(() async {
    dir = Directory.systemTemp.createTempSync('recording_test');
    store = await AttemptStore.openAt(File('${dir.path}/attempts.jsonl'));
  });

  tearDown(() => dir.deleteSync(recursive: true));

  const question = Question(
    id: 'bh.1.2.1.q1',
    type: 'numerical',
    prompt: '2+2=',
    answer: NumericAnswer(value: 4),
    topic: 'multiplying_by_11_trick',
  );

  Future<void> pumpQuestion(WidgetTester tester, {AttemptStore? store}) async {
    final app = MaterialApp(
      home: Scaffold(
        body: MathKeyboardViewInsets(
          child: const QuestionWidget(question: question),
        ),
      ),
    );
    await tester.pumpWidget(
      store == null ? app : AttemptScope(store: store, child: app),
    );
    await tester.pumpAndSettle();
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

  testWidgets('a correct answer is recorded against its topic', (tester) async {
    await pumpQuestion(tester, store: store);
    await answer(tester, '4');

    expect(store.all.length, 1);
    final logged = store.all.single;
    expect(logged.questionId, 'bh.1.2.1.q1');
    expect(logged.topic, 'multiplying_by_11_trick');
    expect(logged.type, 'numerical');
    expect(logged.correct, isTrue);
    expect(store.statsFor('multiplying_by_11_trick').streak, 1);
  });

  testWidgets('a wrong answer is recorded with what was typed', (tester) async {
    await pumpQuestion(tester, store: store);
    await answer(tester, '5');

    expect(store.all.single.correct, isFalse);
    expect(store.all.single.given, isNotEmpty);
    expect(store.statsFor('multiplying_by_11_trick').accuracy, 0);
  });

  testWidgets('grading still works with no store to record to', (tester) async {
    // A question rendered outside the app must not throw for want of a scope.
    await pumpQuestion(tester);
    await answer(tester, '4');

    expect(tester.takeException(), isNull);
    expect(find.byIcon(Icons.check), findsOneWidget);
  });
}
