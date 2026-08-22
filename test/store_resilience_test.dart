import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:mini_hub/content/fraction.dart';
import 'package:mini_hub/content/ids.dart';
import 'package:mini_hub/content/answer.dart';
import 'package:mini_hub/progress/attempt_store.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

/// What a row the app cannot read costs.
void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  test('an unreadable attempt costs that attempt, not the log', () async {
    final directory = await Directory.systemTemp.createTemp('mini_hub_store');
    addTearDown(() => directory.delete(recursive: true));
    final path = '${directory.path}/attempts.db';

    final store = await AttemptStore.openAt(path);
    for (final id in ['sq.q1', 'sq.q2']) {
      await store.record(
        Attempt(
          questionId: QuestionId(id),
          topic: const TopicId('squares'),
          type: QuestionType.numeric,
          correct: true,
          at: DateTime.now().toUtc(),
          given: '4',
        ),
      );
    }
    await store.close();

    // A type this build has no name for — what a question type renamed in a
    // later release leaves behind on a device that has already practised.
    final raw = await databaseFactory.openDatabase(path);
    await raw.insert('attempts', {
      'id': 'sq.q3.future',
      'question_id': 'sq.q3',
      'topic': 'squares',
      'type': 'matrix',
      'correct': 1,
      'at': DateTime.now().toUtc().millisecondsSinceEpoch,
      'given_tex': '4',
      'elapsed_ms': null,
    });
    await raw.close();

    final reopened = await AttemptStore.openAt(path);
    addTearDown(reopened.close);

    // The unreadable row is skipped; the two before it survive. Read all at
    // once this threw, open failed, and every attempt ever made went with it.
    expect(reopened.all, hasLength(2));
    expect(reopened.isDone(const QuestionId('sq.q1')), isTrue);
    expect(reopened.isDone(const QuestionId('sq.q2')), isTrue);
    expect(reopened.isDone(const QuestionId('sq.q3')), isFalse);

    // And the loss is counted rather than only logged, so it is possible to
    // say so rather than leave the history quietly short.
    expect(reopened.unreadableAttempts, 1);
  });

  test('an answer shown as recorded is really recorded', () async {
    final directory = await Directory.systemTemp.createTemp('mini_hub_collide');
    addTearDown(() => directory.delete(recursive: true));
    final path = '${directory.path}/attempts.db';

    final first = await AttemptStore.openAt(path);
    await first.close();

    // An unreadable row holding an id. Skipped at open, it is still in the
    // table, so an insert reusing that id conflicts and is ignored.
    final raw = await databaseFactory.openDatabase(path);
    await raw.insert('attempts', {
      'id': 'collide',
      'question_id': 'sq.q1',
      'topic': 'squares',
      'type': 'bogus',
      'correct': 1,
      'at': DateTime.now().toUtc().millisecondsSinceEpoch,
      'given_tex': '1',
      'elapsed_ms': null,
    });
    await raw.close();

    final store = await AttemptStore.openAt(path);
    addTearDown(store.close);
    expect(store.unreadableAttempts, 1);

    final attempt = Attempt(
      id: 'collide',
      questionId: const QuestionId('sq.q2'),
      topic: const TopicId('squares'),
      type: QuestionType.numeric,
      correct: true,
      at: DateTime.now().toUtc(),
      given: '4',
    );

    // It must fail loudly rather than leave a green check the log never held.
    await expectLater(store.record(attempt), throwsA(isA<StateError>()));
    expect(store.all, isEmpty, reason: 'the failed write was taken back out');
    expect(store.isDone(const QuestionId('sq.q2')), isFalse);
  });

  test('fractions equal to each other hash alike', () {
    // Equality cross-multiplies, so these are the same number however the sign
    // is written. A hash that disagreed would keep both in a Set.
    const onDenominator = Fraction(1, -2);
    const onNumerator = Fraction(-1, 2);

    expect(onDenominator, onNumerator);
    expect(onDenominator.hashCode, onNumerator.hashCode);
    expect({onDenominator, onNumerator}, hasLength(1));

    expect(const Fraction(1, 2) == const Fraction(1, 3), isFalse);
  });
}
