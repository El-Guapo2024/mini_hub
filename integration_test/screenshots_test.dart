import 'dart:io';

import 'package:flutter/material.dart' show Icons;
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:mini_hub/main.dart' as app;
import 'package:mini_hub/ui/screens/reader_screen.dart';
import 'package:path_provider/path_provider.dart';
import 'package:webview_flutter/webview_flutter.dart';

/// Walks the app to each screen worth showing on the App Store and waits
/// there while the host takes the picture.
///
/// Deliberately not part of `chinese_flow_test.dart`. That file is a gate —
/// it seeds its own tiny epub and asserts against it — and bending it to
/// pose for photographs would cost the thing it is actually for. This one
/// asserts almost nothing on purpose: a screenshot run that fails halfway
/// still leaves usable pictures behind.
///
/// Screenshots are taken by the host with `xcrun simctl io … screenshot`
/// rather than `binding.takeScreenshot`, because the host is already driving
/// two devices at different sizes and simctl captures exactly what the
/// device shows, status bar included.
///
/// The handshake: at each stop this writes `shot_<n>.ready` into the
/// documents directory and waits for the host to delete it. Timing a run by
/// sleeping on both sides works until epub.js takes a second longer than
/// usual and every later picture is of the wrong screen.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('pose for App Store screenshots', (tester) async {
    await _seedBook();
    app.main();
    await tester.pumpAndSettle(const Duration(seconds: 2));

    Future<void> stop(String name) async {
      final docs = await getApplicationDocumentsDirectory();
      final flag = File('${docs.path}/shot_$name.ready');
      await flag.writeAsString('ready\n');
      // Keep pumping while waiting: a frozen frame photographs badly, and
      // anything still animating needs to settle.
      for (var i = 0; i < 150; i++) {
        await tester.pump(const Duration(milliseconds: 200));
        if (!flag.existsSync()) return;
      }
      await flag.delete().catchError((_) => flag);
    }

    // 1. The hub.
    await stop('01_hub');

    // 2. The shelf.
    await tester.tap(find.text('Chinese'));
    await tester.pumpAndSettle();
    await stop('02_shelf');

    // 3. The book, open. epub.js needs a moment to lay the chapter out.
    final book = find.textContaining('球状闪电');
    if (book.evaluate().isNotEmpty) {
      await tester.tap(book.first);
      await tester.pumpAndSettle();
      await tester.pump(const Duration(seconds: 6));
      await stop('03_reader');

      // 4. A word, tapped. The tap goes in on the JS side: a synthesized
      // Flutter tap never reaches the native WKWebView.
      final web = ReaderScreen.debugController;
      if (web != null) {
        await ReaderScreen.debugDictionaryReady;
        outer:
        for (final fy in [0.35, 0.45, 0.55, 0.3]) {
          for (final fx in [0.3, 0.5, 0.2, 0.6]) {
            await web.runJavaScriptReturningResult('debugTapAt($fx, $fy)');
            for (var i = 0; i < 12; i++) {
              await tester.pump(const Duration(milliseconds: 200));
              if (find.text('Card').evaluate().isNotEmpty) break outer;
            }
          }
        }
        if (find.text('Card').evaluate().isNotEmpty) {
          await stop('04_word');
          // Dismiss before moving on, or the sheet sits over everything after.
          await tester.tapAt(const Offset(200, 100));
          await tester.pumpAndSettle();
        }
      }

      // 5. The companion, open beside the page.
      final chat = find.byIcon(Icons.chat_bubble_outline);
      if (chat.evaluate().isNotEmpty && find.byType(WebViewWidget).evaluate().isNotEmpty) {
        await tester.tap(chat.first);
        await tester.pumpAndSettle();
        await tester.pump(const Duration(seconds: 1));
        await stop('05_companion');
      }
    }

    // Nothing is asserted about what was captured. The host checks the
    // pictures; a test that failed here would only throw them away.
  });
}

/// Puts a real Chinese book on the shelf before the app starts.
///
/// It has to happen in here rather than from the host: `flutter test`
/// installs its own harness app, and installing wipes the container, so
/// anything copied in from outside beforehand is gone by the time this
/// runs.
///
/// The simulator shares the Mac's filesystem, so the book is copied from
/// wherever it already lives on disk. If none of those paths is readable
/// the run carries on with whatever is already on the shelf — a missing
/// book costs some of the pictures, not the whole run.
Future<void> _seedBook() async {
  const candidates = [
    '/Users/juanantonioluera/Documents/Language_Learning/Chinese/Books/'
        '球状闪电 - 刘慈欣.epub',
    '/Users/juanantonioluera/Library/Mobile Documents/com~apple~CloudDocs/'
        'Chinese Books/球状闪电 - 刘慈欣.epub',
  ];
  try {
    final docs = await getApplicationDocumentsDirectory();
    final shelf = Directory('${docs.path}/chinese_books');
    await shelf.create(recursive: true);
    for (final path in candidates) {
      final src = File(path);
      if (!src.existsSync()) continue;
      final name = Uri.file(path).pathSegments.last;
      final dest = File('${shelf.path}/$name');
      if (!dest.existsSync() || dest.lengthSync() != src.lengthSync()) {
        await src.copy(dest.path);
      }
      return;
    }
  } on Object {
    // Sandboxing, a moved file, a full disk: none of it is worth failing
    // a screenshot run over.
  }
}
