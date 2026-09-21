import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

import '../config.dart';
import 'connections.dart';

/// Azure's text to speech, for the companion's own voice.
///
/// The book is read by the device's voice, which is free, works offline and
/// reports word boundaries so the page can follow along. Only the
/// companion's answers come from here: they are short, so the cost is
/// pennies, and they are the one place the robotic default grated.
///
/// This is the REST endpoint rather than the Speech SDK. The SDK is the only
/// way to get word-boundary events, but those are of no use here — nothing
/// highlights an answer as it is spoken — and the REST call is a single POST
/// with no native dependency to build for the device.
class AzureTts {
  AzureTts({http.Client? client, ConnectionStore? store})
    : _client = client ?? http.Client(),
      _store = store ?? const ConnectionStore();

  final http.Client _client;
  final ConnectionStore _store;

  /// One multilingual voice for every run, English and Chinese alike.
  ///
  /// The answer is split into runs of one script each (see Speech.languageRuns)
  /// and each run is a separate request, which is also what Azure's own advice
  /// asks for — mixing languages in one request can shift the accent
  /// mid-sentence. Using a single multilingual voice for all of them keeps one
  /// speaker across the whole answer; two different voices trading lines
  /// sounded worse than either voice alone.
  static const String voice = 'zh-CN-XiaoxiaoMultilingualNeural';

  /// 24 kHz MP3: small enough that a sentence arrives quickly, and an
  /// extension every iOS decoder recognises.
  static const String _format = 'audio-24khz-48kbitrate-mono-mp3';

  /// The saved Azure connector, or null when none is set up.
  Future<Connection?> connection() => _store.active(ConnectorKind.azure);

  /// The key and region to speak with: the reader's own saved connector
  /// when there is one, and the build's compiled-in pair otherwise. A key
  /// someone entered themselves is theirs, so it wins.
  ///
  /// Null when neither exists, which is not an error — it is how a build
  /// with no key at all behaves, and the caller simply uses the device
  /// voice instead.
  Future<({String key, String region})?> _credentials() async {
    final c = await connection();
    var key = (c?.secret ?? '').trim();
    if (key.isEmpty) key = ChineseConfig.azureKey.trim();
    var region = (c?.endpoint ?? '').trim();
    if (region.isEmpty) region = ChineseConfig.azureRegion.trim();
    if (key.isEmpty || region.isEmpty) return null;
    return (key: key, region: region.toLowerCase());
  }

  /// Speaks [text] in [language] and returns the audio file to play.
  ///
  /// Returns null when no key is configured at all, saved or built in.
  /// Throws [AzureTtsException] when there is one and the call fails, so a
  /// broken key is reported rather than silently sounding like the old voice.
  Future<File?> synthesize(String text, String language) async {
    final creds = await _credentials();
    if (creds == null) return null;
    final key = creds.key;
    final region = creds.region;

    final uri = Uri.parse(
      'https://$region.tts.speech.microsoft.com/cognitiveservices/v1',
    );
    final ssml =
        "<speak version='1.0' xml:lang='$language'>"
        "<voice xml:lang='$language' name='$voice'>"
        '${_escape(text)}'
        '</voice></speak>';

    final reply = await _client.post(
      uri,
      headers: {
        'Ocp-Apim-Subscription-Key': key,
        'Content-Type': 'application/ssml+xml',
        'X-Microsoft-OutputFormat': _format,
        // Azure requires this header and rejects the request without it.
        'User-Agent': 'mini_hub',
      },
      body: utf8.encode(ssml),
    );

    if (reply.statusCode != 200) {
      throw AzureTtsException(_reason(reply.statusCode));
    }

    // just_audio picks its decoder from the file extension, so the name
    // matters as much as the bytes. Keyed by content: the same sentence
    // spoken twice is fetched once.
    final dir = await getTemporaryDirectory();
    // Not a cryptographic hash, and it does not need to be: this only has to
    // name a scratch file distinctly, and a collision costs one replayed
    // sentence. Unsigned so the name never carries a minus sign.
    final name = '$language$voice$text'.hashCode.toUnsigned(32);
    final file = File('${dir.path}/azure_$name.mp3');
    if (!file.existsSync() || file.lengthSync() == 0) {
      await file.writeAsBytes(reply.bodyBytes, flush: true);
    }
    return file;
  }

  static String _reason(int status) => switch (status) {
    401 => 'Azure rejected the key. Check the key and that its region '
        'matches the one saved with it.',
    415 => 'Azure refused the request format.',
    429 => 'Azure is rate limiting, or the free quota for the month is used '
        'up. The device voice still works.',
    >= 500 => 'Azure is having trouble ($status). The device voice still '
        'works.',
    _ => 'Azure would not speak that ($status).',
  };

  /// SSML is XML: an ampersand or angle bracket in an answer would otherwise
  /// break the whole request.
  static String _escape(String s) => s
      .replaceAll('&', '&amp;')
      .replaceAll('<', '&lt;')
      .replaceAll('>', '&gt;')
      .replaceAll("'", '&apos;')
      .replaceAll('"', '&quot;');
}

class AzureTtsException implements Exception {
  const AzureTtsException(this.message);

  final String message;

  @override
  String toString() => message;
}
