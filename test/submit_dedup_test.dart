import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:math_keyboard/math_keyboard.dart';
import 'package:mini_hub/config.dart';
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

/// One answer is one attempt.
///
/// A submit arriving twice with the input unchanged is the same answer arriving
/// twice — a double tap, or a keyboard sending the event twice — and each one
/// built its own [Attempt] with its own id, so the store could not tell them
/// apart and one answer was recorded, and counted, twice.
void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  Future<AttemptStore> open(WidgetTester tester) async {
    late AttemptStore store;
    await tester.runAsync(() async {
      store = await AttemptStore.openAt(inMemoryDatabasePath);
    });
    // Closed inside runAsync too: the write it waits on never completes in the
    // fake-time zone a widget test runs in.
    addTearDown(() => tester.runAsync(store.close));
    return store;
  }

  Future<void> pumpQuestion(WidgetTester tester, AttemptStore store) async {
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
  }

  /// Runs out the timers an answer leaves behind: the pause a correct answer
  /// starts, and the ten-second one the database keeps. A test that ends with
  /// either still pending fails on the timer rather than on what it asked.
  Future<void> settle(WidgetTester tester) async {
    await tester.pump(AppConfig.current.advanceAfter * 2);
    await tester.pump(const Duration(seconds: 11));
  }

  void submit(WidgetTester tester, String tex) {
    tester.widget<MathField>(find.byType(MathField)).onSubmitted!(tex);
  }

  testWidgets('the same answer submitted again is not a second attempt', (
    tester,
  ) async {
    final store = await open(tester);
    await pumpQuestion(tester, store);

    for (var i = 0; i < 20; i++) {
      submit(tester, '4');
      await tester.pump();
    }
    await tester.runAsync(() => Future<void>.delayed(Duration.zero));
    await settle(tester);

    expect(store.all, hasLength(1));
    expect(store.isDone(_question.id), isTrue);
  });

  testWidgets('each different answer is its own attempt', (tester) async {
    final store = await open(tester);
    await pumpQuestion(tester, store);

    for (final tex in ['5', '6', '7', '4']) {
      // The change that clears the last result, as typing would.
      tester.widget<MathField>(find.byType(MathField)).onChanged!(tex);
      await tester.pump();
      submit(tester, tex);
      await tester.pump();
    }
    await tester.runAsync(() => Future<void>.delayed(Duration.zero));
    await settle(tester);

    expect(store.all, hasLength(4));
    expect(store.all.where((a) => a.correct), hasLength(1));
    expect(store.isDone(_question.id), isTrue);
  });
}
