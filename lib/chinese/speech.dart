import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';

import '../config.dart';

/// The one place that speaks. Today it is the on-device zh-CN voice; if the
/// engine ever changes, this file is the whole change.
class Speech {
  Speech() {
    _tts
      ..setLanguage(ChineseConfig.ttsLanguage)
      ..setSpeechRate(ChineseConfig.ttsRate)
      ..setStartHandler(() => speaking.value = true)
      ..setCompletionHandler(() => speaking.value = false)
      ..setCancelHandler(() => speaking.value = false);
  }

  final FlutterTts _tts = FlutterTts();

  /// True while the voice is talking — so a stop control can exist only
  /// when there is something to stop.
  final ValueNotifier<bool> speaking = ValueNotifier(false);

  /// Best installed voice per language, resolved once. iOS ships a robotic
  /// default; the premium/enhanced voices (downloadable in Settings >
  /// Accessibility > Spoken Content) are dramatically better — prefer them.
  final Map<String, Map<String, String>?> _bestVoice = {};

  Future<Map<String, String>?> _pickVoice(String language) async {
    if (_bestVoice.containsKey(language)) return _bestVoice[language];
    Map<String, String>? best;
    try {
      final voices = (await _tts.getVoices as List)
          .cast<Map>()
          .where(
            (v) => (v['locale'] as String? ?? '').toLowerCase().startsWith(
              language.toLowerCase().substring(0, 2),
            ),
          )
          .toList();
      int rank(Map v) {
        final id = ('${v['identifier'] ?? ''} ${v['name'] ?? ''}')
            .toLowerCase();
        if (id.contains('premium')) return 0;
        if (id.contains('enhanced')) return 1;
        return 2;
      }

      voices.sort((a, b) => rank(a).compareTo(rank(b)));
      if (voices.isNotEmpty && rank(voices.first) < 2) {
        best = {
          'name': voices.first['name'] as String,
          'locale': voices.first['locale'] as String,
        };
      }
    } catch (_) {
      // No voice list — the language default will do.
    }
    _bestVoice[language] = best;
    return best;
  }

  Future<void> speak(String text, {String? language}) async {
    final lang = language ?? ChineseConfig.ttsLanguage;
    await _tts.stop();
    await _tts.setLanguage(lang);
    final voice = await _pickVoice(lang);
    if (voice != null) await _tts.setVoice(voice);
    await _tts.speak(text);
  }

  Future<void> stop() async {
    await _tts.stop();
    speaking.value = false;
  }
}
