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
      saveCard: (card, deck) async => saved.add(card),
    );

    final answer = await session.ask('save 走进');

    expect(answer, 'Saved 走进.');
    expect(saved.single.word, '走进');
    final results = (requests.last['messages'] as List).last['content'] as List;
    expect(results.single['type'], 'tool_result');
    expect(results.single['tool_use_id'], 't1');
  });

  /// A scripted model: each call returns the next reply in [script].
  TutorSession scripted(
    List<Map<String, dynamic>> script, {
    required List<(Card, String?)> saved,
    required List<Map<String, dynamic>> requests,
  }) => TutorSession(
    chapterContext: '他走进来了。',
    claude: ClaudeClient(
      apiKey: () async => 'k',
      client: MockClient((req) async {
        requests.add(jsonDecode(req.body) as Map<String, dynamic>);
        return reply(script[requests.length - 1]);
      }),
    ),
    // Stands in for the reader's dictionary and open chapter.
    cardFor: (word) async => word == '走进'
        ? const Card(
            word: '走进',
            pinyin: 'zǒu jìn',
            gloss: 'to walk into',
            sentence: '他走进来了。',
          )
        : null,
    saveCard: (card, deck) async => saved.add((card, deck)),
    listDecks: () async => ['Chinese::Reader', 'Mandarin::Books'],
  );

  Map<String, dynamic> toolUse(String id, String name, Map input) => {
    'stop_reason': 'tool_use',
    'content': [
      {'type': 'tool_use', 'id': id, 'name': name, 'input': input},
    ],
  };

  const done = {
    'stop_reason': 'end_turn',
    'content': [
      {'type': 'text', 'text': 'Done.'},
    ],
  };

  const card = {
    'word': '走进',
    'pinyin': 'zǒujìn',
    'gloss': 'walk into',
    'sentence': '他走进来了。',
  };

  List toolResults(Map<String, dynamic> request) =>
      (request['messages'] as List).last['content'] as List;

  test('the companion can list decks and add a card to one', () async {
    final saved = <(Card, String?)>[];
    final requests = <Map<String, dynamic>>[];
    final session = scripted(
      [
        toolUse('t1', 'list_decks', {}),
        toolUse('t2', 'add_card', {...card, 'deck': 'Mandarin::Books'}),
        done,
      ],
      saved: saved,
      requests: requests,
    );

    expect(await session.ask('save 走进 to my books deck'), 'Done.');

    final tools = (requests.first['tools'] as List).map((t) => t['name']);
    expect(tools, containsAll(['add_card', 'list_decks']));
    expect(
      toolResults(requests[1]).single['content'],
      contains('Mandarin::Books'),
    );
    expect(saved.single.$1.word, '走进');
    expect(saved.single.$2, 'Mandarin::Books');
  });

  test('a deck name not in the list is sent back, not created', () async {
    final saved = <(Card, String?)>[];
    final requests = <Map<String, dynamic>>[];
    final session = scripted(
      [
        toolUse('t1', 'add_card', {...card, 'deck': 'Mandrin'}),
        done,
      ],
      saved: saved,
      requests: requests,
    );

    await session.ask('save 走进 to Mandrin');

    final result = toolResults(requests[1]).single;
    expect(result['is_error'], isTrue);
    expect(result['content'], contains('Chinese::Reader'));
    expect(saved, isEmpty);
  });

  test('a null deck goes to the usual deck', () async {
    final saved = <(Card, String?)>[];
    final session = scripted(
      [
        toolUse('t1', 'add_card', {...card, 'deck': null}),
        done,
      ],
      saved: saved,
      requests: [],
    );

    await session.ask('save 走进');

    expect(saved.single.$2, isNull);
  });

  test('the model gives only the word; the card comes from the book', () async {
    final saved = <(Card, String?)>[];
    final requests = <Map<String, dynamic>>[];
    final session = scripted(
      [
        toolUse('t1', 'add_card', {'word': '走进', 'deck': null}),
        done,
      ],
      saved: saved,
      requests: requests,
    );

    await session.ask('add 走进');

    final schema =
        (requests.first['tools'] as List).firstWhere(
              (t) => t['name'] == 'add_card',
            )['input_schema']
            as Map;
    expect((schema['properties'] as Map).keys, ['word', 'deck']);
    expect(saved.single.$1.pinyin, 'zǒu jìn');
    expect(saved.single.$1.sentence, '他走进来了。');
    expect(toolResults(requests[1]).single['content'], contains('zǒu jìn'));
  });

  test('a word the dictionary does not know is sent back', () async {
    final saved = <(Card, String?)>[];
    final requests = <Map<String, dynamic>>[];
    final session = scripted(
      [
        toolUse('t1', 'add_card', {'word': 'zoujin', 'deck': null}),
        done,
      ],
      saved: saved,
      requests: requests,
    );

    await session.ask('add zoujin');

    expect(toolResults(requests[1]).single['is_error'], isTrue);
    expect(saved, isEmpty);
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
      saveCard: (_, _) async {},
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
