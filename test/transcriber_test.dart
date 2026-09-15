import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:mini_hub/chinese/transcriber.dart';

/// The mic's bytes reach the recognizer through these two helpers, so a
/// mistake here is a silent transcript rather than an error anyone sees.
void main() {
  test('PCM16 converts to float samples, little-endian', () {
    final bytes = Uint8List.fromList([0x00, 0x00, 0xff, 0x7f, 0x00, 0x80]);
    final samples = Transcriber.pcm16ToFloat32(bytes);
    expect(samples.length, 3);
    expect(samples[0], 0.0);
    expect(samples[1], closeTo(1.0, 1e-4));
    expect(samples[2], -1.0);
  });

  test('a chunk starting at an odd offset in its buffer does not throw', () {
    // The failure that silenced the mic: an Int16List view at offset 5.
    final buffer = Uint8List(11);
    buffer[5] = 0xff;
    buffer[6] = 0x7f;
    final chunk = Uint8List.sublistView(buffer, 5, 11);
    final samples = Transcriber.pcm16ToFloat32(chunk);
    expect(samples.length, 3);
    expect(samples[0], closeTo(1.0, 1e-4));
  });

  test('utterances closed by a pause join into one line', () {
    expect(Transcriber.joinUtterances('', '这是第一种'), '这是第一种');
    expect(Transcriber.joinUtterances('这是第一种，', ''), '这是第一种，');
    expect(
      Transcriber.joinUtterances('what does', '了 mean'),
      'what does 了 mean',
    );
  });
}
