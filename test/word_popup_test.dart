import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mini_hub/chinese/claude.dart';
import 'package:mini_hub/chinese/entry.dart';
import 'package:mini_hub/chinese/phrase.dart';
import 'package:mini_hub/ui/widgets/word_popup.dart';

/// A drag-selection's sheet: the dictionary's senses, and above them what the
/// run means in its sentence, arriving while the sheet is already open.
void main() {
  const entries = [
    DictEntry(
      traditional: '走進',
      simplified: '走进',
      pinyin: 'zǒu jìn',
      glosses: ['to enter'],
    ),
  ];

  Future<void> pumpPopup(
    WidgetTester tester, {
    required String word,
    Future<PhraseReading>? inContext,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: ElevatedButton(
              onPressed: () => showWordPopup(
                context: context,
                word: word,
                entries: entries,
                sentence: '他走进来了。',
                inContext: inContext,
                onSpeakWord: () {},
                onSpeakSentence: () {},
                onAddCard: (_) async {},
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

  testWidgets('the meaning here arrives above the dictionary', (tester) async {
    // The test window's 600 px is shorter than any phone, and a sheet gets
    // about half of it: the tight case for the note and the actions below.
    final answer = Completer<PhraseReading>();
    await pumpPopup(tester, word: '走进来', inContext: answer.future);

    expect(find.text('Reading it in this sentence…'), findsOneWidget);
    expect(find.text('• to enter'), findsOneWidget, reason: 'not waited on');

    answer.complete(
      const PhraseReading(
        phrase: '走进来',
        sentence: '他走进来了。',
        translation: 'came in',
        pinyin: 'zǒu jìnlai',
        note: 'toward the speaker',
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('In this sentence'), findsOneWidget);
    expect(find.text('came in'), findsOneWidget);
    expect(find.text('zǒu jìnlai'), findsOneWidget);
    expect(find.text('toward the speaker'), findsOneWidget);
  });

  testWidgets('a failure says why, and the dictionary stays', (tester) async {
    final answer = Completer<PhraseReading>();
    await pumpPopup(tester, word: '走进来', inContext: answer.future);
    answer.completeError(TutorException('Overloaded'));
    await tester.pumpAndSettle();

    expect(find.text('Overloaded'), findsOneWidget);
    expect(find.text('• to enter'), findsOneWidget);
  });

  testWidgets('a tap has no in-context section at all', (tester) async {
    await pumpPopup(tester, word: '走');
    await tester.pumpAndSettle();

    expect(find.text('In this sentence'), findsNothing);
    expect(find.text('Reading it in this sentence…'), findsNothing);
  });

  testWidgets('a long selection fits on a phone', (tester) async {
    // Now that a drag can cross styled text and sentences, a run of a dozen
    // characters is ordinary; at display size it overflowed the sheet.
    tester.view.physicalSize = const Size(375 * 3, 812 * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    await pumpPopup(tester, word: '他走进来了我们都站起来一顶帽子');
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('他走进来了我们都站起来一顶帽子'), findsOneWidget);
  });
}
