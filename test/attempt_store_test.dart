import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:mini_hub/models/ids.dart';
import 'package:mini_hub/data/attempt_store.dart';
import 'package:mini_hub/models/answer.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  late Directory dir;
  late String file;

  setUpAll(() {
    // sqflite talks to the platform's SQLite through a plugin channel, which
    // does not exist under `flutter test`. The ffi factory loads SQLite in
    // process instead, so these run on the VM.
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  setUp(() {
    dir = Directory.systemTemp.createTempSync('attempts_test');
    file = '${dir.path}/attempts.db';
  });

  tearDown(() => dir.deleteSync(recursive: true));

  Attempt at(
    String topic, {
    required bool correct,
    required DateTime when,
    QuestionType type = QuestionType.numeric,
    String id = 'bh.1.2.1.q1',
  }) => Attempt(
    questionId: QuestionId(id),
    topic: TopicId(topic),
    type: type,
    correct: correct,
    at: when,
  );

  final day0 = DateTime.utc(2026, 1, 1);

  test('an empty store reports no progress rather than throwing', () async {
    final store = await AttemptStore.openAt(file);
    expect(store.all, isEmpty);
    expect(store.progressFor(const TopicId('squares')).count, 0);
    expect(store.isDone(const QuestionId('bh.1.2.1.q1')), isFalse);
  });

  test('attempts survive a reopen', () async {
    final store = await AttemptStore.openAt(file);
    await store.record(at('squares', correct: true, when: day0));
    await store.record(at('cubes', correct: false, when: day0));

    final reopened = await AttemptStore.openAt(file);
    expect(reopened.all.length, 2);
    expect(reopened.progressFor(const TopicId('squares')).count, 1);
    expect(reopened.progressFor(const TopicId('cubes')).count, 0);
    expect(reopened.all.first.at, day0);
  });

  test('concurrent records all land', () async {
    // record() is called from the UI without awaiting, so a fast student can
    // have two writes in flight at once.
    final store = await AttemptStore.openAt(file);
    await Future.wait([
      for (var i = 0; i < 25; i++)
        store.record(
          at('squares', correct: true, when: day0.add(Duration(seconds: i))),
        ),
    ]);

    expect((await AttemptStore.openAt(file)).all.length, 25);
  });

  test('clear empties the file as well as the list', () async {
    final store = await AttemptStore.openAt(file);
    await store.record(at('squares', correct: true, when: day0));
    await store.clear();

    expect(store.all, isEmpty);
    expect((await AttemptStore.openAt(file)).all, isEmpty);
  });

  test('a question is done once it has ever been right', () async {
    final store = await AttemptStore.openAt(file);
    await store.record(at('squares', correct: false, when: day0));
    expect(store.isDone(const QuestionId('bh.1.2.1.q1')), isFalse);

    await store.record(
      at('squares', correct: true, when: day0.add(const Duration(hours: 1))),
    );
    expect(store.isDone(const QuestionId('bh.1.2.1.q1')), isTrue);
  });

  test('getting it wrong later does not undo done', () async {
    // Done means finished, not currently correct. Anything else would make a
    // lesson's progress go backwards while a student is revising it.
    final store = await AttemptStore.openAt(file);
    await store.record(at('squares', correct: true, when: day0));
    await store.record(
      at('squares', correct: false, when: day0.add(const Duration(hours: 1))),
    );

    expect(store.isDone(const QuestionId('bh.1.2.1.q1')), isTrue);
  });

  test(
    'progress counts each question once, however often it is tried',
    () async {
      final store = await AttemptStore.openAt(file);
      for (var i = 0; i < 3; i++) {
        await store.record(
          at('squares', correct: true, when: day0.add(Duration(hours: i))),
        );
      }
      await store.record(
        at('squares', correct: true, when: day0, id: 'bh.1.2.1.q2'),
      );

      final progress = store.progressFor(const TopicId('squares'));
      expect(progress.count, 2);
      expect(progress.done, {
        const QuestionId('bh.1.2.1.q1'),
        const QuestionId('bh.1.2.1.q2'),
      });
    },
  );

  test('progress is per topic', () async {
    final store = await AttemptStore.openAt(file);
    await store.record(at('squares', correct: true, when: day0));
    await store.record(
      at('cubes', correct: true, when: day0, id: 'bh.1.2.1.q2'),
    );

    expect(store.progressFor(const TopicId('squares')).done, {
      const QuestionId('bh.1.2.1.q1'),
    });
    expect(store.progressFor(const TopicId('cubes')).done, {
      const QuestionId('bh.1.2.1.q2'),
    });
  });

  test('an id is stable across a save and reload', () async {
    final store = await AttemptStore.openAt(file);
    await store.record(at('squares', correct: true, when: day0));
    final id = store.all.single.id;

    expect((await AttemptStore.openAt(file)).all.single.id, id);
  });
}
