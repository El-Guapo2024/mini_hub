import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mini_hub/ui/widgets/new_deck_dialog.dart';

/// Naming a new deck. These exist because the first version of this dialog
/// disposed its text controller as soon as `showDialog` returned — while the
/// dialog was still on screen animating out — and cancelling threw.
void main() {
  /// Opens the dialog from a real route. Not every test closes it — an
  /// empty name is meant to leave it open — so nothing here asserts that
  /// the future completed.
  Future<void> open(
    WidgetTester tester, {
    void Function(String? name)? onResult,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () async {
                final name = await askNewDeckName(context);
                onResult?.call(name);
              },
              child: const Text('open'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    expect(find.text('New deck'), findsOneWidget);
  }

  testWidgets('a typed name comes back', (tester) async {
    String? got;
    await open(tester, onResult: (name) => got = name);
    await tester.enterText(find.byType(TextField), 'Chinese::Books');
    await tester.tap(find.text('Use it'));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('New deck'), findsNothing);
    // The whole job of the dialog: the name reaches the caller, trimmed.
    expect(got, 'Chinese::Books');
  });

  testWidgets('cancelling throws nothing on the way out', (tester) async {
    await open(tester);
    // Typed into first: an untouched controller would not catch a disposal
    // the field then reads through.
    await tester.enterText(find.byType(TextField), 'che');

    await tester.tap(find.text('Cancel'));
    // Pumped a frame at a time through the exit animation, which is exactly
    // when the disposed controller used to be read.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('New deck'), findsNothing);
  });

  testWidgets('an empty name is not a deck, so it is refused', (tester) async {
    await open(tester);
    await tester.tap(find.text('Use it'));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(
      find.text('New deck'),
      findsOneWidget,
      reason: 'nothing typed should leave the dialog open, not name a deck',
    );
  });
}
