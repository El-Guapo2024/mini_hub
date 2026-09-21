import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:just_audio/just_audio.dart';

import '../config.dart';
import 'azure_tts.dart';

/// The one place that speaks. Today it is the on-device zh-CN voice; if the
/// engine ever changes, this file is the whole change.
class Speech {
  Speech() {
    _tts
      // By default the plugin deactivates the shared audio session after
      // every utterance — which also killed the mic's recording session, so
      // the recogniser got silence. The recorder manages the session
      // instead.
      ..autoStopSharedSession(false)
      ..setLanguage(ChineseConfig.ttsLanguage)
      ..setSpeechRate(ChineseConfig.ttsRate)
      ..setStartHandler(() => speaking.value = true)
      ..setCompletionHandler(_finished)
      ..setCancelHandler(() => speaking.value = false)
      ..setProgressHandler(_progressed);

    // A run spoken by Azure is played here, not by flutter_tts, so that
    // plugin's completion handler never fires for it. Without this the
    // first Chinese run of a mixed answer would play and the English after
    // it would never start.
    _player.playerStateStream.listen((s) {
      if (s.processingState != ProcessingState.completed) return;
      speaking.value = false;
      if (!reading.value && _runs.isNotEmpty) _speakNextRun();
    });
  }

  /// The page being read aloud. Position is a character offset into it,
  /// moved word by word as the voice speaks — so the bar is smooth, and a
  /// drag or a resume starts from exactly that spot, like scrubbing a video.
  String _page = '';

  /// Where the voice is on the page (or where it will resume).
  final ValueNotifier<int> readOffset = ValueNotifier(0);

  /// True while a page is being read aloud (false when paused or done).
  final ValueNotifier<bool> reading = ValueNotifier(false);

  int get readLength => _page.length;

  /// The span of the page currently handed to the voice.
  int _chunkStart = 0;
  int _chunkEnd = 0;

  /// Called when a read reaches the end of the page on its own — not on pause.
  void Function()? onReadDone;

  static final RegExp _sentence = RegExp(r'[^。！？!?；\n]+[。！？!?；”」』]*');

  /// Sentences with their closing punctuation kept, so each is spoken with
  /// its intonation.
  static List<String> sentencesOf(String text) => [
    for (final m in _sentence.allMatches(text))
      if (m[0]!.trim().isNotEmpty) m[0]!.trim(),
  ];

  /// The end of the sentence containing [offset] — how far one utterance
  /// runs, so speech resumed mid-sentence still stops at a natural pause.
  static int sentenceEndAfter(String text, int offset) {
    for (final m in _sentence.allMatches(text)) {
      if (m.end > offset) return m.end;
    }
    return text.length;
  }

  /// Reads [page] aloud. The same page as a paused read resumes where it
  /// stopped; a new page starts from the top.
  Future<void> read(String page) async {
    if (page.trim().isEmpty) return;
    if (page != _page) {
      _page = page;
      readOffset.value = 0;
    }
    if (readOffset.value >= _page.length) readOffset.value = 0;
    _runs = [];
    await _tts.stop();
    reading.value = true;
    await _speakFromOffset();
  }

  /// Moves to character [offset]; while reading, carries on from there.
  Future<void> seek(int offset) async {
    if (_page.isEmpty) return;
    readOffset.value = offset.clamp(0, _page.length - 1);
    if (!reading.value) return;
    await _tts.stop(); // a cancel, not a completion — no double advance
    await _speakFromOffset();
  }

  /// Stops reading but keeps the place.
  Future<void> pause() async {
    reading.value = false;
    await _tts.stop();
    await _player.stop();
    speaking.value = false;
  }

  Future<void> _speakFromOffset() async {
    var start = readOffset.value;
    while (start < _page.length && _page[start].trim().isEmpty) {
      start++;
    }
    if (start >= _page.length) {
      _pageDone();
      return;
    }
    final lang = ChineseConfig.ttsLanguage;
    await _tts.setLanguage(lang);
    final voice = await _pickVoice(lang);
    if (voice != null) await _tts.setVoice(voice);
    if (!reading.value) return; // paused while the voice was resolving
    _chunkStart = start;
    _chunkEnd = sentenceEndAfter(_page, start);
    readOffset.value = start;
    await _tts.speak(_page.substring(_chunkStart, _chunkEnd));
  }

  /// The voice reached a word: move the place to it.
  void _progressed(String text, int start, int end, String word) {
    if (!reading.value) return;
    readOffset.value = (_chunkStart + start).clamp(0, _page.length);
  }

  void _finished() {
    speaking.value = false;
    if (!reading.value) {
      // An answer in several voices: go on to its next run.
      if (_runs.isNotEmpty) _speakNextRun();
      return;
    }
    readOffset.value = _chunkEnd;
    if (_chunkEnd < _page.length) {
      _speakFromOffset();
    } else {
      _pageDone();
    }
  }

  /// Done: the next play starts the page over, unless the listener turns
  /// the page and carries on.
  void _pageDone() {
    reading.value = false;
    readOffset.value = _page.length;
    onReadDone?.call();
  }

  final FlutterTts _tts = FlutterTts();

