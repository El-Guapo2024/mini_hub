import 'dart:async';
import 'dart:io';
import 'dart:convert';

import 'package:flutter/material.dart' hide Card;
import 'package:path_provider/path_provider.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../../chinese/card_store.dart';
import '../../chinese/dictionary.dart';
import '../../chinese/entry.dart';
import '../../chinese/library.dart';
import '../../chinese/reading.dart';
import '../../chinese/reading_cache.dart';
import '../../chinese/speech.dart';
import '../../chinese/tutor.dart';
import '../../config.dart';
import '../widgets/companion_bar.dart';
import '../widgets/reading_sheet.dart';
import '../widgets/word_popup.dart';

/// The book, rendered by epub.js in a WebView; everything above it is Flutter.
///
/// The bridge carries exactly the contract in docs/chinese-module.md: JS
/// reports `ready`, `tapped` and `moved`; Dart calls `appendChunk`, `openBook`,
/// `goNext` and `goPrev`. The WebView owns rendering and position, nothing
/// else.
class ReaderScreen extends StatefulWidget {
  const ReaderScreen({super.key, required this.book, required this.library});

  final Book book;
  final Library library;

  /// The live controller, so the integration test can drive the page's own
  /// hit-testing (synthesized taps never reach a native platform view).
  @visibleForTesting
  static WebViewController? debugController;

  /// Resolves when the dictionary is parsed; the test must not probe before.
  @visibleForTesting
  static Future<void>? get debugDictionaryReady =>
      _ReaderScreenState._dictionaryLoad;

  /// A CJK ideograph, as opposed to the punctuation between them. The main
  /// block plus extension A covers everything a modern book uses.
  @visibleForTesting
  static bool isHan(String char) {
    if (char.isEmpty) return false;
    final code = char.runes.first;
    return (code >= 0x4E00 && code <= 0x9FFF) ||
        (code >= 0x3400 && code <= 0x4DBF);
  }

  /// The doc's finding: the prepared unit is the sentence. Expand from the
  /// tap to the nearest sentence-ending punctuation on each side.
  @visibleForTesting
  static String sentenceAround(String text, int offset) {
    const enders = '。！？；!?;\n';
    var start = 0;
    for (var i = offset - 1; i >= 0; i--) {
      if (enders.contains(text[i])) {
        start = i + 1;
        break;
      }
    }
    var end = text.length;
    for (var i = offset; i < text.length; i++) {
      if (enders.contains(text[i])) {
        end = i + 1;
        break;
      }
    }
    return text.substring(start, end).trim();
  }

  @override
  State<ReaderScreen> createState() => _ReaderScreenState();
}

class _ReaderScreenState extends State<ReaderScreen> {
  late final WebViewController _web;
  final Speech _speech = Speech();

  static Future<Dictionary>? _dictionaryLoad;
  double _progress = 0;

  /// One conversation per reading session, anchored to the open chapter.
  TutorSession? _tutor;

  /// Prepared sentences. Built once with its cache, so a sentence met twice
  /// on the way back through a page is explained without a second call.
  Future<ReadingService>? _readingsLoad;

  /// The text of the chapter on screen — what a prepared sentence is read
  /// against, and what the companion answers questions about.
  String _chapter = '';

  /// The companion strip under the page — toggled, never covering the book.
  bool _companionOpen = false;

  /// Real touches never make it into the WKWebView on iOS, so gestures are
  /// recognized here from raw pointer events and replayed over the bridge.
  /// A quick horizontal flick turns the page; a slower hold-and-drag
  /// selects the characters between the two points; anything else is a tap.
  Offset? _down;
  DateTime? _downAt;
  DateTime _lastDrag = DateTime.fromMillisecondsSinceEpoch(0);

  /// Live highlight while the finger moves, throttled so the bridge keeps up.
  void _pointerMove(PointerMoveEvent e) {
    final down = _down;
    if (down == null || (e.localPosition - down).distance <= 14) return;
    final now = DateTime.now();
    if (now.difference(_lastDrag) < const Duration(milliseconds: 60)) return;
    _lastDrag = now;
    final up = e.localPosition;
    _web.runJavaScript(
      'showSelection(${down.dx}, ${down.dy}, ${up.dx}, ${up.dy})',
    );
  }

