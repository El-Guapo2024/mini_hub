import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:mini_hub/chinese/claude.dart';
import 'package:mini_hub/chinese/reading.dart';
import 'package:mini_hub/chinese/reading_cache.dart';

/// A prepared reading survives what a model actually sends back.
///
/// The companion writes this JSON, so the parse is the boundary between an
/// agent's output and the sheet. It is deliberately lenient about everything
/// except the translation: a reading with no notes is a sentence that implies
/// nothing, which is a real answer, while a reading with no translation is
/// nothing at all.
void main() {
  group('Reading.fromJson', () {
    test('keeps the translation and its notes', () {
      final reading = Reading.fromJson({
        'sentence': '他走进来了。',
        'translation': 'He came in.',
        'notes': [
          {'about': '走进来', 'says': 'toward the speaker — not just "entered"'},
          {'about': '了', 'says': 'the change of state, not a past tense'},
        ],
      });

      expect(reading.translation, 'He came in.');
      expect(reading.notes.length, 2);
      expect(reading.notes.first.about, '走进来');
    });

    test('a sentence that implies nothing is still a reading', () {
      final reading = Reading.fromJson({
        'sentence': '我是学生。',
        'translation': 'I am a student.',
      });

      expect(reading.notes, isEmpty);
    });

    test('a half-written note is dropped, the reading is not', () {
      final reading = Reading.fromJson({
        'translation': 'He came in.',
        'notes': [
          {'about': '了'},
          'not a note at all',
          {'about': '走进来', 'says': 'toward the speaker'},
        ],
      });

      expect(reading.notes.length, 1);
      expect(reading.notes.single.says, 'toward the speaker');
    });

    test('no translation is not a reading', () {
      expect(
        () => Reading.fromJson({'notes': <dynamic>[]}),
        throwsA(isA<FormatException>()),
      );
    });
  });

  group('ReadingCache', () {
    late Directory dir;

    setUp(() => dir = Directory.systemTemp.createTempSync('readings'));
    tearDown(() => dir.deleteSync(recursive: true));

    test('a sentence prepared once comes back', () async {
      final cache = ReadingCache(dir);
      const sentence = '他走进来了。';
      expect(await cache.get(sentence), isNull);

      await cache.put(
        const Reading(
          sentence: sentence,
          translation: 'He came in.',
          notes: [ReadingNote(about: '了', says: 'change of state')],
        ),
      );

      final hit = await cache.get(sentence);
      expect(hit?.translation, 'He came in.');
      expect(hit?.notes.single.says, 'change of state');
    });

    test('the key survives a restart, so the cache keeps hitting', () {
      // The point of hashing the bytes rather than leaning on hashCode.
      expect(ReadingCache.keyFor('他走进来了。'), ReadingCache.keyFor('他走进来了。'));
      expect(
        ReadingCache.keyFor('他走进来了。'),
        isNot(ReadingCache.keyFor('他走出去了。')),
      );
      expect(ReadingCache.keyFor(' 他走进来了。 '), ReadingCache.keyFor('他走进来了。'));
    });

    test('a file holding a different sentence reads as a miss', () async {
      final cache = ReadingCache(dir);
      dir.createSync(recursive: true);
      File(
        '${dir.path}/${ReadingCache.keyFor('他走进来了。')}.json',
      ).writeAsStringSync(
        jsonEncode({
          'sentence': '别的句子。',
          'translation': 'A different sentence.',
          'notes': <dynamic>[],
        }),
      );

      expect(await cache.get('他走进来了。'), isNull);
    });

    test('a corrupt file reads as a miss, not a crash', () async {
      final cache = ReadingCache(dir);
      dir.createSync(recursive: true);
      File(
        '${dir.path}/${ReadingCache.keyFor('他走进来了。')}.json',
      ).writeAsStringSync('{ half a fi');

      expect(await cache.get('他走进来了。'), isNull);
    });
  });

  group('ReadingService', () {
    late Directory dir;

    setUp(() => dir = Directory.systemTemp.createTempSync('readings'));
    tearDown(() => dir.deleteSync(recursive: true));

    /// A Messages API reply whose one text block is [json], encoded.
    http.Response apiReply(Object json) => http.Response(
      jsonEncode({
        'stop_reason': 'end_turn',
        'content': [
          {'type': 'text', 'text': jsonEncode(json)},
        ],
      }),
      200,
      headers: {'content-type': 'application/json; charset=utf-8'},
    );

    ClaudeClient claude(MockClientHandler handler) =>
        ClaudeClient(apiKey: () async => 'k', client: MockClient(handler));

    test('asks once, then answers from the cache', () async {
      var calls = 0;
      final service = ReadingService(
        cache: ReadingCache(dir),
        claude: claude((req) async {
          calls++;
          expect(req.headers['x-api-key'], 'k');
          final messages = jsonDecode(req.body)['messages'] as List;
          expect(messages.single['content'], contains('他走进来了。'));
          return apiReply({
            'translation': 'He came in.',
            'notes': [
              {'about': '了', 'says': 'change of state'},
            ],
          });
        }),
      );

      final first = await service.prepare('他走进来了。', chapter: 'a chapter');
      final second = await service.prepare('他走进来了。', chapter: 'a chapter');

      expect(first.translation, 'He came in.');
      expect(second.notes.single.about, '了');
      expect(calls, 1, reason: 'the second reading came off disk');
    });

    test('the API error is what the reader is shown', () async {
      final service = ReadingService(
        claude: claude(
          (_) async => http.Response(
            jsonEncode({
              'type': 'error',
              'error': {'type': 'overloaded_error', 'message': 'Overloaded'},
            }),
            529,
          ),
        ),
      );

      expect(
        () => service.prepare('他走进来了。'),
        throwsA(
          isA<TutorException>().having(
            (e) => e.message,
            'message',
            'Overloaded',
          ),
        ),
      );
    });

    test('offline says so', () async {
      final service = ReadingService(
        claude: claude((_) async => throw const SocketException('nope')),
      );

      expect(
        () => service.prepare('他走进来了。'),
        throwsA(
          isA<TutorException>().having(
            (e) => e.message,
            'message',
            contains('online'),
          ),
        ),
      );
    });

    test('a rejected key says where to replace it', () async {
      final service = ReadingService(
        claude: claude((_) async => http.Response('{}', 401)),
      );

      expect(
        () => service.prepare('他走进来了。'),
        throwsA(
          isA<TutorException>().having(
            (e) => e.message,
            'message',
            contains('replace it'),
          ),
        ),
      );
    });

    test('a reply that is not a reading is not cached', () async {
      final cache = ReadingCache(dir);
      final service = ReadingService(
        cache: cache,
        claude: claude((_) async => apiReply({'notes': <dynamic>[]})),
      );

      await expectLater(
        service.prepare('他走进来了。'),
        throwsA(isA<TutorException>()),
      );
      expect(await cache.get('他走进来了。'), isNull);
    });
  });
}
