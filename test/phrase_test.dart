import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:mini_hub/chinese/claude.dart';
import 'package:mini_hub/chinese/phrase.dart';

/// A selection read in its sentence: what a drag over several words asks,
/// and what the dictionary's per-word senses cannot answer.
///
/// The same characters mean different things in different sentences, so
/// everything here keys on both — the selection and where it was made.
void main() {
  group('PhraseReading.fromJson', () {
    test('keeps the translation, the reading and the note', () {
      final read = PhraseReading.fromJson({
        'phrase': '走进来',
        'sentence': '他走进来了。',
        'translation': 'came in',
        'pinyin': 'zǒu jìnlai',
        'note': 'toward the speaker, not just "entered"',
      });

      expect(read.translation, 'came in');
      expect(read.pinyin, 'zǒu jìnlai');
      expect(read.note, contains('speaker'));
    });

    test('a selection with nothing more to say is still a reading', () {
      final read = PhraseReading.fromJson({'translation': 'a student'});

      expect(read.note, isEmpty);
      expect(read.pinyin, isEmpty);
    });

    test('no translation is not a reading', () {
      expect(
        () => PhraseReading.fromJson({'pinyin': 'xuésheng', 'note': ''}),
        throwsA(isA<FormatException>()),
      );
    });
  });

  group('PhraseService.passageAround', () {
    test('a short paragraph goes whole', () {
      const text = '他走进来了。我们都站起来。';
      expect(PhraseService.passageAround(text, 1, 4), text);
    });

    test('a long chapter sends the neighbourhood, not the chapter', () {
      final text = '${'前' * 2000}走进来${'后' * 2000}';
      final passage = PhraseService.passageAround(text, 2000, 2003);

      expect(passage, contains('走进来'));
      expect(
        passage.length,
        3 + 2 * PhraseService.passageRadius,
        reason: 'the radius either side of the selection, and no more',
      );
    });
  });

  group('PhraseCache', () {
    late Directory dir;

    setUp(() => dir = Directory.systemTemp.createTempSync('phrases'));
    tearDown(() => dir.deleteSync(recursive: true));

    const read = PhraseReading(
      phrase: '打听',
      sentence: '我去打听一下。',
      translation: 'ask around',
      pinyin: 'dǎting',
      note: '',
    );

    test('a selection read once comes back', () async {
      final cache = PhraseCache(dir);
      expect(await cache.get('打听', '我去打听一下。'), isNull);

      await cache.put(read);

      expect((await cache.get('打听', '我去打听一下。'))?.translation, 'ask around');
    });

    test('the same characters in another sentence are a miss', () async {
      final cache = PhraseCache(dir);
      await cache.put(read);

      expect(await cache.get('打听', '他打听过你。'), isNull);
    });
  });

  group('PhraseService', () {
    late Directory dir;

    setUp(() => dir = Directory.systemTemp.createTempSync('phrases'));
    tearDown(() => dir.deleteSync(recursive: true));

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

    test('sends the selection with its sentence and passage', () async {
      late Map<String, dynamic> body;
      final service = PhraseService(
        claude: claude((req) async {
          body = jsonDecode(req.body) as Map<String, dynamic>;
          return apiReply({
            'translation': 'came in',
            'pinyin': 'zǒu jìnlai',
            'note': '',
          });
        }),
      );

      final read = await service.prepare(
        ' 走进来 ',
        sentence: '他走进来了。',
        passage: '门开了。他走进来了。',
      );

      final asked = (body['messages'] as List).single['content'] as String;
      expect(asked, contains('Selected: 走进来'));
      expect(asked, contains('Sentence: 他走进来了。'));
      expect(body['system'], contains('门开了。'));
      expect(
        (body['output_config'] as Map)['format'],
        containsPair('type', 'json_schema'),
      );
      expect(read.phrase, '走进来', reason: 'trimmed, as it is cached');
      expect(read.sentence, '他走进来了。');
    });

    test('asks once per sentence, then answers from the cache', () async {
      var calls = 0;
      final service = PhraseService(
        cache: PhraseCache(dir),
        claude: claude((_) async {
          calls++;
          return apiReply({
            'translation': 'ask around',
            'pinyin': 'dǎting',
            'note': '',
          });
        }),
      );

      await service.prepare('打听', sentence: '我去打听一下。');
      await service.prepare('打听', sentence: '我去打听一下。');
      expect(calls, 1, reason: 'the second came off disk');

      await service.prepare('打听', sentence: '他打听过你。');
      expect(calls, 2, reason: 'another sentence is another question');
    });

    test('a reply with no translation is refused, and not cached', () async {
      final cache = PhraseCache(dir);
      final service = PhraseService(
        cache: cache,
        claude: claude(
          (_) async => apiReply({'translation': '', 'pinyin': '', 'note': ''}),
        ),
      );

      await expectLater(
        service.prepare('打听', sentence: '我去打听一下。'),
        throwsA(isA<TutorException>()),
      );
      expect(await cache.get('打听', '我去打听一下。'), isNull);
    });

    test('nothing selected is not sent', () async {
      var calls = 0;
      final service = PhraseService(
        claude: claude((_) async {
          calls++;
          return apiReply({'translation': 'x', 'pinyin': '', 'note': ''});
        }),
      );

      await expectLater(
        service.prepare('  ', sentence: '我去打听一下。'),
        throwsA(isA<TutorException>()),
      );
      expect(calls, 0);
    });
  });
}
