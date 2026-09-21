import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/services.dart' show rootBundle;
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';
import 'package:sherpa_onnx/sherpa_onnx.dart' as sherpa;

/// Tap-to-talk speech recognition that types as you speak, on the phone.
///
/// sherpa-onnx with a streaming zipformer trained on Chinese and English
/// together (X-ASR, 480 ms chunks, with punctuation): words appear while
/// talking, a question can mix languages — "why is 了 here?" — and no audio
/// leaves the phone. Whisper transcribed mixed speech too, but only in
/// bursts; the iOS recognizer streamed, but in one language at a time.
class Transcriber {
  final AudioRecorder _recorder = AudioRecorder();

  /// The model is large (~160MB on disk, most of it the int8 encoder), so
  /// it is loaded once for the app's life.
  static sherpa.OnlineRecognizer? _recognizer;
  static Future<void>? _loading;

  sherpa.OnlineStream? _stream;
  StreamSubscription<Uint8List>? _mic;
  void Function(String)? _onPartial;

  /// Text from utterances already closed by a pause; the recognizer resets
  /// after each, so the field shows these plus the one in progress.
  String _committed = '';

  static const String _assetDir = 'assets/chinese/asr';
  static const List<String> _files = [
    'encoder.int8.onnx',
    'decoder.onnx',
    'joiner.int8.onnx',
    'tokens.txt',
  ];
  static const int _sampleRate = 16000;

  /// Same trace file the reader writes — the only observable channel from a
  /// simctl-launched app.
  static void _trace(String line) {
    getApplicationDocumentsDirectory()
        .then(
          (d) => File('${d.path}/reader_log.txt').writeAsStringSync(
            '${DateTime.now().toIso8601String()} mic: $line\n',
            mode: FileMode.append,
          ),
        )
        .catchError((_) {});
  }

  /// Loads the model (copying it out of the bundle the first time, since
  /// onnxruntime needs real file paths). Cheap after the first call.
  Future<void> ensureReady() {
    return _loading ??= _load().catchError((Object e) {
      _loading = null; // let the next tap try again
      throw e;
    });
  }

  static Future<void> _load() async {
    final clock = Stopwatch()..start();
    final support = await getApplicationSupportDirectory();
    final dir = Directory('${support.path}/asr');
    await dir.create(recursive: true);
    for (final name in _files) {
      final out = File('${dir.path}/$name');
      if (await out.exists()) continue;
      final data = await rootBundle.load('$_assetDir/$name');
      // Written aside and renamed, so an interrupted copy is never mistaken
      // for a complete model on the next launch.
      final part = File('${out.path}.part');
      await part.writeAsBytes(
        data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes),
        flush: true,
      );
      await part.rename(out.path);
    }
    sherpa.initBindings();
    String path(String name) => '${dir.path}/$name';
    _recognizer = sherpa.OnlineRecognizer(
      sherpa.OnlineRecognizerConfig(
        model: sherpa.OnlineModelConfig(
          transducer: sherpa.OnlineTransducerModelConfig(
            encoder: path('encoder.int8.onnx'),
            decoder: path('decoder.onnx'),
            joiner: path('joiner.int8.onnx'),
          ),
          tokens: path('tokens.txt'),
          numThreads: 2,
          debug: false,
        ),
      ),
    );
    _trace('model ready in ${clock.elapsedMilliseconds}ms');
  }

  /// Starts listening; [onPartial] receives the whole text so far each time
  /// it grows. Returns null once listening, or why it could not start — a
  /// mic that silently does nothing reads as a broken button.
  Future<String?> start(void Function(String) onPartial) async {
    _trace('start');
    try {
      if (!await _recorder.hasPermission()) {
        _trace('no permission');
        return 'Microphone access is off — allow it in Settings.';
      }
      await ensureReady();
      _stream?.free();
      _stream = _recognizer!.createStream();
      _committed = '';
      _onPartial = onPartial;
      final audio = await _recorder.startStream(
        const RecordConfig(
          encoder: AudioEncoder.pcm16bits,
          sampleRate: _sampleRate,
          numChannels: 1,
        ),
      );
      _mic = audio.listen(_feed);
      _trace('listening');
      return null;
    } catch (e) {
      _trace('start failed: $e');
      await _recorder.cancel().catchError((_) {});
      return 'The microphone could not start: $e';
    }
  }

  void _feed(Uint8List chunk) {
    final recognizer = _recognizer;
    final stream = _stream;
    if (recognizer == null || stream == null) return;
    stream.acceptWaveform(
      samples: pcm16ToFloat32(chunk),
      sampleRate: _sampleRate,
    );
    while (recognizer.isReady(stream)) {
      recognizer.decode(stream);
    }
    final text = recognizer.getResult(stream).text;
    if (recognizer.isEndpoint(stream)) {
      _committed = joinUtterances(_committed, text);
      recognizer.reset(stream);
      _onPartial?.call(_committed);
    } else {
      _onPartial?.call(joinUtterances(_committed, text));
    }
  }

  /// Stop recording and return the final text ('' when nothing usable).
  Future<String> stop() async {
    final recognizer = _recognizer;
    final stream = _stream;
    _stream = null;
    try {
      await _recorder.stop();
      await _mic?.cancel();
      _mic = null;
      if (recognizer == null || stream == null) return '';
      // A little silence flushes the last word out of the 480 ms window.
      stream.acceptWaveform(
        samples: Float32List((_sampleRate * 0.66).round()),
        sampleRate: _sampleRate,
      );
      stream.inputFinished();
      while (recognizer.isReady(stream)) {
        recognizer.decode(stream);
      }
      final text = joinUtterances(
        _committed,
        recognizer.getResult(stream).text,
      ).trim();
      _trace('heard ${text.length} chars');
      return text;
    } catch (e) {
      _trace('stop failed: $e');
      return '';
    } finally {
      stream?.free();
      _onPartial = null;
    }
  }

  Future<void> cancel() async {
    await _recorder.cancel();
    await _mic?.cancel();
    _mic = null;
    _stream?.free();
    _stream = null;
  }

  void dispose() {
    _mic?.cancel();
    _stream?.free();
    _stream = null;
    _recorder.dispose();
  }

  /// Little-endian PCM16 bytes as float samples in [-1, 1]. Read through
  /// ByteData: a chunk can start at an odd offset in its buffer, where an
  /// Int16List view throws.
  static Float32List pcm16ToFloat32(Uint8List bytes) {
    final data = ByteData.sublistView(bytes);
    final out = Float32List(bytes.lengthInBytes ~/ 2);
    for (var i = 0; i < out.length; i++) {
      out[i] = data.getInt16(i * 2, Endian.little) / 32768;
    }
    return out;
  }

  /// Utterances closed by a pause, joined into one line of text.
  static String joinUtterances(String committed, String next) {
    final a = committed.trim();
    final b = next.trim();
    if (a.isEmpty) return b;
    if (b.isEmpty) return a;
    return '$a $b';
  }
}
