import 'package:flutter_test/flutter_test.dart';
import 'package:mini_hub/chinese/speech.dart';

/// Read-aloud goes sentence by sentence, so the split is what the progress
/// bar counts and where a paused read resumes.
void main() {
  test('splits at sentence enders and keeps the punctuation', () {
    expect(Speech.sentencesOf('今天早上，我很早就起床了。你知道为什么吗？我也不知道！'), [
      '今天早上，我很早就起床了。',
      '你知道为什么吗？',
      '我也不知道！',
    ]);
  });

  test('a closing quote stays with its sentence', () {
    expect(Speech.sentencesOf('他说：“我有一件事想告诉你。”原来他要去北京。'), [
      '他说：“我有一件事想告诉你。”',
      '原来他要去北京。',
    ]);
  });

  test('speech resumed mid-sentence runs to that sentence\'s end', () {
    const page = '今天早上，我很早就起床了。你知道为什么吗？';
    // From the start, from mid-sentence, and from the second sentence.
    expect(Speech.sentenceEndAfter(page, 0), 13);
    expect(Speech.sentenceEndAfter(page, 5), 13);
    expect(Speech.sentenceEndAfter(page, 13), page.length);
    expect(Speech.sentenceEndAfter(page, page.length), page.length);
  });

  test('a mixed answer is spoken in two voices, switching at each script', () {
    expect(Speech.languageRuns('Here, 了 marks a change: 他不来了。 Got it?'), [
      ('Here,', 'en-US'),
      ('了', 'zh-CN'),
      ('marks a change:', 'en-US'),
      ('他不来了。', 'zh-CN'),
      ('Got it?', 'en-US'),
    ]);
    expect(Speech.languageRuns('Only English.'), [('Only English.', 'en-US')]);
    expect(Speech.languageRuns('只有中文。'), [('只有中文。', 'zh-CN')]);
  });

  test('headings and blank lines are their own pieces, empties dropped', () {
    expect(Speech.sentencesOf('第一章 早上\n\n  外面下着小雨。'), ['第一章 早上', '外面下着小雨。']);
  });
}
