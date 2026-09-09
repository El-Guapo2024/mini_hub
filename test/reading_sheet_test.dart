import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mini_hub/chinese/reading.dart';
import 'package:mini_hub/chinese/tutor.dart';
import 'package:mini_hub/ui/widgets/reading_sheet.dart';

/// The sheet asks while it is open, so it has three states and must show all
/// three. The one that matters is the failure: the companion lives on a Mac
/// that is sometimes asleep, and a reader who has to close the sheet, find
/// the sentence again and repeat the gesture will stop asking.
void main() {
  Future<void> pumpSheet(
    WidgetTester tester, {
    required Future<Reading> Function() prepare,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: ElevatedButton(
              onPressed: () => showReadingSheet(
                context: context,
                sentence: '他走进来了。',
                prepare: prepare,
                onSpeakSentence: () {},
              ),
              child: const Text('open'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pump();
  }

  testWidgets('the sentence and a spinner show while it is being prepared', (
    tester,
  ) async {
    await pumpSheet(
      tester,
      prepare: () => Future.delayed(
        const Duration(milliseconds: 50),
        () => const Reading(
          sentence: '他走进来了。',
          translation: 'He came in.',
          notes: [],
        ),
      ),
    );

    expect(find.text('他走进来了。'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    await tester.pumpAndSettle();
    expect(find.text('He came in.'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsNothing);
  });

  testWidgets('notes are shown under their own heading', (tester) async {
    await pumpSheet(
      tester,
      prepare: () async => const Reading(
        sentence: '他走进来了。',
        translation: 'He came in.',
        notes: [ReadingNote(about: '了', says: 'a change of state')],
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Implied, not written'), findsOneWidget);
    expect(find.text('了'), findsOneWidget);
    expect(find.text('a change of state'), findsOneWidget);
  });

  testWidgets('a sentence with nothing implied shows no empty heading', (
    tester,
  ) async {
    await pumpSheet(
      tester,
      prepare: () async => const Reading(
        sentence: '我是学生。',
        translation: 'I am a student.',
        notes: [],
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Implied, not written'), findsNothing);
  });

  testWidgets('a failure is retried from the sheet itself', (tester) async {
    var attempts = 0;
    await pumpSheet(
      tester,
      prepare: () async {
        attempts++;
        if (attempts == 1) {
          throw TutorException('Companion server not reachable');
        }
        return const Reading(
          sentence: '他走进来了。',
          translation: 'He came in.',
          notes: [],
        );
      },
    );
    await tester.pumpAndSettle();

    expect(find.text('Companion server not reachable'), findsOneWidget);

    await tester.tap(find.text('Try again'));
    await tester.pumpAndSettle();

    expect(attempts, 2);
    expect(find.text('He came in.'), findsOneWidget);
    expect(find.text('Try again'), findsNothing);
  });
}
