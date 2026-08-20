import 'package:flutter_test/flutter_test.dart';
import 'package:mini_hub/config.dart';
import 'package:mini_hub/main.dart';

/// What the app does when it cannot do its job.
void main() {
  testWidgets('a session that will not be saved says so', (tester) async {
    await tester.pumpWidget(const MyApp(storageFailed: true));
    await tester.pump();

    // Said once, over the whole app: it was true before the first answer, and
    // a student who is only told at the question has already lost a session.
    expect(
      find.text('Progress is not being saved on this device'),
      findsOneWidget,
    );
  });

  testWidgets('a working session says nothing about saving', (tester) async {
    await tester.pumpWidget(const MyApp());
    await tester.pump();

    expect(
      find.text('Progress is not being saved on this device'),
      findsNothing,
    );
  });

  testWidgets('a build that cannot be configured says which flag', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MisconfiguredApp(reason: 'CONTENT was built as "typo"'),
    );
    await tester.pump();

    expect(find.textContaining('CONTENT'), findsOneWidget);
  });

  test('a real content source is not an error', () {
    // This build names one, so there is nothing to report. The check runs
    // before anything reads the configuration, because the first thing that
    // does is a repository built in a field initializer, outside every try.
    expect(AppConfig.configurationError, isNull);
    expect(AppConfig.current.content, ContentSource.real);
  });

  test('every source name is accepted by the check it guards', () {
    for (final source in ContentSource.values) {
      expect(ContentSource.byName(source.name), source);
    }
    expect(() => ContentSource.byName('typo'), throwsArgumentError);
  });
}
