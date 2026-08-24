import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:math_keyboard/math_keyboard.dart';
import 'package:mini_hub/main.dart';
import 'package:mini_hub/progress/attempt_store.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

Future<void> _scrollUntilVisible(WidgetTester tester, Finder finder) async {
  final list = find.byType(ListView);
  for (var i = 0; i < 60; i++) {
    if (finder.evaluate().isNotEmpty) return;
    await tester.drag(list, const Offset(0, -300));
    await tester.pump(const Duration(milliseconds: 50));
  }
}

Future<void> _openStemaArena(WidgetTester tester) async {
  await tester.tap(find.text('Stema Arena'));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 100));
}

void main() {
  late Directory dir;

  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  setUp(() async {
    dir = Directory.systemTemp.createTempSync('extended_lesson_only_test');
  });

  tearDown(() => dir.deleteSync(recursive: true));

  testWidgets('lesson-only topic: lesson renders, practice shows a message, '
      'list row has no progress text', (tester) async {
    late AttemptStore store;
    await tester.runAsync(() async {
      store = await AttemptStore.openAt('${dir.path}/attempts.db');
    });

    await tester.pumpWidget(MyApp(store: store));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    await _openStemaArena(tester);

    for (
      var i = 0;
      i < 5 && find.text('Number Sense').evaluate().isEmpty;
      i++
    ) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    await tester.tap(find.text('Number Sense'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    for (var i = 0; i < 50 && find.byType(ListView).evaluate().isEmpty; i++) {
      await tester.pump(const Duration(milliseconds: 200));
    }
    expect(find.byType(ListView), findsOneWidget);

    await _scrollUntilVisible(tester, find.text('Standard Fibonacci Numbers'));
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.text('Standard Fibonacci Numbers'), findsOneWidget);

    // What does the row show for a topic with zero questions?
    final row = find.ancestor(
      of: find.text('Standard Fibonacci Numbers'),
      matching: find.byType(Card),
    );
    expect(row, findsOneWidget);
    // No "N of N done" / "done · N questions" subtitle text at all: dumped
    // here for the report.
    // ignore: avoid_print
    print(
      'Lesson-only topic row widget tree text: '
      '${tester.widgetList<Text>(find.descendant(of: row, matching: find.byType(Text))).map((t) => t.data).toList()}',
    );

    await tester.tap(find.text('Standard Fibonacci Numbers'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    for (var i = 0; i < 10 && find.byType(TabBar).evaluate().isEmpty; i++) {
      await tester.pump(const Duration(milliseconds: 200));
    }
    expect(find.byType(TabBar), findsOneWidget);

    // Lesson tab (initial): real markdown rendered.
    await tester.pump(const Duration(milliseconds: 100));
    expect(
      find.textContaining('Fibonacci numbers memorized'),
      findsOneWidget,
      reason: 'lesson body markdown should be rendered',
    );

    // Practice tab: should show a sensible message, not blank/crash.
    await tester.tap(find.text('Practice'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.byType(MathField), findsNothing);
    expect(
      find.textContaining('no questions'),
      findsOneWidget,
      reason: 'a lesson-only topic should say so on the Practice tab',
    );
    expect(tester.takeException(), isNull);
  });
}
