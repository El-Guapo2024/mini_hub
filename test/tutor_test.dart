import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:mini_hub/chinese/card_store.dart';
import 'package:mini_hub/chinese/claude.dart';
import 'package:mini_hub/chinese/tutor.dart';
import 'package:mini_hub/config.dart';

http.Response reply(Map<String, dynamic> body) => http.Response(
  jsonEncode(body),
  200,
  headers: {'content-type': 'application/json; charset=utf-8'},
);

/// The companion's tool loop, now run on the phone: a card the model asks
/// for is saved, its result goes back, and the answer that follows is what
/// the reader sees.
void main() {
  test('add_card saves the card and the conversation carries on', () async {
    final requests = <Map<String, dynamic>>[];
    final saved = <Card>[];
    final session = TutorSession(
      chapterContext: '他走进来了。',
      claude: ClaudeClient(
        apiKey: () async => 'k',
        client: MockClient((req) async {
          requests.add(jsonDecode(req.body) as Map<String, dynamic>);
          if (requests.length == 1) {
            return reply({
              'stop_reason': 'tool_use',
              'content': [
                {
                  'type': 'tool_use',
                  'id': 't1',
                  'name': 'add_card',
                  'input': {
                    'word': '走进',
                    'pinyin': 'zǒujìn',
                    'gloss': 'walk into',
                    'sentence': '他走进来了。',
                  },
                },
              ],
            });
          }
          return reply({
            'stop_reason': 'end_turn',
            'content': [
              {'type': 'text', 'text': 'Saved 走进.'},
            ],
          });
        }),
      ),
      saveCard: (card) async => saved.add(card),
    );

    final answer = await session.ask('save 走进');

    expect(answer, 'Saved 走进.');
    expect(saved.single.word, '走进');
    final results = (requests.last['messages'] as List).last['content'] as List;
    expect(results.single['type'], 'tool_result');
    expect(results.single['tool_use_id'], 't1');
  });

  test('a failed question leaves no half turn behind', () async {
    var calls = 0;
    final session = TutorSession(
      chapterContext: '',
      claude: ClaudeClient(
        apiKey: () async => 'k',
        client: MockClient((req) async {
          calls++;
          if (calls == 1) return http.Response('{}', 500);
          final messages = jsonDecode(req.body)['messages'] as List;
          expect(messages.length, 1, reason: 'the failed turn was dropped');
          return reply({
            'stop_reason': 'end_turn',
            'content': [
              {'type': 'text', 'text': 'ok'},
            ],
          });
        }),
      ),
      saveCard: (_) async {},
    );

    await expectLater(session.ask('one'), throwsA(isA<TutorException>()));
    expect(await session.ask('two'), 'ok');
  });

  test('the chosen model is sent; only Opus carries fallbacks', () async {
    for (final model in CompanionModel.values) {
      late http.Request sent;
      final session = TutorSession(
        chapterContext: '',
        claude: ClaudeClient(
          apiKey: () async => 'k',
          model: () async => model,
          client: MockClient((req) async {
            sent = req;
            return reply({
              'stop_reason': 'end_turn',
              'content': [
                {'type': 'text', 'text': 'ok'},
              ],
            });
          }),
        ),
      );

      await session.ask('hi');
      final body = jsonDecode(sent.body) as Map<String, dynamic>;
      expect(body['model'], model.id);
      final opus = model == CompanionModel.opus;
      expect(body.containsKey('fallbacks'), opus, reason: model.name);
      expect(sent.headers.containsKey('anthropic-beta'), opus);
    }
  });

  test('no key says where to add one', () async {
    final session = TutorSession(
      chapterContext: '',
      claude: ClaudeClient(
        apiKey: () async => null,
        client: MockClient((_) async => fail('no request without a key')),
      ),
    );

    expect(
      () => session.ask('hi'),
      throwsA(
        isA<TutorException>().having(
          (e) => e.message,
          'message',
          contains('API key'),
        ),
      ),
    );
  });
}