  void _pointerUp(PointerUpEvent e) {
    final down = _down;
    final downAt = _downAt;
    _down = null;
    if (down == null || downAt == null) return;
    final up = e.localPosition;
    final dx = up.dx - down.dx;
    final dy = up.dy - down.dy;
    final held = DateTime.now().difference(downAt);
    if (dx.abs() > 60 &&
        dx.abs() > dy.abs() &&
        held < const Duration(milliseconds: 300)) {
      _debugLog('flutter swipe ${dx < 0 ? 'next' : 'prev'}');
      _web.runJavaScript(dx < 0 ? 'goNext()' : 'goPrev()');
      return;
    }
    if ((up - down).distance > 14) {
      _debugLog('flutter select $down -> $up');
      _web.runJavaScript(
        'selectRange(${down.dx}, ${down.dy}, ${up.dx}, ${up.dy})',
      );
      return;
    }
    _debugLog('flutter tap $up');
    _web.runJavaScript('tapAt(${up.dx}, ${up.dy})');
  }

  @override
  void initState() {
    super.initState();
    // Loaded once for the app's life; every book shares it.
    _dictionaryLoad ??= Dictionary.load(ChineseConfig.cedictAsset);
    _debugLog('reader init');
    // A page read to its end turns the page and keeps reading.
    _speech.onReadDone = _turnAndReadOn;

    _web = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.transparent)
      ..addJavaScriptChannel('Bridge', onMessageReceived: _onMessage)
      ..setNavigationDelegate(
        NavigationDelegate(onPageFinished: (_) => _sendBook()),
      )
      ..loadFlutterAsset(ChineseConfig.readerPage);
    ReaderScreen.debugController = _web;
  }

  @override
  void dispose() {
    _speech.onReadDone = null;
    _speech.stop();
    // The test hook is a static, so without this every reader ever opened
    // keeps its WebViewController — and with it the WKWebView holding a
    // whole book — alive for the life of the app. Closing a book has to
    // actually release it; the second one opened was enough to be killed
    // for memory on a simulator.
    if (identical(ReaderScreen.debugController, _web)) {
      ReaderScreen.debugController = null;
    }
    // Drop the page's own retained state too: epub.js keeps the parsed book
    // and its rendered sections, which is the large half of the leak.
    _web.loadRequest(Uri.parse('about:blank')).ignore();
    super.dispose();
  }

  /// The epub crosses the bridge in base64 chunks; one giant call is fragile
  /// and file:// fetches are blocked, so this is the reliable path.
  Future<void> _sendBook() async {
    final bytes = await widget.book.file.readAsBytes();
    final b64 = base64Encode(bytes);
    const chunk = 512 * 1024;
    for (var i = 0; i < b64.length; i += chunk) {
      final end = (i + chunk > b64.length) ? b64.length : i + chunk;
      await _web.runJavaScript(
        'appendChunk(${jsonEncode(b64.substring(i, end))})',
      );
    }
    if (!mounted) return;
    final fg = Theme.of(context).colorScheme.onSurface;
    final hex =
        '#${fg.toARGB32().toRadixString(16).padLeft(8, '0').substring(2)}';
    await _web.runJavaScript(
      'openBook(${jsonEncode(widget.book.cfi)}, ${jsonEncode(hex)})',
    );
  }

  /// Bridge traffic, mirrored to a file the Mac can read — debug prints
  /// from a simulator app launched outside `flutter run` reach nothing.
  static File? _debugLogFile;
  static void _debugLog(String line) {
    assert(() {
      if (_debugLogFile == null) {
        getApplicationDocumentsDirectory().then((d) {
          _debugLogFile = File('${d.path}/reader_log.txt');
        });
      } else {
        _debugLogFile!.writeAsStringSync(
          '${DateTime.now().toIso8601String()} $line\n',
          mode: FileMode.append,
        );
      }
      return true;
    }());
    debugPrint(line);
  }

  void _onMessage(JavaScriptMessage message) {
    final m = jsonDecode(message.message) as Map<String, dynamic>;
    _debugLog(
      'bridge: ${message.message.length > 120 ? m['type'] : message.message}',
    );
    switch (m['type']) {
      case 'log':
        debugPrint('reader.js: ${m['msg']}');
      case 'chapter':
        final text = m['text'] as String;
        // A new chapter keeps the conversation but moves its anchor.
        _chapter = text;
        (_tutor ??= TutorSession(chapterContext: text)).chapterContext = text;
      case 'moved':
        widget.library.savePosition(widget.book, m['cfi'] as String);
        final pct = (m['pct'] as num?)?.toDouble() ?? 0;
        setState(() => _progress = pct);
        final turnedAt = _readOnAfterTurn;
        if (turnedAt != null &&
            DateTime.now().difference(turnedAt) < const Duration(seconds: 5)) {
          _readOnAfterTurn = null;
          // Give the new page a moment to lay out before reading its text.
          Future.delayed(const Duration(milliseconds: 400), () {
            if (mounted) _readVisiblePage();
          });
        }
      case 'tapped':
        _onTapped(m['text'] as String, m['offset'] as int);
      case 'selected':
        _onSelected(m['text'] as String, m['start'] as int, m['end'] as int);
    }
  }

  /// Stage 3 of the build order: the sentence, prepared. The sheet does the
  /// asking itself, so the tap that opens it returns immediately.
  Future<void> _explain(String sentence) async {
    _debugLog('explain "$sentence"');
    await showReadingSheet(
      context: context,
      sentence: sentence,
      prepare: () async {
        final readings = await (_readingsLoad ??= _openReadings());
        return readings.prepare(sentence, chapter: _chapter);
      },
      onSpeakSentence: () => _speech.speak(sentence),
    );
  }

  Future<ReadingService> _openReadings() async =>
      ReadingService(cache: await ReadingCache.open());

  Future<void> _onTapped(String text, int offset) async {
    // A tap during the (one-off) dictionary parse must not just vanish.
    var ready = false;
    unawaited(_dictionaryLoad!.then((_) => ready = true));
    await Future<void>.delayed(const Duration(milliseconds: 300));
    if (!ready && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Dictionary still loading — one moment…'),
          duration: Duration(seconds: 2),
        ),
      );
    }
    final dictionary = await _dictionaryLoad!;
    // A tap is exactly the character under the finger; drag to select more.
    final char = text.substring(offset, offset + 1);
    final matchEntries = dictionary.lookupSelection(char)?.entries;
    final match = matchEntries == null
        ? null
        : (word: char, entries: matchEntries);
    assert(() {
      final at = offset < text.length ? text[offset] : '<end>';
      debugPrint(
        'tapped: offset=$offset at="$at" '
        'match=${match?.word} words=${dictionary.wordCount}',
      );
      return true;
    }());
    if (!mounted) return;
    if (match == null) {
      // Punctuation and spaces are meant to do nothing — a sheet for 。 is
      // noise. A character with no entry is different: the tap landed, the
      // dictionary simply has nothing, and silence there reads as a dead
      // app rather than a miss.
      if (ReaderScreen.isHan(char)) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('No dictionary entry for $char.'),
            duration: const Duration(seconds: 2),
          ),
        );
      }
      return;
    }

    final entry = match.entries.first;
    final sentence = ReaderScreen.sentenceAround(text, offset);
    await showWordPopup(
      context: context,
      word: match.word,
      entries: match.entries,
      sentence: sentence,
      onSpeakWord: () => _speech.speak(match.word),
      onSpeakSentence: () => _speech.speak(sentence),
      onExplain: () => _explain(sentence),
      onAddCard: () async {
        final store = await CardStore.open();
        await store.add(
          Card(
            word: match.word,
            pinyin: entry.pinyin,
            gloss: entry.glosses.join('; '),
            sentence: sentence,
          ),
        );
      },
    );
  }

  /// A drag-selection: look the exact run up, or segment it word by word.
  Future<void> _onSelected(String text, int start, int end) async {
    final dictionary = await _dictionaryLoad!;
    final sel = text.substring(start, end);
    final r = dictionary.lookupSelection(sel);
    if (!mounted) return;
    final entries =
        r?.entries ??
        [DictEntry(traditional: sel, simplified: sel, pinyin: '', glosses: [])];
    final entry = entries.first;
    final sentence = ReaderScreen.sentenceAround(text, start);
    await showWordPopup(
      context: context,
      word: sel,
      pinyin: r?.pinyin ?? '',
      entries: entries,
      sentence: sentence,
      onSpeakWord: () => _speech.speak(sel),
      onSpeakSentence: () => _speech.speak(sentence),
      onExplain: () => _explain(sentence),
      onAddCard: () async {
        final store = await CardStore.open();
        await store.add(
          Card(
            word: sel,
            pinyin: r?.pinyin ?? entry.pinyin,
            gloss: entries.map((e) => e.glosses.join('; ')).join(' | '),
            sentence: sentence,
          ),
        );
      },
    );
    unawaited(_web.runJavaScript('clearSelection()'));
  }

  /// Co-reading: speak exactly what the open page shows, sentence by
  /// sentence. Pressed while reading, it pauses; pressed again on the same
  /// page, it resumes where it stopped.
  Future<void> _toggleReadAloud() async {
    _readOnAfterTurn = null;
    if (_speech.reading.value) {
      await _speech.pause();
      return;
    }
    await _readVisiblePage();
  }

  Future<void> _readVisiblePage() async {
    final text = await _visibleText();
    if (text.trim().isEmpty) return;
    await _speech.read(text);
  }

  /// Set when a page read to its end turned the page itself; the `moved`
  /// that follows reads the new page. Timestamped, so a turn that never
  /// comes (the last page of the book) cannot fire on a later manual swipe.
  DateTime? _readOnAfterTurn;

  /// Opening the companion pauses a page read (its place is kept) and hides
  /// the play controls until it is closed again.
  void _toggleCompanion() {
    final opening = !_companionOpen;
    if (opening) {
      _readOnAfterTurn = null;
      if (_speech.reading.value) _speech.pause();
    }
    setState(() => _companionOpen = opening);
  }

  void _turnAndReadOn() {
    if (!mounted) return;
    _readOnAfterTurn = DateTime.now();
    _web.runJavaScript('goNext()');
  }

  /// iOS returns the JS string JSON-quoted, hence the decode.
  Future<String> _visibleText() async {
    final raw = await _web.runJavaScriptReturningResult('visibleText()');
    var text = raw.toString();
    if (text.startsWith('"')) {
      try {
        text = jsonDecode(text) as String;
      } on FormatException {
        // Use it as it came.
      }
    }
    return text;
  }

  /// The strip under the page: read aloud with its progress, and the
  /// companion. At the thumb, not in the title bar.
  Widget _controls(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Material(
      color: cs.surfaceContainer,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        child: ListenableBuilder(
          listenable: Listenable.merge([_speech.reading, _speech.readOffset]),
          builder: (context, _) {
            final reading = _speech.reading.value;
            final total = _speech.readLength;
            final done = _speech.readOffset.value.clamp(0, total);
            return Row(
              children: [
                // While the companion is open the strip is just its toggle:
                // reading aloud and talking to the companion don't mix.
                if (_companionOpen)
                  const Spacer()
                else ...[
                  // One button that toggles — never play and stop side by side.
                  IconButton(
                    icon: Icon(
                      reading
                          ? Icons.pause_circle_filled
                          : Icons.play_circle_outline,
                    ),
                    iconSize: 30,
                    tooltip: reading ? 'Pause reading' : 'Read this page aloud',
                    onPressed: _toggleReadAloud,
                  ),
                  // Scrub like a video: the dot follows the voice word by
                  // word, and dropping it anywhere plays from that character.
                  Expanded(
                    child: Slider(
                      value: total == 0 ? 0 : done.toDouble(),
                      max: total == 0 ? 1 : total.toDouble(),
                      onChanged: total == 0
                          ? null
                          : (v) => _speech.readOffset.value = v.round(),
                      onChangeEnd: total == 0
                          ? null
                          : (v) => _speech.seek(v.round()),
                    ),
                  ),
                  Text(
                    total == 0 ? '' : '${(100 * done / total).round()}%',
                    style: Theme.of(context).textTheme.labelSmall,
                  ),
                ],
                IconButton(
                  icon: Icon(
                    _companionOpen
                        ? Icons.chat_bubble
                        : Icons.chat_bubble_outline,
                  ),
                  tooltip: 'Companion',
                  onPressed: () => _toggleCompanion(),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.book.title),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(2),
          child: LinearProgressIndicator(value: _progress, minHeight: 2),
        ),
      ),
      // Pages turn by tapping the screen edges or swiping — no button bar.
      // The eager recognizer hands every gesture straight to the WKWebView;
      // without it, taps died in Flutter's gesture arena and no touch ever
      // reached the page (the JS side proved it: zero touchstarts).
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Listener(
                onPointerDown: (e) {
                  _down = e.localPosition;
                  _downAt = DateTime.now();
                },
                onPointerMove: _pointerMove,
                onPointerUp: _pointerUp,
                child: WebViewWidget(controller: _web),
              ),
            ),
            if (_companionOpen)
              CompanionBar(
                session: _tutor ??= TutorSession(chapterContext: ''),
                speech: _speech,
              ),
            _controls(context),
          ],
        ),
      ),
    );
  }
}
