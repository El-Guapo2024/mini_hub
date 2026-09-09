import 'package:record/record.dart';
import 'package:whisper_ggml/whisper_ggml.dart';

/// Hold-to-talk speech recognition, on the phone, via whisper.cpp.
///
/// Whisper replaces iOS dictation because questions mix languages —
/// "why is 了 here?" — and the system recognizer is locked to one. The
/// base multilingual model (~140MB) downloads once on first use.
class Transcriber {
  final WhisperController _whisper = WhisperController();
  final AudioRecorder _recorder = AudioRecorder();

  static const WhisperModel _model = WhisperModel.base;

  WhisperLiveSession? _session;

  /// Resolves when the model file is on disk (no-op after the first time).
  Future<void> ensureReady() => _whisper.downloadModel(_model);

  /// Streaming mode: the mic feeds Whisper while the button is held, and
  /// [onPartial] receives progressively refined transcripts to show live.
  Future<bool> start(void Function(String) onPartial) async {
    if (!await _recorder.hasPermission()) return false;
    final stream = await _recorder.startStream(
      const RecordConfig(
        encoder: AudioEncoder.pcm16bits,
        sampleRate: 16000,
        numChannels: 1,
      ),
    );
    _session = await _whisper.transcribeLive(
      model: _model,
      pcm16Stream: stream,
      lang: 'auto',
    );
    _session!.partials.listen(onPartial);
    return true;
  }

  /// Stop recording and return the final text ('' when nothing usable).
  Future<String> stop() async {
    final session = _session;
    _session = null;
    if (session == null) return '';
    await _recorder.stop(); // closes the stream; the session finalizes
    final text = await session.stop();
    return text.trim();
  }

  Future<void> cancel() async {
    await _recorder.cancel();
    await _session?.stop();
    _session = null;
  }

  void dispose() {
    _recorder.dispose();
  }
}
