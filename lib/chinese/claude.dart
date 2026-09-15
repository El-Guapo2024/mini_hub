import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

import '../config.dart';
import 'connections.dart';

/// What the companion says when the call fails — shown to the reader as-is.
class TutorException implements Exception {
  TutorException(this.message);
  final String message;
  @override
  String toString() => message;
}

/// The reader's own Anthropic API key, kept in the Keychain.
///
/// Each person brings their own key: a key built into the app could be
/// pulled out of it by anyone who has the build, and TestFlight hands the
/// build to other people.
class ApiKeyStore {
  /// The key of the Claude connector in use (see Connectors).
  static Future<String?> read() async {
    final key = (await const ConnectionStore().active(
      ConnectorKind.claude,
    ))?.secret.trim();
    return key == null || key.isEmpty ? null : key;
  }

  /// The model chosen for that key; missing or unreadable is the default.
  static Future<CompanionModel> readModel() async {
    try {
      return (await const ConnectionStore().active(
            ConnectorKind.claude,
          ))?.model ??
          ChineseConfig.defaultModel;
    } catch (_) {
      // An unreadable preference costs a choice, not the answer.
      return ChineseConfig.defaultModel;
    }
  }
}

/// The Messages API over plain HTTP — Dart has no official SDK.
class ClaudeClient {
  ClaudeClient({
    http.Client? client,
    Future<String?> Function()? apiKey,
    Future<CompanionModel> Function()? model,
  }) : _client = client ?? http.Client(),
       _apiKey = apiKey ?? ApiKeyStore.read,
       _model = model ?? ApiKeyStore.readModel;

  final http.Client _client;
  final Future<String?> Function() _apiKey;

  /// Read per request, so switching keys or models in Connectors applies to
  /// the next call.
  final Future<CompanionModel> Function() _model;

  static final Uri _endpoint = Uri.parse(
    'https://api.anthropic.com/v1/messages',
  );

  /// Past this, a call is reported as failed instead of spinning forever.
  static const Duration timeout = Duration(seconds: 90);

  /// Same trace file the reader writes — the only observable channel from a
  /// simctl-launched app. Never the key itself.
  static void _trace(String line) {
    getApplicationDocumentsDirectory()
        .then(
          (d) => File('${d.path}/reader_log.txt').writeAsStringSync(
            '${DateTime.now().toIso8601String()} claude: $line\n',
            mode: FileMode.append,
          ),
        )
        .catchError((_) {});
  }

  /// One request. [body] is everything but the model; the reply comes back
  /// decoded, and anything that is not an answer becomes a [TutorException].
  Future<Map<String, dynamic>> messages(Map<String, dynamic> body) async {
    final key = await _apiKey();
    _trace(key == null ? 'no key saved' : 'key saved');
    if (key == null) {
      throw TutorException(
        'Add a Claude API key first — Connectors, on the Chinese shelf.',
      );
    }

    final model = await _model();
    // On Opus, a declined request is re-run on a fallback model inside the
    // same call instead of the reader getting nothing. The cheaper models
    // are not sent the parameter.
    final fallbacks = model == CompanionModel.opus;

    _trace('-> ${model.id}');
    final clock = Stopwatch()..start();
    final http.Response resp;
    try {
      resp = await _client
          .post(
            _endpoint,
            headers: {
              'content-type': 'application/json',
              'x-api-key': key,
              'anthropic-version': '2023-06-01',
              if (fallbacks)
                'anthropic-beta': 'server-side-fallback-2026-07-01',
            },
            body: jsonEncode({
              'model': model.id,
              if (fallbacks) 'fallbacks': 'default',
              ...body,
            }),
          )
          .timeout(timeout);
    } on TimeoutException {
      _trace('timed out after ${clock.elapsed.inSeconds}s');
      throw TutorException(
        'The companion took too long to answer — try again.',
      );
    } catch (e) {
      _trace('transport error: $e');
      throw TutorException('Could not reach the Claude API — are you online?');
    }
    _trace(
      '<- HTTP ${resp.statusCode} in ${clock.elapsedMilliseconds}ms'
      '${resp.statusCode == 200 ? '' : ': ${utf8.decode(resp.bodyBytes, allowMalformed: true)}'}',
    );

    Map<String, dynamic>? json;
    try {
      json = jsonDecode(utf8.decode(resp.bodyBytes)) as Map<String, dynamic>;
    } on FormatException {
      // A non-JSON body (a captive portal, a proxy) — the status line says it.
    } on TypeError {
      // JSON, but not an object.
    }

    if (resp.statusCode == 401) {
      throw TutorException(
        'The API key was rejected — replace it or pick another in Connectors.',
      );
    }
    if (resp.statusCode != 200) {
      final message = (json?['error'] as Map?)?['message'] as String?;
      throw TutorException(message ?? 'HTTP ${resp.statusCode}');
    }
    if (json == null) {
      throw TutorException('Unexpected reply from the Claude API.');
    }
    if (json['stop_reason'] == 'refusal') {
      throw TutorException('The companion declined to answer that.');
    }
    return json;
  }

  /// The text blocks of a reply, joined. Thinking and tool blocks are not
  /// something to show the reader.
  static String textOf(Map<String, dynamic> reply) => [
    for (final block in (reply['content'] as List? ?? []))
      if (block is Map && block['type'] == 'text') block['text'] as String,
  ].join().trim();
}
