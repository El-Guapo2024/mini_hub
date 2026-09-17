import 'dart:convert';
import 'dart:io';

import 'package:archive/archive.dart';
import 'package:flutter/foundation.dart' show debugPrint;
import 'package:flutter/material.dart' show Icons;
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:mini_hub/main.dart' as app;
import 'package:mini_hub/ui/screens/reader_screen.dart';
import 'package:path_provider/path_provider.dart';
import 'package:webview_flutter/webview_flutter.dart';

/// The four features, on a real device build: open the reader, tap a word,
/// hear it (no assertion possible on sound — only that speaking doesn't
/// throw), and keep a card.
///
/// Where the card ends up is not asserted, and cannot be: Anki owns the
/// cards, and a test device has no AnkiWeb account connected. What is
/// checked is everything up to the hand-off.
///
/// Requires a book seeded at Documents/chinese_books/ before the run.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('read, tap a word, speak, card', (tester) async {
    await _seedBook();
    app.main();
    await tester.pumpAndSettle(const Duration(seconds: 2));

    // Hub -> Chinese.
    await tester.tap(find.text('Chinese'));
    await tester.pumpAndSettle();

    // The seeded book is on the shelf.
    expect(find.text('xiaowangzi'), findsOneWidget);
    await tester.tap(find.text('xiaowangzi'));
    await tester.pumpAndSettle();

    // The reader is up; give epub.js time to receive and open the book.
    expect(find.byType(WebViewWidget), findsOneWidget);
    await tester.pump(const Duration(seconds: 6));

    // Drive the page's own hit-testing (a synthesized Flutter tap never
    // reaches the native WKWebView, so the tap is injected on the JS side —
    // same caretRangeFromPoint path a finger takes). Probe a grid of points;
    // where text falls depends on pagination.
    final web = ReaderScreen.debugController!;
    await ReaderScreen.debugDictionaryReady;

    // Per-glyph accuracy: the center of every visible character must
    // resolve to exactly that character. This is the finger-tap contract.
    final acc = await web.runJavaScriptReturningResult('debugAccuracy(200)');
    debugPrint('accuracy: $acc');
    expect(
      '$acc',
      contains('miss[]'),
      reason: 'tap accuracy not perfect: $acc',
    );

    var found = false;
    outer:
    for (final fy in [0.3, 0.4, 0.5, 0.6]) {
      for (final fx in [0.2, 0.4, 0.6]) {
        final probe = await web.runJavaScriptReturningResult(
          'debugTapAt($fx, $fy)',
        );
        debugPrint('probe($fx,$fy) -> $probe');
        for (var i = 0; i < 10; i++) {
          await tester.pump(const Duration(milliseconds: 200));
          if (find.text('Card').evaluate().isNotEmpty) break;
        }
        if (find.text('Card').evaluate().isNotEmpty) {
          found = true;
          break outer;
        }
      }
    }
    expect(found, isTrue, reason: 'no tap produced a dictionary popup');

    // Speak the word — asserts only that the TTS path doesn't throw.
    await tester.tap(find.byTooltip('Speak word'));
    await tester.pump(const Duration(seconds: 2));

    // Keep it as a card; the sheet closes itself.
    await tester.tap(find.text('Card'));
    await tester.pumpAndSettle();

    // The sheet took the tap and closed itself. That is as far as this can
    // go: keeping a card hands it to Anki, and with no account connected
    // there is nothing left behind on the device to read back.
    expect(
      find.text('Card'),
      findsNothing,
      reason: 'the card sheet stayed open',
    );

    // Leave evidence for the host: the tap accuracy this run measured.
    final docs = await getApplicationDocumentsDirectory();
    await File(
      '${docs.path}/itest_result.txt',
    ).writeAsString('accuracy=$acc\n');

    // Hold the reader on screen briefly so host-side screenshots catch it.
    await tester.pump(const Duration(seconds: 3));

    // --- position survives leaving the book ---

    // Turn a page so there is a position to remember.
    await web.runJavaScript('goNext()');
    await tester.pump(const Duration(seconds: 2));

    // Leave the reader; the shelf should now offer to continue.
    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.text('continue'), findsOneWidget);

    // Reopen: the saved CFI is handed back to epub.js without error.
    await tester.tap(find.text('xiaowangzi'));
    await tester.pumpAndSettle();
    await tester.pump(const Duration(seconds: 6));
    final probe = await ReaderScreen.debugController!
        .runJavaScriptReturningResult('debugTapAt(0.4, 0.4)');
    expect(
      '$probe',
      contains('hit'),
      reason: 'reopening at a saved position should still render text',
    );

    // The probe opens a word popup asynchronously; wait for it, then
    // dismiss it before reaching the app bar.
    for (var i = 0; i < 15; i++) {
      await tester.pump(const Duration(milliseconds: 200));
      if (find.text('Card').evaluate().isNotEmpty) break;
    }
    if (find.text('Card').evaluate().isNotEmpty) {
      await tester.tapAt(const Offset(200, 100));
      await tester.pumpAndSettle();
    }
    expect(find.text('Card'), findsNothing);

    // --- the companion strip appears under the page, book still visible ---
    await tester.tap(find.byIcon(Icons.chat_bubble_outline));
    await tester.pumpAndSettle();
    await tester.pump(const Duration(seconds: 1));
    expect(
      find.byIcon(Icons.mic_none).evaluate().isNotEmpty &&
          find.byType(WebViewWidget).evaluate().isNotEmpty,
      isTrue,
      reason: 'companion bar should appear beside the book',
    );
  });
}

