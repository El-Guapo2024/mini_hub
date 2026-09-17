import 'dart:io';

import 'package:path_provider/path_provider.dart';

import 'anki_sync.dart';
import 'card.dart';
import 'claude.dart';
import 'keep_card.dart';

export 'claude.dart' show TutorException;

/// One conversation with the companion, anchored to the open chapter.
///
/// The phone talks to the Claude API directly, on the reader's own key. The
/// model can list the learner's Anki decks and add cards to any of them; the
/// loop that runs those tools lives here, and every card is kept on the
/// phone first — the phone stays the source of truth.
class TutorSession {
  TutorSession({
    required this.chapterContext,
    ClaudeClient? claude,
    Future<Card?> Function(String word)? cardFor,
    Future<void> Function(Card card, String? deck)? saveCard,
    Future<List<String>> Function()? listDecks,
  }) : _claude = claude ?? ClaudeClient(),
       _cardFor = cardFor ?? _bareCard,
       _saveCard = saveCard ?? _toDeck,
       _listDecks = listDecks ?? _ankiDecks;

  /// The visible chapter's text, sent with every question.
  String chapterContext;

  final ClaudeClient _claude;

  /// Builds the card for a word exactly as tapping it in the book does:
  /// pinyin and meaning from the dictionary, the sentence from the chapter.
  /// Null when the dictionary doesn't know the word.
  final Future<Card?> Function(String word) _cardFor;
  final Future<void> Function(Card card, String? deck) _saveCard;
  final Future<List<String>> Function() _listDecks;

  /// The whole conversation as the API sees it, replies kept verbatim —
  /// thinking blocks included, which must go back unchanged.
  final List<Map<String, dynamic>> _messages = [];

  /// Rounds of tool use one question may take before giving up.
  static const int _maxRounds = 5;

  static const String _persona =
      'You are a native Chinese speaker reading a book together with a '
      'learner, sitting beside them. Answer their questions about the text in '
      'English, with Chinese examples where they help. Be concise and warm; '
      'answer only what was asked. Pay special attention to meaning that is '
      'implied rather than written: dropped subjects, unmarked conditionals, '
      'aspect particles. Never correct the learner unless they ask to be '
      'corrected. When the learner asks to save or remember a word (or you '
      'both agree one is worth keeping), call the add_card tool straight '
      'away with just the word in Chinese characters, written as it appears '
      'in the passage. The app fills in the pinyin, the meaning and the '
      'sentence from its dictionary and the book, exactly as when the '
      'learner taps the word, so never ask them for those. If they name a '
      'deck, or ask which decks they have, call list_decks first and use a '
      'deck name exactly as listed; otherwise leave the deck null and the '
      'card goes to their usual deck.';

  static const Map<String, dynamic> _addCard = {
    'name': 'add_card',
    'description':
        "Add a flashcard for a word to the learner's Anki collection. Give "
        'only the word; its pinyin, meaning and example sentence come from '
        "the app's dictionary and the open book.",
    'strict': true,
    'input_schema': {
      'type': 'object',
      'properties': {
        'word': {
          'type': 'string',
          'description': 'the Chinese word or phrase, in characters',
        },
        'deck': {
          'type': ['string', 'null'],
          'description':
              'a deck name exactly as list_decks returned it, or null for '
              "the learner's usual deck",
        },
      },
      'required': ['word', 'deck'],
      'additionalProperties': false,
    },
  };

  static const Map<String, dynamic> _listDecksTool = {
    'name': 'list_decks',
    'description':
        "List the decks in the learner's connected Anki collection. Empty "
        'when no Anki account is connected.',
    'strict': true,
    'input_schema': {
      'type': 'object',
      'properties': <String, dynamic>{},
      'required': <String>[],
      'additionalProperties': false,
    },
  };

  /// Without a reader to look words up in, the card carries only the word.
  static Future<Card?> _bareCard(String word) async =>
      Card(word: word, pinyin: '', gloss: '', sentence: '');

  static Future<void> _toDeck(Card card, String? deck) async {
    await keepCard(card, deck: deck);
  }

  static Future<List<String>> _ankiDecks() => AnkiSync().decks();

  /// Same trace file the reader writes — the only observable channel from
  /// a simctl-launched app.
  static Future<void> _log(String line) async {
    try {
      final d = await getApplicationDocumentsDirectory();
      File('${d.path}/reader_log.txt').writeAsStringSync(
        '${DateTime.now().toIso8601String()} tutor: $line\n',
        mode: FileMode.append,
      );
    } catch (_) {}
  }

  Future<String> ask(String question) async {
    final start = _messages.length;
    _messages.add({'role': 'user', 'content': question});
    await _log('ask "$question"');
    try {
      for (var round = 0; round < _maxRounds; round++) {
        final reply = await _claude.messages({
          'max_tokens': 16000,
          'system':
              '$_persona\n\nThe reader currently has this passage open:'
              '\n\n$chapterContext',
          'tools': [_addCard, _listDecksTool],
          'messages': _messages,
        });
        final content = reply['content'] as List? ?? [];
        _messages.add({'role': 'assistant', 'content': content});
        if (reply['stop_reason'] != 'tool_use') {
          await _log('answered');
          return ClaudeClient.textOf(reply);
        }
        // Every result for this round goes back in one message.
        _messages.add({
          'role': 'user',
          'content': [
            for (final block in content)
              if (block is Map && block['type'] == 'tool_use')
                await _runTool(block),
          ],
        });
      }
      throw TutorException('The companion went round in circles — ask again.');
    } catch (e) {
      // A failed question leaves no half turn for the next one to trip on.
      _messages.removeRange(start, _messages.length);
      await _log('error: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> _runTool(Map block) async {
    final input = block['input'] as Map? ?? {};
    String field(String name) => (input[name] as String? ?? '').trim();
    final result = {'type': 'tool_result', 'tool_use_id': block['id']};
    try {
      switch (block['name']) {
        case 'list_decks':
          final decks = await _listDecks();
          return {
            ...result,
            'content': decks.isEmpty
                ? 'No Anki account is connected; cards stay on the phone.'
                : decks.join('\n'),
          };
        case 'add_card':
          final word = field('word');
          final deck = field('deck').isEmpty ? null : field('deck');
          if (deck != null) {
            // A misspelt name would quietly create a new deck in Anki;
            // send the model back to the real list instead.
            final decks = await _listDecks();
            if (decks.isNotEmpty && !decks.contains(deck)) {
              return {
                ...result,
                'content': 'No deck named "$deck". Decks: ${decks.join(', ')}',
                'is_error': true,
              };
            }
          }
          final card = word.isEmpty ? null : await _cardFor(word);
          if (card == null) {
            return {
              ...result,
              'content':
                  '"$word" is not in the dictionary; try the word exactly as '
                  'written in the passage, in characters.',
              'is_error': true,
            };
          }
          await _saveCard(card, deck);
          return {
            ...result,
            'content':
                'card saved: ${card.word} ${card.pinyin} — ${card.gloss}'
                '${deck == null ? '' : ' (to $deck)'}',
          };
      }
      return {...result, 'content': 'no such tool', 'is_error': true};
    } catch (e) {
      return {...result, 'content': 'could not do that: $e', 'is_error': true};
    }
  }
}
