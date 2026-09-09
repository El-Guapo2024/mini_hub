import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;

import 'entry.dart';

/// The offline dictionary: CC-CEDICT, indexed by surface form.
///
/// Lookup is longest-match at a position — try the eight characters starting
/// at the tap, then seven, down to one — which is how a reader's eye resolves
/// a word too. (The approach, and the data file, follow Wen Reader, MIT,
/// Oliver Zhang.)
class Dictionary {
  Dictionary._(this._bySurface);

  final Map<String, List<DictEntry>> _bySurface;

  int get wordCount => _bySurface.length;

  /// CEDICT words run one to about six characters; eight is a safe ceiling.
  static const int _maxWordLength = 8;

  static Future<Dictionary> load(String assetPath) async {
    final raw = await rootBundle.loadString(assetPath);
    return Dictionary._(await compute(_parse, raw));
  }

  /// The word under a tap: the longest entry starting at [offset] in [text],
  /// or null when nothing there is in the dictionary.
  ({String word, List<DictEntry> entries})? matchAt(String text, int offset) {
    if (offset < 0 || offset >= text.length) return null;
    final limit = offset + _maxWordLength > text.length
        ? text.length
        : offset + _maxWordLength;
    for (var end = limit; end > offset; end--) {
      final word = text.substring(offset, end);
      final entries = _bySurface[word];
      if (entries != null) return (word: word, entries: entries);
    }
    return null;
  }

  /// A user-drawn selection: the exact entry when the whole run is a word,
  /// otherwise a greedy left-to-right segmentation of it.
  ({String pinyin, List<DictEntry> entries})? lookupSelection(String sel) {
    final exact = _bySurface[sel];
    if (exact != null) return (pinyin: exact.first.pinyin, entries: exact);
    final parts = <DictEntry>[];
    var i = 0;
    while (i < sel.length) {
      final m = matchAt(sel, i);
      if (m == null) {
        i++;
        continue;
      }
      parts.add(m.entries.first);
      i += m.word.length;
    }
    if (parts.isEmpty) return null;
    return (pinyin: parts.map((e) => e.pinyin).join(' '), entries: parts);
  }

  /// Hand-rolled split, not a regex: the file is 124k lines and this parse
  /// gates the first lookup of a session — a debug build with a per-line
  /// regex left taps answerless for many seconds.
  static Map<String, List<DictEntry>> _parse(String raw) {
    final bySurface = <String, List<DictEntry>>{};
    for (final rawLine in raw.split('\n')) {
      // The upstream file is CRLF.
      final l = rawLine.trimRight();
      if (l.isEmpty || l.startsWith('#')) continue;
      // "傳統 传统 [chuan2 tong3] /tradition/"
      final s1 = l.indexOf(' ');
      if (s1 < 0) continue;
      final s2 = l.indexOf(' ', s1 + 1);
      final br1 = l.indexOf('[', s2 + 1);
      final br2 = l.indexOf(']', br1 + 1);
      final sl1 = l.indexOf('/', br2 + 1);
      final sl2 = l.lastIndexOf('/');
      if (s2 < 0 || br1 < 0 || br2 < 0 || sl1 < 0 || sl2 <= sl1) continue;
      final entry = DictEntry(
        traditional: l.substring(0, s1),
        simplified: l.substring(s1 + 1, s2),
        pinyin: _accent(l.substring(br1 + 1, br2)),
        glosses: l.substring(sl1 + 1, sl2).split('/'),
      );
      bySurface.putIfAbsent(entry.simplified, () => []).add(entry);
      if (entry.traditional != entry.simplified) {
        bySurface.putIfAbsent(entry.traditional, () => []).add(entry);
      }
    }
    return bySurface;
  }

  // ---- numbered pinyin -> accented ----

  static const _marks = {
    'a': ['ā', 'á', 'ǎ', 'à', 'a'],
    'e': ['ē', 'é', 'ě', 'è', 'e'],
    'i': ['ī', 'í', 'ǐ', 'ì', 'i'],
    'o': ['ō', 'ó', 'ǒ', 'ò', 'o'],
    'u': ['ū', 'ú', 'ǔ', 'ù', 'u'],
    'ü': ['ǖ', 'ǘ', 'ǚ', 'ǜ', 'ü'],
  };

  static String _accent(String numbered) =>
      numbered.split(' ').map(_accentSyllable).join(' ');

  /// "zhong1" -> "zhōng". The mark lands on a > e > the o of ou > the last
  /// vowel — the standard rule. Syllables without a trailing 1-5 (erhua "r",
  /// punctuation) pass through untouched.
  static String _accentSyllable(String syl) {
    if (syl.isEmpty) return syl;
    final toneChar = syl[syl.length - 1];
    final tone = int.tryParse(toneChar);
    if (tone == null || tone < 1 || tone > 5) return syl;
    var body = syl.substring(0, syl.length - 1).replaceAll('u:', 'ü');

    var at = -1;
    if (body.contains('a')) {
      at = body.indexOf('a');
    } else if (body.contains('e')) {
      at = body.indexOf('e');
    } else if (body.contains('ou')) {
      at = body.indexOf('o');
    } else {
      for (var i = body.length - 1; i >= 0; i--) {
        if (_marks.containsKey(body[i].toLowerCase())) {
          at = i;
          break;
        }
      }
    }
    if (at < 0) return body;

    final vowel = body[at].toLowerCase();
    final marked = _marks[vowel]![tone - 1];
    return body.replaceRange(at, at + 1, marked);
  }
}
