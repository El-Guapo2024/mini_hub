import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

import 'claude.dart';
import 'reading_cache.dart';

/// A run the reader picked out of the page, read as it is used there.
///
/// The dictionary answers what characters *can* mean; a drag over several
/// words got back one gloss list per word, which is exactly the failure the
/// module exists to avoid — `走进` is not `走` plus `进`. This is the other
/// answer: what the selection means in this sentence, once.
class PhraseReading {
  const PhraseReading({
    required this.phrase,
    required this.sentence,
    required this.translation,
    required this.pinyin,
    required this.note,
  });

  /// Exactly what was selected.
  final String phrase;

  /// The sentence it was selected in — half of what the reading is about.
  final String sentence;

  /// English for the selection in the sense it carries here.
  final String translation;

  /// Tone-marked, as the characters are read in this sentence.
  final String pinyin;

  /// What the selection is doing that the translation does not show; empty
  /// when the translation says it all.
  final String note;

  Map<String, String> toJson() => {
    'phrase': phrase,
    'sentence': sentence,
    'translation': translation,
    'pinyin': pinyin,
    'note': note,
  };

  /// Lenient about everything but the translation, as [Reading] is: the
  /// model writes this, and a reading with no note is still an answer.
  factory PhraseReading.fromJson(Map<String, dynamic> j) {
    final translation = (j['translation'] as String? ?? '').trim();
    if (translation.isEmpty) {
      throw const FormatException('the phrase reading carried no translation');
    }
    return PhraseReading(
      phrase: (j['phrase'] as String? ?? '').trim(),
      sentence: (j['sentence'] as String? ?? '').trim(),
      translation: translation,
      pinyin: (j['pinyin'] as String? ?? '').trim(),
      note: (j['note'] as String? ?? '').trim(),
    );
  }
}

/// Reads selections in context, and remembers the ones it has read.
///
/// The same selection in the same sentence always means the same thing, so
/// it is cached by both; the same characters in another sentence are asked
/// about again, because there they may not mean the same thing at all.
class PhraseService {
  PhraseService({PhraseCache? cache, ClaudeClient? claude})
    : _cache = cache,
      _claude = claude ?? ClaudeClient();

  final PhraseCache? _cache;
  final ClaudeClient _claude;

  static const String _reader =
      'A learner reading a Chinese book selected part of a sentence. Read '
      'the selection as it is used in that sentence.\n\n'
      'translation: natural English for exactly the selected text, in the '
      'one sense it carries here — not the dictionary\'s list of senses, and '
      'not the whole sentence. If the selection is not a unit on its own '
      '(it cuts through a word, or runs from the end of one phrase into the '
      'next), translate what it contributes here.\n'
      'pinyin: tone-marked pinyin for the selected characters as they are '
      'read in this sentence.\n'
      'note: one plain English line on what the selection is doing that the '
      'translation does not show — an idiom whose parts mislead, a '
      'construction, a particle\'s job, a sense far from the usual one. '
      'Empty when the translation says it all; do not pad it.';

  static const Map<String, dynamic> _schema = {
    'type': 'object',
    'properties': {
      'translation': {'type': 'string'},
      'pinyin': {'type': 'string'},
      'note': {'type': 'string'},
    },
    'required': ['translation', 'pinyin', 'note'],
    'additionalProperties': false,
  };

  /// How much of the page around a selection goes with it. The sentence is
  /// what the selection is read against; the text either side settles who
  /// "he" is or what "that" points back to, and a whole chapter per drag
  /// would cost far more than it adds.
  static const int passageRadius = 600;

  /// [text] with [passageRadius] characters kept either side of the
  /// selection at [start]..[end], so a selection in a long chapter sends
  /// its neighbourhood rather than the chapter.
  static String passageAround(String text, int start, int end) {
    final from = (start - passageRadius).clamp(0, text.length);
    final to = (end + passageRadius).clamp(0, text.length);
    return text.substring(from, to).trim();
  }

  Future<PhraseReading> prepare(
    String phrase, {
    required String sentence,
    String passage = '',
  }) async {
    final selected = phrase.trim();
    final inSentence = sentence.trim();
    if (selected.isEmpty) {
      throw TutorException('Nothing is selected to translate.');
    }

    final cached = await _cache?.get(selected, inSentence);
    if (cached != null) return cached;

    final reply = await _claude.messages({
      'max_tokens': 16000,
      'system': passage.isEmpty
          ? _reader
          : '$_reader\n\nIt appears in this passage:\n\n$passage',
      'messages': [
        {
          'role': 'user',
          'content': 'Sentence: $inSentence\n\nSelected: $selected',
        },
      ],
      'output_config': {
        'format': {'type': 'json_schema', 'schema': _schema},
      },
    });

    final PhraseReading reading;
    try {
      final json = jsonDecode(ClaudeClient.textOf(reply));
      if (json is! Map<String, dynamic>) {
        throw const FormatException('the phrase reading was not an object');
      }
      reading = PhraseReading.fromJson({
        ...json,
        'phrase': selected,
        'sentence': inSentence,
      });
    } on FormatException catch (e) {
      throw TutorException('The companion did not translate that: $e');
    }

    await _cache?.put(reading);
    return reading;
  }
}

/// Phrase readings on disk, addressed by the selection and its sentence.
class PhraseCache {
  PhraseCache(this.directory);

  final Directory directory;

  static Future<PhraseCache> open() async {
    final docs = await getApplicationDocumentsDirectory();
    return PhraseCache(Directory('${docs.path}/chinese_phrases'));
  }

  /// A NUL between the two halves, which no book's text contains, keeps
  /// `ab` + `c` apart from `a` + `bc`.
  File _fileFor(String phrase, String sentence) => File(
    '${directory.path}/${ReadingCache.keyFor('${phrase.trim()}\u0000${sentence.trim()}')}.json',
  );

  /// Null for anything not read before. A collision, a half-written file or
  /// an older shape all read as a miss: being wrong costs one more call.
  Future<PhraseReading?> get(String phrase, String sentence) async {
    final file = _fileFor(phrase, sentence);
    if (!await file.exists()) return null;
    try {
      final json =
          jsonDecode(await file.readAsString()) as Map<String, dynamic>;
      final reading = PhraseReading.fromJson(json);
      if (reading.phrase != phrase.trim() ||
          reading.sentence != sentence.trim()) {
        return null;
      }
      return reading;
    } on FormatException {
      return null;
    } on TypeError {
      return null;
    }
  }

  Future<void> put(PhraseReading reading) async {
    if (reading.phrase.isEmpty) return;
    await directory.create(recursive: true);
    await _fileFor(
      reading.phrase,
      reading.sentence,
    ).writeAsString(jsonEncode(reading.toJson()));
  }
}
