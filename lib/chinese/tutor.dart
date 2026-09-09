import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

import '../config.dart';
import 'card_store.dart';

/// What the companion says when the call fails — shown to the reader as-is.
class TutorException implements Exception {
  TutorException(this.message);
  final String message;
  @override
  String toString() => message;
}

/// One conversation with the companion, anchored to the open chapter.
///
/// The companion is the Mac-side Agent SDK server (tutor_server/), which
/// answers on this machine's Claude login and can add Anki cards through
/// its own tool. The phone only ever talks to that server.
class TutorSession {
  TutorSession({required this.chapterContext});

  /// The visible chapter's text, sent with every question.
  String chapterContext;

  final List<Map<String, String>> turns = [];

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
    turns.add({'role': 'user', 'content': question});
    await _log('ask "$question"');
    final http.Response resp;
    try {
      resp = await http.post(
        Uri.parse('${ChineseConfig.tutorServer}/ask'),
        headers: {'content-type': 'application/json'},
        body: jsonEncode({
          'question': question,
          'chapter': chapterContext,
          'history': turns.sublist(0, turns.length - 1),
        }),
      );
    } catch (e) {
      turns.removeLast();
      await _log('transport error: $e');
      throw TutorException(
        'Companion server not reachable — start it on the Mac:\n'
        'node tutor_server/server.mjs',
      );
    }
    await _log('status ${resp.statusCode}');
    if (resp.statusCode != 200) {
      turns.removeLast();
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

    final Map<String, dynamic> json;
    try {
      json = jsonDecode(utf8.decode(resp.bodyBytes)) as Map<String, dynamic>;
    } on FormatException {
      turns.removeLast();
      throw TutorException('Unexpected reply from the companion server.');
    }

    // Cards the agent's add_card tool created ride back in the response;
    // the phone stays the source of truth for the deck.
    for (final c in (json['cards'] as List? ?? [])) {
      final store = await CardStore.open();
      await store.add(
        Card(
          word: c['word'] as String? ?? '',
          pinyin: c['pinyin'] as String? ?? '',
          gloss: c['gloss'] as String? ?? '',
          sentence: c['sentence'] as String? ?? '',
        ),
      );
    }
    final text = json['text'] as String? ?? '';
    turns.add({'role': 'assistant', 'content': text});
    return text;
  }
}
