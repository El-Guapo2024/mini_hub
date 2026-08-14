import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:mini_hub/data/attempt_store.dart';
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
    String type = 'numeric',
    String id = 'bh.1.2.1.q1',
  }) => Attempt(
    questionId: id,
    topic: topic,
    type: type,
    correct: correct,
    at: when,
  );

  final day0 = DateTime.utc(2026, 1, 1);

  test('an empty store reports no attempts rather than throwing', () async {
    final store = await AttemptStore.openAt(file);
    expect(store.all, isEmpty);
    expect(store.statsFor('squares').attempts, 0);
    expect(store.reviewQueue(day0), isEmpty);
  });

  test('attempts survive a reopen', () async {
    final store = await AttemptStore.openAt(file);
    await store.record(at('squares', correct: true, when: day0));
    await store.record(at('cubes', correct: false, when: day0));

    final reopened = await AttemptStore.openAt(file);
    expect(reopened.all.length, 2);
    expect(reopened.statsFor('squares').correct, 1);
    expect(reopened.statsFor('cubes').correct, 0);
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

  group('TopicStats', () {
    test('recent accuracy tracks the last 10, not all time', () async {
      final store = await AttemptStore.openAt(file);
      // Ten wrong long ago, then ten right: lifetime says 50%, but the student
      // has clearly learned it and the recent figure must say so.
      for (var i = 0; i < 10; i++) {
        await store.record(
          at('squares', correct: false, when: day0.add(Duration(minutes: i))),
        );
      }
      for (var i = 0; i < 10; i++) {
        await store.record(
          at('squares', correct: true, when: day0.add(Duration(hours: i + 1))),
        );
      }

      final stats = store.statsFor('squares');
      expect(stats.attempts, 20);
      expect(stats.accuracy, 0.5);
      expect(stats.recent, 1.0);
    });

    test('streak counts back from the most recent answer', () async {
      final store = await AttemptStore.openAt(file);
      await store.record(at('squares', correct: true, when: day0));
      await store.record(
        at('squares', correct: false, when: day0.add(const Duration(hours: 1))),
      );
      await store.record(
        at('squares', correct: true, when: day0.add(const Duration(hours: 2))),
      );
      await store.record(
        at('squares', correct: true, when: day0.add(const Duration(hours: 3))),
      );

      expect(store.statsFor('squares').streak, 2);
    });

    test('a wrong answer breaks the streak immediately', () async {
      final store = await AttemptStore.openAt(file);
      await store.record(at('squares', correct: true, when: day0));
      await store.record(
        at('squares', correct: false, when: day0.add(const Duration(hours: 1))),
      );
      expect(store.statsFor('squares').streak, 0);
    });

    test('freshness runs 0 to 1 over the staleness window', () async {
      final store = await AttemptStore.openAt(file);
      await store.record(at('squares', correct: true, when: day0));
      final stats = store.statsFor('squares');

      expect(stats.freshness(day0), 0);
      expect(
        stats.freshness(day0.add(const Duration(days: 15))),
        closeTo(0.5, 0.01),
      );
      expect(stats.freshness(day0.add(const Duration(days: 30))), 1);
      expect(
        stats.freshness(day0.add(const Duration(days: 365))),
        1,
        reason: 'clamped, so a long-abandoned topic cannot dominate forever',
      );
    });
  });

  test('the review queue puts weak and stale topics first', () async {
    final store = await AttemptStore.openAt(file);
    // Practised today, all correct.
    await store.record(
      at(
        'strong_fresh',
        correct: true,
        when: day0.add(const Duration(days: 29)),
      ),
    );
    // Practised today, all wrong.
    await store.record(
      at(
        'weak_fresh',
        correct: false,
        when: day0.add(const Duration(days: 29)),
      ),
    );
    // A month ago, all wrong.
    await store.record(at('weak_stale', correct: false, when: day0));

    final queue = store.reviewQueue(day0.add(const Duration(days: 30)));
    expect(queue.map((s) => s.topic), [
      'weak_stale',
      'weak_fresh',
      'strong_fresh',
    ]);
  });

  test('accuracy breaks down by question type', () async {
    final store = await AttemptStore.openAt(file);
    await store.record(
      at('squares', correct: true, when: day0, type: 'numeric'),
    );
    await store.record(
      at('squares', correct: false, when: day0, type: 'approx'),
    );
    await store.record(at('cubes', correct: false, when: day0, type: 'approx'));

    final byType = store.accuracyByType();
    expect(byType['numeric'], 1.0);
    expect(byType['approx'], 0.0, reason: 'weak across both topics');
  });

  test('an id is stable across a save and reload', () async {
    final store = await AttemptStore.openAt(file);
    await store.record(at('squares', correct: true, when: day0));
    final id = store.all.single.id;

    expect((await AttemptStore.openAt(file)).all.single.id, id);
  });

  test('stats group across every topic at once', () async {
    final store = await AttemptStore.openAt(file);
    await store.record(at('squares', correct: true, when: day0));
    await store.record(at('cubes', correct: false, when: day0));

    final all = store.statsByTopic();
    expect(all.keys, unorderedEquals(['squares', 'cubes']));
    expect(all['squares']!.recent, 1.0);
    expect(all['cubes']!.recent, 0.0);
  });
}
