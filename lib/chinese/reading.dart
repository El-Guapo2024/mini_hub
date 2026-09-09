import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config.dart';
import 'reading_cache.dart';
import 'tutor.dart';

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
  ReadingService({ReadingCache? cache, http.Client? client})
    : _cache = cache,
      _client = client ?? http.Client();

  final ReadingCache? _cache;
  final http.Client _client;

  Future<Reading> prepare(String sentence, {String chapter = ''}) async {
    final trimmed = sentence.trim();
    if (trimmed.isEmpty) {
      throw TutorException('There is no sentence here to explain.');
    }

    final cached = await _cache?.get(trimmed);
    if (cached != null) return cached;

    final http.Response resp;
    try {
      resp = await _client.post(
        Uri.parse('${ChineseConfig.tutorServer}/read'),
        headers: {'content-type': 'application/json'},
        body: jsonEncode({'sentence': trimmed, 'chapter': chapter}),
      );
    } catch (e) {
      throw TutorException(
        'Companion server not reachable — start it on the Mac:\n'
        'node tutor_server/server.mjs',
      );
    }

    if (resp.statusCode != 200) {
      String detail = 'HTTP ${resp.statusCode}';
      try {
        detail =
            (jsonDecode(utf8.decode(resp.bodyBytes))['error'] as String?) ??
            detail;
      } on FormatException {
        // A non-JSON body (a stray server, a proxy) — keep the status line.
      }
      throw TutorException(detail);
    }

    final Reading reading;
    try {
      final json = jsonDecode(utf8.decode(resp.bodyBytes));
      reading = Reading.fromJson({
        'sentence': trimmed,
        ...json as Map<String, dynamic>,
      });
    } on FormatException catch (e) {
      throw TutorException('The companion did not prepare a reading: $e');
    }

    await _cache?.put(reading);
    return reading;
  }
}
