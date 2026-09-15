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

  /// Punctuation is not a word, and must not be treated as a failed lookup.
  /// A tap on 。 finding nothing is correct; a tap on a character the
  /// dictionary does not carry is a miss worth saying out loud. Telling
  /// those apart is the whole job of isHan.
  test('han characters are told apart from the punctuation between them', () {
    expect(ReaderScreen.isHan('走'), isTrue);
    expect(ReaderScreen.isHan('了'), isTrue);
    expect(ReaderScreen.isHan('。'), isFalse);
    expect(ReaderScreen.isHan('，'), isFalse);
    expect(ReaderScreen.isHan('“'), isFalse);
    expect(ReaderScreen.isHan(' '), isFalse);
    expect(ReaderScreen.isHan(''), isFalse);
    expect(ReaderScreen.isHan('a'), isFalse);
  });
}
