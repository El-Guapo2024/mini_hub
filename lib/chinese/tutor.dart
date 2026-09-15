import 'dart:io';

import 'package:path_provider/path_provider.dart';

import 'card_store.dart';
import 'claude.dart';

export 'claude.dart' show TutorException;

/// One conversation with the companion, anchored to the open chapter.
///
/// The phone talks to the Claude API directly, on the reader's own key. The
/// model can call add_card; the loop that runs that tool lives here, and the
/// card goes straight into the phone's deck — the phone stays the source of
/// truth.
class TutorSession {
  TutorSession({
    required this.chapterContext,
    ClaudeClient? claude,
    Future<void> Function(Card card)? saveCard,
  }) : _claude = claude ?? ClaudeClient(),
       _saveCard = saveCard ?? _toDeck;

  /// The visible chapter's text, sent with every question.
  String chapterContext;

  final ClaudeClient _claude;
  final Future<void> Function(Card card) _saveCard;

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
      'both agree one is worth keeping), call the add_card tool to put it in '
      'their Anki deck.';

  static const Map<String, dynamic> _addCard = {
    'name': 'add_card',
    'description': "Add a flashcard to the learner's Anki deck.",
    'strict': true,
    'input_schema': {
      'type': 'object',
      'properties': {
        'word': {'type': 'string', 'description': 'the Chinese word or phrase'},
        'pinyin': {'type': 'string', 'description': 'accented pinyin'},
        'gloss': {'type': 'string', 'description': 'short English meaning'},
        'sentence': {
          'type': 'string',
          'description': 'example sentence, ideally from the book',
        },
      },
      'required': ['word', 'pinyin', 'gloss', 'sentence'],
      'additionalProperties': false,
    },
  };

  static Future<void> _toDeck(Card card) async =>
      (await CardStore.open()).add(card);

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
          'tools': [_addCard],
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
    if (block['name'] != 'add_card') {
      return {...result, 'content': 'no such tool', 'is_error': true};
    }
    try {
      await _saveCard(
        Card(
          word: field('word'),
          pinyin: field('pinyin'),
          gloss: field('gloss'),
          sentence: field('sentence'),
        ),
      );
      return {...result, 'content': 'card saved: ${field('word')}'};
    } catch (e) {
      return {...result, 'content': 'could not save: $e', 'is_error': true};
    }
  }
}
