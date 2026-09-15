import 'dart:convert';

import 'claude.dart';
import 'reading_cache.dart';

/// One thing the sentence means without saying it.
///
/// The doc's first finding is that Chinese meaning lives in the clause and
/// much of it is never written — dropped subjects, unmarked conditionals,
/// aspect particles. A note names the bit of the sentence it is about, so it
/// can be read against the text rather than as loose commentary.
class ReadingNote {
  const ReadingNote({required this.about, required this.says});

  /// The fragment being explained, quoted from the sentence.
  final String about;

  /// What it carries that the characters do not spell out.
  final String says;

  Map<String, String> toJson() => {'about': about, 'says': says};

  factory ReadingNote.fromJson(Map<String, dynamic> j) => ReadingNote(
    about: (j['about'] as String? ?? '').trim(),
    says: (j['says'] as String? ?? '').trim(),
  );
}

/// A prepared sentence: what it says, and what it implies.
///
/// The prepared unit is the sentence, never the word — `走进` is not `走` plus
/// `进`. Word lookup stays the dictionary's job; this is the other half.
class Reading {
  const Reading({
    required this.sentence,
    required this.translation,
    required this.notes,
  });

  final String sentence;
  final String translation;
  final List<ReadingNote> notes;

  Map<String, dynamic> toJson() => {
    'sentence': sentence,
    'translation': translation,
    'notes': [for (final n in notes) n.toJson()],
  };

  /// Tolerant by design: the model writes this, so a missing `notes` or a
  /// malformed note is a thinner reading rather than a failed one. Only a
  /// reply with no translation at all is worth refusing.
  factory Reading.fromJson(Map<String, dynamic> j) {
    final translation = (j['translation'] as String? ?? '').trim();
    if (translation.isEmpty) {
      throw const FormatException('the reading carried no translation');
    }
    final notes = <ReadingNote>[];
    for (final raw in (j['notes'] as List? ?? [])) {
      if (raw is! Map<String, dynamic>) continue;
      final note = ReadingNote.fromJson(raw);
      if (note.says.isEmpty) continue;
      notes.add(note);
    }
    return Reading(
      sentence: (j['sentence'] as String? ?? '').trim(),
      translation: translation,
      notes: notes,
    );
  }
}

/// Prepares sentences, and remembers the ones it has prepared.
///
/// A reader meets the same sentence again on the way back through a page, and
/// a prepared reading does not change — so the cache is checked first and the
/// companion is asked only for what is genuinely new.
class ReadingService {
  ReadingService({ReadingCache? cache, ClaudeClient? claude})
    : _cache = cache,
      _claude = claude ?? ClaudeClient();

  final ReadingCache? _cache;
  final ClaudeClient _claude;

  static const String _reader =
      'You prepare one Chinese sentence for a learner reading a book.\n\n'
      'translation: natural English for the whole sentence, not word by '
      'word.\n'
      'notes: only meaning that is implied rather than written — dropped '
      'subjects, unmarked conditionals, aspect particles, register, an idiom '
      'whose parts mislead. "about" quotes the fragment from the sentence; '
      '"says" is one plain English line about what it carries. A sentence '
      'that implies nothing beyond its words gets an empty notes list; do not '
      'pad it with a gloss of every word, which is what this exists instead '
      'of.';

  /// Structured output: the API holds the reply to this shape, so there is
  /// no fence-stripping of a model told to emit bare JSON.
  static const Map<String, dynamic> _schema = {
    'type': 'object',
    'properties': {
      'translation': {'type': 'string'},
      'notes': {
        'type': 'array',
        'items': {
          'type': 'object',
          'properties': {
            'about': {'type': 'string'},
            'says': {'type': 'string'},
          },
          'required': ['about', 'says'],
          'additionalProperties': false,
        },
      },
    },
    'required': ['translation', 'notes'],
    'additionalProperties': false,
  };

  Future<Reading> prepare(String sentence, {String chapter = ''}) async {
    final trimmed = sentence.trim();
    if (trimmed.isEmpty) {
      throw TutorException('There is no sentence here to explain.');
    }

    final cached = await _cache?.get(trimmed);
    if (cached != null) return cached;

    final reply = await _claude.messages({
      'max_tokens': 16000,
      'system': '$_reader\n\nIt appears in this passage:\n\n$chapter',
      'messages': [
        {'role': 'user', 'content': 'Prepare this sentence:\n\n$trimmed'},
      ],
      'output_config': {
        'format': {'type': 'json_schema', 'schema': _schema},
      },
    });

    final Reading reading;
    try {
      final json = jsonDecode(ClaudeClient.textOf(reply));
      if (json is! Map<String, dynamic>) {
        throw const FormatException('the reading was not an object');
      }
      reading = Reading.fromJson({'sentence': trimmed, ...json});
    } on FormatException catch (e) {
      throw TutorException('The companion did not prepare a reading: $e');
    }

    await _cache?.put(reading);
    return reading;
  }
}
