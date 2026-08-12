import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mini_hub/main.dart';

void main() {
  testWidgets('the app boots without throwing', (tester) async {
    // Replaces the `flutter create` counter boilerplate, which asserted a
    // widget this app never had and so failed on every run.
    await tester.pumpWidget(const MyApp());
    await tester.pump();

    expect(find.byType(MaterialApp), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
