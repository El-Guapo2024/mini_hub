import 'package:flutter_test/flutter_test.dart';
import 'package:mini_hub/ui/screens/reader_screen.dart';

/// The sentence is the prepared unit — what gets spoken and what a card
/// carries. It must stop at Chinese full-stop punctuation on both sides.
void main() {
  const text = '他们回答我说。一顶帽子有什么可怕的？我的画画的不是帽子。';

  test('middle sentence is cut at 。 and ？', () {
    // Tap on 帽 inside the middle sentence.
    final s = ReaderScreen.sentenceAround(text, 9);
    expect(s, '一顶帽子有什么可怕的？');
  });

  test('first sentence has no left boundary', () {
    expect(ReaderScreen.sentenceAround(text, 2), '他们回答我说。');
  });

  test('text without enders returns the whole node, trimmed', () {
    expect(ReaderScreen.sentenceAround('  只有四个字  ', 4), '只有四个字');
  });
}
