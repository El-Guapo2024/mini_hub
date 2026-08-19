import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mini_hub/content/answer.dart';
import 'package:mini_hub/content/ids.dart';
import 'package:mini_hub/progress/attempt_scope.dart';
import 'package:mini_hub/progress/attempt_store.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

/// The store is one instance for the life of the app, so a widget reading it
/// through the scope can only be kept current by being told when it changes.
void main() {
  late Directory dir;
  late String file;

  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  setUp(() {
    dir = Directory.systemTemp.createTempSync('progress_notifies_test');
    file = '${dir.path}/attempts.db';
  });

  tearDown(() => dir.deleteSync(recursive: true));

  Attempt at(String question, {bool correct = true}) => Attempt(
    questionId: QuestionId(question),
    topic: const TopicId('adding'),
    type: QuestionType.numeric,
    correct: correct,
    at: DateTime.utc(2026, 1, 1),
  );

  testWidgets('a widget reading through the scope rebuilds on a new attempt', (
    tester,
  ) async {
    // Opened and written to outside the fake-async zone: sqflite's ffi factory
    // does real I/O, which never completes on `testWidgets`' fake clock.
    final store = (await tester.runAsync(() => AttemptStore.openAt(file)))!;
    addTearDown(() => tester.runAsync(store.close));

    await tester.pumpWidget(
      AttemptScope(
        store: store,
        child: Directionality(
          textDirection: TextDirection.ltr,
          child: Builder(
            builder: (context) {
              final progress = AttemptScope.maybeOf(
                context,
              )!.progressFor(const TopicId('adding'));
              return Text('${progress.count} done');
            },
          ),
        ),
      ),
    );

    expect(find.text('0 done'), findsOneWidget);

    // No setState anywhere: the rebuild has to come from the store itself.
    await tester.runAsync(() => store.record(at('q1')));
    await tester.pump();

    expect(find.text('1 done'), findsOneWidget);
  });

  test('recording the same attempt twice leaves one of it', () async {
    final store = await AttemptStore.openAt(file);
    final attempt = at('q1');

    await store.record(attempt);
    await store.record(attempt);

    expect(store.all.length, 1);
    await store.close();

    // What a restart sees must be what was on screen.
    final reopened = await AttemptStore.openAt(file);
    addTearDown(reopened.close);
    expect(reopened.all.length, 1);
  });

  test('a listener hears a recorded attempt exactly once', () async {
    final store = await AttemptStore.openAt(file);
    addTearDown(store.close);

    var notifications = 0;
    store.addListener(() => notifications++);

    await store.record(at('q1'));
    expect(notifications, 1);

    await store.record(at('q1'));
    expect(notifications, 2, reason: 'a second attempt is a real change');

    await store.record(store.all.first);
    expect(notifications, 2, reason: 'a replay of a held attempt is not');
  });
}
