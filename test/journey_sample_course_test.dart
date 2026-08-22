import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mini_hub/config.dart';
import 'package:math_keyboard/math_keyboard.dart';
import 'package:mini_hub/main.dart';
import 'package:mini_hub/progress/attempt_store.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

/// The sample-content journey, isolated in its own file because
/// AppConfig.current is a lazy static read once per isolate: mixed into the
/// same file as tests that expect the real content bank, whichever test ran
/// first would decide the content source for every test after it. Run this
/// file with:
///
///     flutter test --dart-define=CONTENT=sample <this file>
void main() {
  late Directory dir;

  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  setUp(() async {
    dir = Directory.systemTemp.createTempSync('extended_journey_sample_test');
  });

  tearDown(() => dir.deleteSync(recursive: true));

  testWidgets('sample course (CONTENT=sample): loads, topic opens, a '
      'question can be answered', (tester) async {
    // Only meaningful when the build selected the sample bank. AppConfig
    // .current is a lazy static read once per isolate, so this file cannot
    // share a process with tests expecting the real one.
    if (AppConfig.current.content != ContentSource.sample) {
      markTestSkipped('run with --dart-define=CONTENT=sample');
      return;
    }

    late AttemptStore store;
    await tester.runAsync(() async {
      store = await AttemptStore.openAt('${dir.path}/attempts.db');
    });

    await tester.pumpWidget(MyApp(store: store));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    await tester.tap(find.text('Stema Arena'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    for (var i = 0; i < 10 && find.text('Math').evaluate().isEmpty; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(
      find.text('Math'),
      findsOneWidget,
      reason: 'the sample course "Math" tile should appear',
    );

    await tester.tap(find.text('Math'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    for (var i = 0; i < 20 && find.byType(ListView).evaluate().isEmpty; i++) {
      await tester.pump(const Duration(milliseconds: 200));
    }
    expect(find.byType(ListView), findsOneWidget);
    expect(find.text('Arithmetic Basics'), findsOneWidget);

    await tester.tap(find.text('Arithmetic Basics'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    for (var i = 0; i < 10 && find.byType(TabBar).evaluate().isEmpty; i++) {
      await tester.pump(const Duration(milliseconds: 200));
    }
    expect(find.byType(TabBar), findsOneWidget);

    await tester.tap(find.text('Practice'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.byType(MathField), findsOneWidget);

    // q1: 7 + 5 = 12
    final field = tester.widget<MathField>(find.byType(MathField));
    field.onChanged!('12');
    await tester.pump();
    field.onSubmitted!('12');
    await tester.pump();
    await tester.runAsync(() => Future<void>.delayed(Duration.zero));
    await tester.pump();

    expect(find.byIcon(Icons.check), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
