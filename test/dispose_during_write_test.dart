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

const _question = Question(
  id: QuestionId('bh.1.2.1.q1'),
  prompt: '2+2=',
  answer: NumericAnswer(value: 4),
  topic: TopicId('multiplying_by_11_trick'),
);

/// An answer is recorded without being waited on, so the write outlives the
/// card that started it — a student who answers and swipes straight on leaves
/// one in flight. Its failure path calls setState, which a disposed widget
/// cannot survive.
///
/// The write has to be started inside [WidgetTester.runAsync] as well as waited
/// on there: a widget test runs in fake time, where real database I/O never
/// completes, and a write begun outside it simply hangs.
void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  Future<void> answerThenDispose(
    WidgetTester tester, {
    required bool breakTheStore,
  }) async {
    late AttemptStore store;
    await tester.runAsync(() async {
      store = await AttemptStore.openAt(inMemoryDatabasePath);
    });

    await tester.pumpWidget(
      MaterialApp(
        home: AttemptScope(
          store: store,
          child: const Scaffold(
            body: MathKeyboardViewInsets(
              child: QuestionWidget(question: _question),
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    await tester.runAsync(() async {
      if (breakTheStore) {
        // Nothing left to write to, so the record fails and takes the path
        // that reports it.
        await store.close();
      }
      tester.widget<MathField>(find.byType(MathField)).onSubmitted!('4');
      // Off the card before the write has settled.
      await tester.pumpWidget(const MaterialApp(home: Scaffold()));
      await Future<void>.delayed(const Duration(milliseconds: 50));
    });
    await tester.pump();

    expect(tester.takeException(), isNull);
    if (!breakTheStore) {
      await tester.runAsync(store.close);
    }
  }

  testWidgets('a card left before its write finishes', (tester) async {
    await answerThenDispose(tester, breakTheStore: false);
  });

  testWidgets('a card left before its write fails', (tester) async {
    // The failure sets state to tell the student, and there is no longer a
    // widget to tell.
    await answerThenDispose(tester, breakTheStore: true);
  });
}