  /// The companion's voice, when an Azure key is saved. The book is never
  /// read this way: a novel is hundreds of thousands of characters, and the
  /// device voice is free, works offline and reports word boundaries so the
  /// page can follow along as it reads.
  final AzureTts _azure = AzureTts();
  final AudioPlayer _player = AudioPlayer();

  /// True while the voice is talking — so a stop control can exist only
  /// when there is something to stop.
  final ValueNotifier<bool> speaking = ValueNotifier(false);

  /// Best installed voice per language, resolved once. iOS ships a robotic
  /// default; the premium/enhanced voices (downloadable in Settings >
  /// Accessibility > Spoken Content) are dramatically better — prefer them.
  final Map<String, Map<String, String>?> _bestVoice = {};

  Future<Map<String, String>?> _pickVoice(String language) async {
    if (_bestVoice.containsKey(language)) return _bestVoice[language];
    Map<String, String>? best;
    try {
      final voices = (await _tts.getVoices as List)
          .cast<Map>()
          .where(
            (v) => (v['locale'] as String? ?? '').toLowerCase().startsWith(
              language.toLowerCase().substring(0, 2),
            ),
          )
          .toList();
      int rank(Map v) {
        final id = ('${v['identifier'] ?? ''} ${v['name'] ?? ''}')
            .toLowerCase();
        if (id.contains('premium')) return 0;
        if (id.contains('enhanced')) return 1;
        return 2;
      }

      voices.sort((a, b) => rank(a).compareTo(rank(b)));
      if (voices.isNotEmpty && rank(voices.first) < 2) {
        best = {
          'name': voices.first['name'] as String,
          'locale': voices.first['locale'] as String,
        };
      }
    } catch (_) {
      // No voice list — the language default will do.
    }
    _bestVoice[language] = best;
    return best;
  }

  /// Runs of an answer still to speak, each with the voice for its script.
  List<(String, String)> _runs = [];

  static final RegExp _han = RegExp(r'[㐀-䶿一-鿿]');
  static final RegExp _latin = RegExp(r'[A-Za-z0-9]');
  static final RegExp _scriptRun = RegExp(
    r'[㐀-䶿一-鿿　-〿＀-￯]+|'
    r'[^㐀-䶿一-鿿　-〿＀-￯]+',
  );

  /// Splits mixed text into runs spoken by the Chinese or the English voice.
  /// No single iOS voice switches language mid-sentence, so the switch is
  /// made here, at each change of script. Punctuation and spacing ride with
  /// the run before them rather than becoming a run of their own.
  static List<(String, String)> languageRuns(String text) {
    final runs = <(String, String)>[];
    for (final m in _scriptRun.allMatches(text)) {
      final piece = m[0]!;
      final isHan = _han.hasMatch(piece);
      if (!isHan && !_latin.hasMatch(piece)) {
        if (runs.isNotEmpty) {
          runs[runs.length - 1] = (runs.last.$1 + piece, runs.last.$2);
        }
        continue;
      }
      final lang = isHan ? ChineseConfig.ttsLanguage : 'en-US';
      if (runs.isNotEmpty && runs.last.$2 == lang) {
        runs[runs.length - 1] = (runs.last.$1 + piece, lang);
      } else {
        runs.add((piece, lang));
      }
    }
    return [
      for (final r in runs)
        if (r.$1.trim().isNotEmpty) (r.$1.trim(), r.$2),
    ];
  }

  /// Speaks an answer that mixes English and Chinese, each part in its own
  /// voice, one after the other.
  Future<void> speakMixed(String text) async {
    reading.value = false;
    await _tts.stop();
    await _player.stop();
    _runs = languageRuns(text);
    await _speakNextRun();
  }

  Future<void> _speakNextRun() async {
    if (_runs.isEmpty) return;
    final (text, lang) = _runs.removeAt(0);
    try {
      final file = await _azure.synthesize(text, lang);
      if (file != null) {
        speaking.value = true;
        await _player.setFilePath(file.path);
        // Not awaited: the future finishes when playback does, and the
        // state stream already chains the next run. Awaiting both would
        // speak the run after this one twice.
        unawaited(_player.play());
        return;
      }
    } catch (e) {
      // A bad key, a spent quota or no network must not cost the answer:
      // it is spoken in the device voice, exactly as with no key at all.
      debugPrint('azure tts, falling back to the device voice: $e');
    }
    await _tts.setLanguage(lang);
    final voice = await _pickVoice(lang);
    if (voice != null) await _tts.setVoice(voice);
    await _tts.speak(text);
  }

  Future<void> speak(String text, {String? language}) async {
    final lang = language ?? ChineseConfig.ttsLanguage;
    // A one-off (a word, an answer) interrupts a page read; its place is kept.
    reading.value = false;
    _runs = [];
    await _tts.stop();
    await _player.stop();
    await _tts.setLanguage(lang);
    final voice = await _pickVoice(lang);
    if (voice != null) await _tts.setVoice(voice);
    await _tts.speak(text);
  }

  Future<void> stop() async {
    reading.value = false;
    _runs = [];
    await _tts.stop();
    await _player.stop();
    speaking.value = false;
  }

  /// Hands back the native audio player. The reader owns one Speech for the
  /// life of the screen, so this runs when the book is closed.
  Future<void> dispose() async {
    await _player.dispose();
  }
}
