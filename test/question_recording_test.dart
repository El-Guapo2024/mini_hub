import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mini_hub/content/answer.dart';
import 'package:mini_hub/content/ids.dart';
import 'package:mini_hub/content/question.dart';
import 'package:mini_hub/progress/attempt_store.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'support/pump.dart';

const _question = Question(
  id: QuestionId('bh.1.2.1.q1'),
  prompt: '2+2=',
  answer: NumericAnswer(value: 4),
  topic: TopicId('multiplying_by_11_trick'),
);

const _topic = TopicId('multiplying_by_11_trick');

void main() {
  late Directory dir;
  late AttemptStore store;

  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  setUp(() async {
    dir = Directory.systemTemp.createTempSync('recording_test');
    store = await AttemptStore.openAt('${dir.path}/attempts.db');
  });

  // Closed before the directory goes, or the delete races SQLite. The store
  // holds the database open, and SQLite writes -wal and -shm beside the file;
  // a recursive delete that walks the directory while those are still being
  // flushed can find a new one after the walk and fail with
  //
  //     FileSystemException: Deletion failed (OS Error: Directory not empty)
  //
  // which showed up as this file failing once in a full run and passing on
  // its own -- the window only opens under the I/O load of the other tests.
  tearDown(() async {
    await store.close();
    dir.deleteSync(recursive: true);
  });

  testWidgets('a correct answer is recorded against its topic', (tester) async {
    await pumpQuestion(tester, _question, store: store);
    await answer(tester, '4');

    final logged = store.all.single;
    expect(logged.questionId, const QuestionId('bh.1.2.1.q1'));
    expect(logged.topic, _topic);
    expect(logged.type, QuestionType.numeric);
    expect(logged.correct, isTrue);
    expect(store.progressFor(_topic).count, 1);
  });

  testWidgets('a wrong answer is recorded with what was typed', (tester) async {
    await pumpQuestion(tester, _question, store: store);
    await answer(tester, '5');

    expect(store.all.single.correct, isFalse);
    expect(store.all.single.given, isNotEmpty);
    expect(store.progressFor(_topic).count, 0);
  });

  testWidgets('grading still works with no store to record to', (tester) async {
    // A question rendered outside the app must not throw for want of a scope.
    await pumpQuestion(tester, _question);
    await answer(tester, '4');

    expect(tester.takeException(), isNull);
    expect(find.byIcon(Icons.check), findsOneWidget);
  });
}
