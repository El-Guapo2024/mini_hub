import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:math_keyboard/math_keyboard.dart';
import 'package:mini_hub/main.dart';
import 'package:mini_hub/progress/attempt_store.dart';
import 'package:mini_hub/ui/widgets/tile_grid.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

/// The journey again, at the sizes an iPad actually has.
///
/// Every other widget test renders at 800x600 and says nothing about any
/// other size. That is how the hub grid came to ask for two columns on a
/// 13-inch iPad, each tile a third of a metre of empty card with a 48-pixel
/// icon adrift in it — found by running it on a simulator, which is not
/// something CI does.
///
/// So the sizes are the test. A layout fault at one of them either throws —
/// an overflow records an exception the binding rethrows at the end — or
/// shows up in the column count asserted below.
///
/// Every size runs inside one `testWidgets` rather than one each. A second
/// `testWidgets` in this file gets a course list that never loads: the app
/// starts, the hub is there, the tap navigates, and the courses simply never
/// arrive however long it is pumped. Whatever that is, it is not about size —
/// swapping which size runs first moves the failure with the order — and the
/// journey tests in this repo are already one-test-per-file, which is the
/// same workaround under another name.
void main() {
  /// Logical sizes, portrait and landscape, of what this ships to. The phone
  /// is the control: whatever changes for a tablet must not change for it.
  const sizes = <String, Size>{
    'iPhone 15': Size(393, 852),
    'iPad mini portrait': Size(744, 1133),
    'iPad Pro 11 portrait': Size(834, 1210),
    'iPad Pro 13 portrait': Size(1032, 1376),
    'iPad Pro 13 landscape': Size(1376, 1032),
  };

  /// Columns the hub grid actually laid out, read off the tiles themselves:
  /// how many share the topmost row.
  int columns(WidgetTester tester) {
    final tiles = find.descendant(
      of: find.byType(TileGrid),
      matching: find.byType(Card),
    );
    final tops = tiles
        .evaluate()
        .map(
          (e) => (e.renderObject! as RenderBox).localToGlobal(Offset.zero).dy,
        )
        .toList();
    final first = tops.reduce((a, b) => a < b ? a : b);
    return tops.where((t) => t == first).length;
  }

  /// Pumps until [finder] finds something, letting real IO run in between.
  ///
  /// A plain pump loop is not enough: these are asset reads, and they happen
  /// outside the fake-async zone. runAsync is what gives them a turn.
  Future<void> waitFor(WidgetTester tester, Finder finder) async {
    for (var i = 0; i < 50 && finder.evaluate().isEmpty; i++) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 20)),
      );
      await tester.pump(const Duration(milliseconds: 100));
    }
  }

  late Directory dir;

  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  setUp(() async {
    dir = Directory.systemTemp.createTempSync('ipad_layout_test');
  });

  tearDown(() => dir.deleteSync(recursive: true));

  testWidgets('hub, course, topic and practice lay out at every size', (
    tester,
  ) async {
    addTearDown(() => tester.binding.setSurfaceSize(null));

    late AttemptStore store;
    await tester.runAsync(() async {
      store = await AttemptStore.openAt('${dir.path}/attempts.db');
    });

    for (final entry in sizes.entries) {
      final name = entry.key;
      final width = entry.value.width;

      // The size the widgets are given. The device pixel ratio is left at 1,
      // so these logical sizes are what they see.
      await tester.binding.setSurfaceSize(entry.value);

      // Keyed by the size, so each one starts at the hub. Pumping an
      // identical MyApp only updates the tree it already has, and the
      // Navigator inside it keeps the stack the previous size left on it --
      // the second size would open on the first one's practice screen.
      await tester.pumpWidget(MyApp(key: ValueKey(name), store: store));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // ---- Hub ----
      expect(find.text('Stema Arena'), findsOneWidget, reason: name);

      // What GridView.extent itself works out: tiles at most 240 wide with
      // 16 between them, in a grid inset 16 either side. Fewer columns than
      // fit is the fault this file exists for; more would mean tiles
      // narrower than the grid asked for.
      final fits = ((width - 32) / (240 + 16)).ceil();
      expect(
        columns(tester),
        fits,
        reason:
            '$name: at ${width.toInt()} logical pixels the hub should lay out '
            '$fits columns of at most 240. A fixed column count is what made '
            'the 13-inch iPad show two tiles the width of a hand each.',
      );

      await tester.tap(find.text('Stema Arena'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // ---- Course list ----
      await waitFor(tester, find.text('Number Sense'));
      expect(find.text('Number Sense'), findsOneWidget, reason: name);

      await tester.tap(find.text('Number Sense'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // ---- Topic list ----
      await waitFor(tester, find.byType(ListTile));
      expect(find.byType(ListView), findsOneWidget, reason: name);

      // The first topic card, whatever the bank currently opens with. Which
      // topic it is does not matter here; that it lays out does.
      await tester.tap(find.byType(ListTile).first);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // ---- Topic: lesson, then practice ----
      await waitFor(tester, find.byType(TabBar));
      expect(find.byType(TabBar), findsOneWidget, reason: name);
      await tester.pump(const Duration(milliseconds: 100));

      await tester.tap(find.text('Practice'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // The practice pane is the tightest thing in the app — the tab bar,
      // the question card and the maths keyboard sharing one height — so it
      // is the screen most likely to overflow at a size nobody rendered it
      // at. Both the card and the field it is answered in must fit.
      await waitFor(tester, find.byType(MathField));
      expect(find.byType(MathField), findsOneWidget, reason: name);
      // findsWidgets, not one: the topic list is still in the navigator
      // beneath this route and its cards carry a count of the same shape.
      expect(find.textContaining(' of '), findsWidgets, reason: name);
    }
  });
}
