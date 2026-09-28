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

  /// A CJK ideograph, as opposed to the punctuation between them. The main
  /// block plus extension A covers everything a modern book uses.
  static bool isHan(String char) {
    if (char.isEmpty) return false;
    final code = char.runes.first;
    return (code >= 0x4E00 && code <= 0x9FFF) ||
        (code >= 0x3400 && code <= 0x4DBF);
  }

  /// What can be part of a word: ideographs, and the Latin letters and digits
  /// a few entries carry (卡拉OK, T恤). Punctuation and spaces end a clause.
  static bool _inWord(String char) =>
      isHan(char) || RegExp(r'^[A-Za-z0-9]$').hasMatch(char);

  /// How far either side of a tap the clause is read. A word's boundaries
  /// are settled by its neighbours, not by text a line away.
  static const int _clauseReach = 32;

  /// The word a tap at [offset] fell in, read the way the clause around it
  /// divides into words.
  ///
  /// A pop-up dictionary such as Zhongwen looks forward from the finger
  /// only, taking the longest entry that starts there. That answers 究 for a
  /// tap on the 究 of 研究, and 研究生 ("graduate student") for a tap on the
  /// 研 of 研究生命起源 ("researching the origin of life"). Here the clause
  /// is cut into dictionary words first — fewest words, then fewest single
  /// characters, and between equals the longer word later on, which is how
  /// Chinese most often resolves — and the tap is answered with the word it
  /// landed in: 研究 for either character, 生命 for 生 or 命.
  ///
  /// Null when the character is not part of a word (punctuation, a space),
  /// or when the division leaves it on its own and the dictionary has no
  /// entry for it.
  ({int start, String word, List<DictEntry> entries})? wordAt(
    String text,
    int offset,
  ) {
    if (offset < 0 || offset >= text.length || !_inWord(text[offset])) {
      return null;
    }
    var from = offset;
    while (from > 0 &&
        offset - from < _clauseReach &&
        _inWord(text[from - 1])) {
      from--;
    }
    var to = offset + 1;
    while (to < text.length &&
        to - offset < _clauseReach &&
        _inWord(text[to])) {
      to++;
    }
    final clause = text.substring(from, to);

    // best[i]: the cheapest division of clause[0, i) as (words, singles);
    // last[i]: how long its final word is.
    final n = clause.length;
    final words = List<int>.filled(n + 1, 0);
    final singles = List<int>.filled(n + 1, 0);
    final last = List<int>.filled(n + 1, 0);
    for (var i = 1; i <= n; i++) {
      words[i] = 1 << 30;
      final longest = i < _maxWordLength ? i : _maxWordLength;
      // Longest first, and only a strictly cheaper division replaces one
      // already found: between equals, the longer final word stands.
      for (var len = longest; len >= 1; len--) {
        if (len > 1 && !_bySurface.containsKey(clause.substring(i - len, i))) {
          continue;
        }
        final w = words[i - len] + 1;
        final s = singles[i - len] + (len == 1 ? 1 : 0);
        if (w < words[i] || (w == words[i] && s < singles[i])) {
          words[i] = w;
          singles[i] = s;
          last[i] = len;
        }
      }
    }

    final at = offset - from;
    for (var end = n; end > 0; end -= last[end]) {
      final start = end - last[end];
      if (start > at) continue;
      final word = clause.substring(start, end);
      final entries = _bySurface[word];
      if (entries == null) return null;
      return (start: from + start, word: word, entries: entries);
    }
    return null;
  }

  /// Every dictionary word the character at [offset] belongs to, longest
  /// first, the character itself included: what else the tap could have
  /// meant, for when the division in [wordAt] guessed wrong.
  List<({int start, String word, List<DictEntry> entries})> wordsCovering(
    String text,
    int offset,
  ) {
    final found = <({int start, String word, List<DictEntry> entries})>[];
    if (offset < 0 || offset >= text.length) return found;
    final first = offset - _maxWordLength + 1 < 0
        ? 0
        : offset - _maxWordLength + 1;
    for (var start = first; start <= offset; start++) {
      for (var end = offset + 1; end <= text.length; end++) {
        if (end - start > _maxWordLength) break;
        final word = text.substring(start, end);
        final entries = _bySurface[word];
        if (entries != null) {
          found.add((start: start, word: word, entries: entries));
        }
      }
    }
    found.sort((a, b) {
      final byLength = b.word.length.compareTo(a.word.length);
      return byLength != 0 ? byLength : a.start.compareTo(b.start);
    });
    return found;
  }

  /// The dictionary from CC-CEDICT text already in hand, for tests that want
  /// a handful of entries rather than the shipped 124k.
  @visibleForTesting
  static Dictionary parse(String raw) => Dictionary._(_parse(raw));

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
