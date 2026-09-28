import 'package:flutter_test/flutter_test.dart';
import 'package:mini_hub/chinese/dictionary.dart';
import 'package:mini_hub/config.dart';
import 'package:mini_hub/ui/widgets/pinyin_text.dart';

/// A tap answers with the word it fell in, read the way its clause divides.
///
/// A pop-up dictionary such as Zhongwen takes the longest entry starting at
/// the finger and never looks behind it: a tap on the 究 of 研究 gets 究, a
/// tap on the 小 of 从小学习 gets 小学 ("primary school"). These pin the
/// cases where reading the clause first gets it right instead.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('on a handful of entries', () {
    final dictionary = Dictionary.parse(
      [
        '研究 研究 [yan2 jiu1] /research/',
        '研究生 研究生 [yan2 jiu1 sheng1] /graduate student/',
        '生命 生命 [sheng1 ming4] /life/',
        '起源 起源 [qi3 yuan2] /origin/',
        '研 研 [yan2] /to grind/',
        '究 究 [jiu1] /to investigate/',
        '生 生 [sheng1] /to be born/',
        '命 命 [ming4] /life; fate/',
      ].join('\n'),
    );

    test('the division with fewest single characters wins', () {
      // 研究/生命/起源, not 研究生/命/起源.
      for (final (at, word) in [(0, '研究'), (1, '研究'), (2, '生命'), (3, '生命')]) {
        expect(dictionary.wordAt('研究生命起源', at)?.word, word, reason: '$at');
      }
    });

    test('where the word starts comes back with it', () {
      final found = dictionary.wordAt('他研究生命', 4)!;
      expect(found.word, '生命');
      expect(found.start, 3);
    });

    test('punctuation, and a character with no entry, find nothing', () {
      expect(dictionary.wordAt('研究。', 2), isNull);
      expect(dictionary.wordAt('研究他', 2), isNull);
    });

    test('a clause ends at punctuation', () {
      // Without the comma, 研究生 would be a word here.
      expect(dictionary.wordAt('研究，生', 3)?.word, '生');
    });

    test('everything the character belongs to, longest first', () {
      expect(dictionary.wordsCovering('研究生命起源', 2).map((w) => w.word), [
        '研究生',
        '生命',
        '生',
      ]);
    });
  });

  group('on the shipped CC-CEDICT', () {
    late Dictionary dictionary;
    setUpAll(() async {
      dictionary = await Dictionary.load(ChineseConfig.cedictAsset);
    });

    String? tap(String text, String char) =>
        dictionary.wordAt(text, text.indexOf(char))?.word;

    test(
      'reads the clause, where looking forward from the tap misreads it',
      () {
        expect(tap('他从小学习中文', '小'), '从小');
        expect(tap('他从小学习中文', '学'), '学习');
        expect(tap('研究生命起源', '究'), '研究');
        expect(tap('研究生命起源', '命'), '生命');
        expect(tap('他们回答我说', '答'), '回答');
        expect(tap('中华人民共和国成立了', '和'), '中华人民共和国');
      },
    );

    test('and agrees with it where it was already right', () {
      expect(tap('他走进了房间', '走'), '走进');
      expect(tap('这个问题很难', '问'), '问题');
      expect(tap('一顶帽子有什么可怕的？', '帽'), '帽子');
    });

    test('the other readings stay on offer', () {
      final also = dictionary.wordsCovering('他从小学习中文', 3).map((w) => w.word);
      expect(also, containsAll(['小学', '学习', '学']));
    });
  });

  group('PinyinText.toneOf', () {
    test('reads the tone from the mark, and neutral from none', () {
      expect(PinyinText.toneOf('zhōng'), 1);
      expect(PinyinText.toneOf('guó'), 2);
      expect(PinyinText.toneOf('Běi'), 3);
      expect(PinyinText.toneOf('jìn'), 4);
      expect(PinyinText.toneOf('lǜ'), 4);
      expect(PinyinText.toneOf('nǚ'), 3);
      expect(PinyinText.toneOf('le'), 5);
      expect(PinyinText.toneOf('r'), 5);
    });
  });
}