/// A tiny real epub, written into the shelf directory before launch —
/// a reinstall wipes anything seeded into the container from outside.
Future<void> _seedBook() async {
  String xhtml(String title, List<String> paras) =>
      '<?xml version="1.0" encoding="utf-8"?>'
      '<html xmlns="http://www.w3.org/1999/xhtml"><head><title>$title</title>'
      '</head><body><h1>$title</h1>'
      '${paras.map((p) => '<p>$p</p>').join()}</body></html>';

  final files = <String, String>{
    'META-INF/container.xml':
        '<?xml version="1.0"?>'
        '<container version="1.0" xmlns="urn:oasis:names:tc:opendocument:xmlns:container">'
        '<rootfiles><rootfile full-path="OEBPS/content.opf" '
        'media-type="application/oebps-package+xml"/></rootfiles></container>',
    'OEBPS/content.opf':
        '<?xml version="1.0" encoding="utf-8"?>'
        '<package xmlns="http://www.idpf.org/2007/opf" unique-identifier="id" version="3.0">'
        '<metadata xmlns:dc="http://purl.org/dc/elements/1.1/">'
        '<dc:title>test</dc:title><dc:language>zh</dc:language>'
        '<dc:identifier id="id">urn:uuid:itest-book</dc:identifier></metadata>'
        '<manifest><item id="c1" href="ch1.xhtml" media-type="application/xhtml+xml"/>'
        '<item id="nav" href="nav.xhtml" media-type="application/xhtml+xml" properties="nav"/>'
        '</manifest><spine><itemref idref="c1"/></spine></package>',
    'OEBPS/nav.xhtml':
        '<?xml version="1.0" encoding="utf-8"?>'
        '<html xmlns="http://www.w3.org/1999/xhtml" '
        'xmlns:epub="http://www.idpf.org/2007/ops"><head><title>nav</title></head>'
        '<body><nav epub:type="toc"><ol><li><a href="ch1.xhtml">一</a></li></ol>'
        '</nav></body></html>',
    'OEBPS/ch1.xhtml': xhtml('第一章', [
      '当我还只有六岁的时候，在一本书上看到了一幅精彩的插画。',
      '我把我的杰作拿给大人看，我问他们我的画是不是叫他们害怕。',
      '这些大人总是需要解释。我只好放弃了当画家这个美好的职业。',
    ]),
  };

  final zip = Archive();
  final mimetype = utf8.encode('application/epub+zip');
  zip.addFile(ArchiveFile.noCompress('mimetype', mimetype.length, mimetype));
  files.forEach((name, content) {
    final bytes = utf8.encode(content);
    zip.addFile(ArchiveFile(name, bytes.length, bytes));
  });

  final docs = await getApplicationDocumentsDirectory();
  final shelf = Directory('${docs.path}/chinese_books');
  await shelf.create(recursive: true);
  await File(
    '${shelf.path}/xiaowangzi.epub',
  ).writeAsBytes(ZipEncoder().encode(zip)!);
}
