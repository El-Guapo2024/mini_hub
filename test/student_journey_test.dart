import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mini_hub/ui/screens/topic_screen.dart';
import 'package:math_keyboard/math_keyboard.dart';
import 'package:mini_hub/main.dart';
import 'package:mini_hub/progress/attempt_store.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

/// Drives the whole student journey through the real widget tree, real
/// asset bundle, and a real (ffi-backed) sqflite store.
///
/// pumpAndSettle is never used: every screen involved here eventually shows
/// a MathField, whose cursor animates forever and would hang settle. Instead
/// we pump fixed durations and let tester.runAsync carry real IO (asset
/// reads, sqflite calls) outside the fake-async zone.
/// Drags the topic list's own [ListView] up until [finder] is on screen, or
/// gives up after a generous number of drags. Avoids [scrollUntilVisible],
/// which throws "Too many elements" here because more than one [Scrollable]
/// exists in the tree.
Future<void> _scrollUntilVisible(WidgetTester tester, Finder finder) async {
  final list = find.byType(ListView);
  for (var i = 0; i < 30; i++) {
    if (finder.evaluate().isNotEmpty) return;
    await tester.drag(list, const Offset(0, -300));
    await tester.pump(const Duration(milliseconds: 50));
  }
}

void main() {
  // The deck is shuffled in the app. This test types a particular answer, so
  // it has to know which question it is answering.
  setUp(() => debugShufflePractice = false);
  tearDown(() => debugShufflePractice = true);

  late Directory dir;
  late AttemptStore store;

  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  setUp(() async {
    dir = Directory.systemTemp.createTempSync('full_journey_test');
  });

  tearDown(() => dir.deleteSync(recursive: true));

  testWidgets('launch -> hub -> course -> topic -> lesson -> practice -> progress', (
    tester,
  ) async {
    await tester.runAsync(() async {
      store = await AttemptStore.openAt('${dir.path}/attempts.db');
    });

    await tester.pumpWidget(MyApp(store: store));
    await tester.pump();
    // Let the hub settle (no async work here, but be generous).
    await tester.pump(const Duration(milliseconds: 100));

    // ---- Hub home ----
    expect(find.text('Mini Hub'), findsOneWidget);
    expect(find.text('Stema Arena'), findsOneWidget);

    await tester.tap(find.text('Stema Arena'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    // ---- Course list (courses.json load) ----
    // Give the async course load a few pumps to land.
    for (
      var i = 0;
      i < 5 && find.text('Number Sense').evaluate().isEmpty;
      i++
    ) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(
      find.text('Number Sense'),
      findsOneWidget,
      reason: 'the Number Sense course tile should appear after loading',
    );

    await tester.tap(find.text('Number Sense'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    // ---- Topic list (topics load, one file per topic, concurrently) ----
    // The course has 100+ topics, each its own asset read, so give this
    // plenty of pumps.
    for (var i = 0; i < 50 && find.byType(ListView).evaluate().isEmpty; i++) {
      await tester.pump(const Duration(milliseconds: 200));
    }
    expect(find.byType(ListView), findsOneWidget);

    // "Special Integers" is far down the list (topic 39 of ~116), so it is
    // not built until scrolled into the viewport.
    await _scrollUntilVisible(tester, find.text('Special Integers'));
    await tester.pump(const Duration(milliseconds: 100));
    expect(
      find.text('Special Integers'),
      findsOneWidget,
      reason: 'the Special Integers topic should appear in the topic list',
    );
    // No progress recorded yet: should not show "done" wording for this topic.
    expect(find.textContaining('0 of'), findsWidgets);

    await tester.tap(find.text('Special Integers'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    // ---- Topic screen: lesson + questions load ----
    for (var i = 0; i < 10 && find.byType(TabBar).evaluate().isEmpty; i++) {
      await tester.pump(const Duration(milliseconds: 200));
    }
    expect(find.byType(TabBar), findsOneWidget);
    expect(find.text('Lesson'), findsOneWidget);
    expect(find.text('Practice'), findsOneWidget);

    // The lesson tab is the initial tab: real markdown should be rendered,
    // not raw text or an error.
    await tester.pump(const Duration(milliseconds: 100));
    expect(
      find.text('Special Integers'),
      findsWidgets,
      reason: 'the lesson heading should render',
    );
    expect(
      find.textContaining('important properties'),
      findsOneWidget,
      reason: 'lesson body markdown should be rendered as text, not an error',
    );

    // ---- Switch to Practice tab ----
    await tester.tap(find.text('Practice'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.byType(MathField), findsOneWidget);
    expect(
      find.textContaining('1 of'),
      findsOneWidget,
      reason: 'the practice header should show question 1 of N',
    );
    // The previous route (topic list) is still in the Navigator stack
    // beneath this one and may itself show a "0 done"-shaped count, so allow
    // more than one match; what matters is that the practice header shows it.
    expect(find.textContaining('0 done'), findsWidgets);

    // ---- Answer question 1 correctly: 572 x 21 = 12012 ----
    var field = tester.widget<MathField>(find.byType(MathField));
    field.onChanged!('12012');
    await tester.pump();
    field.onSubmitted!('12012');
    await tester.pump();
    await tester.runAsync(() => Future<void>.delayed(Duration.zero));
    await tester.pump();

    // Marked correct on screen.
    expect(
      find.byIcon(Icons.check),
      findsOneWidget,
      reason:
          'question 1 of Special Integers is 572 x 21 = 12012. If the bank has '
          'been regenerated and the order moved, this is a content shift '
          'rather than a grading fault.',
    );
    expect(
      find.textContaining('1 done'),
      findsOneWidget,
      reason:
          'the done count should tick up immediately after a correct answer',
    );

    // Auto-advance timer is AppConfig.current.advanceAfter (700ms), then a
    // 300ms page-turn animation. Pump past both.
    await tester.pump(const Duration(milliseconds: 750));
    await tester.pump(const Duration(milliseconds: 350));
    await tester.pump(const Duration(milliseconds: 100));

    // Should now be on question 2.
    expect(
      find.textContaining('2 of'),
      findsOneWidget,
      reason: 'answering correctly should auto-advance to the next question',
    );

    // ---- Answer question 2 WRONG: q2 is 2/37 x 999 = 54 ----
    field = tester.widget<MathField>(find.byType(MathField));
    field.onChanged!('999999');
    await tester.pump();
    field.onSubmitted!('999999');
    await tester.pump();
    await tester.runAsync(() => Future<void>.delayed(Duration.zero));
    await tester.pump();

    // Marked wrong, answer NOT shown, no auto-advance.
    expect(
      find.byIcon(Icons.close),
      findsOneWidget,
      reason:
          'question 2 is 2/37 x 999 = 54, and 999999 is meant to be wrong for '
          'it. If the bank moved, this is a content shift.',
    );
    expect(
      find.textContaining('Answer:'),
      findsNothing,
      reason:
          'a miss must not print the answer. It used to, and it was the '
          'fastest way through the bank -- read the answer, move on. Skip is '
          'the way past a question that will not come.',
    );
    // Pump well past the advance window: must NOT have moved on.
    await tester.pump(const Duration(milliseconds: 750));
    await tester.pump(const Duration(milliseconds: 100));
    expect(
      find.textContaining('2 of'),
      findsOneWidget,
      reason: 'a wrong answer must not auto-advance',
    );
    // The done count should still read 1 (only the correct one counts).
    expect(find.textContaining('1 done'), findsOneWidget);

    // ---- Go back to the topic list ----
    await tester.pageBack();
    await tester.pump();
    // Let the pop transition finish; mid-transition both the outgoing
    // TopicScreen's app bar and the topic list's tile can be on screen at
    // once, matching this text twice.
    await tester.pump(const Duration(milliseconds: 350));
    await tester.pump(const Duration(milliseconds: 200));

    await _scrollUntilVisible(tester, find.text('Special Integers'));
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.text('Special Integers'), findsOneWidget);
    // Progress should now show 1 of N done for this topic.
    expect(
      find.textContaining('1 of'),
      findsOneWidget,
      reason: 'the topic list should reflect the one correct answer just given',
    );

    // ---- Reopen the same topic, go to Practice, confirm question 1 still marked done ----
    await tester.tap(find.text('Special Integers'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    for (var i = 0; i < 10 && find.byType(TabBar).evaluate().isEmpty; i++) {
      await tester.pump(const Duration(milliseconds: 200));
    }
    await tester.tap(find.text('Practice'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    // Reopening deals a fresh deck of what is left, so the answered question
    // is not in it and the tick that marks one is not on screen. This used to
    // assert the opposite: the deck reopened at question one every time, so a
    // student met the same answered card at the top of every sitting.
    expect(
      find.byIcon(Icons.check_circle),
      findsNothing,
      reason: 'the answered question should not be dealt again',
    );
    // 66 left of 67, and the topic's own total beside it. The previous route
    // is still stacked beneath, so the loose match sees more than one.
    expect(find.textContaining('1 of'), findsWidgets);
    expect(
      find.text('1 of 66   ·   1 done'),
      findsOneWidget,
      reason: 'the deck should hold what is left, and say what the topic is at',
    );

    expect(tester.takeException(), isNull);
  });
}
