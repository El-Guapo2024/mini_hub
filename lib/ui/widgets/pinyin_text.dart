import 'package:flutter/material.dart';

/// Pinyin coloured by tone, one colour per syllable.
///
/// The tone is the part of a syllable a learner most often misremembers, and
/// a colour reads at a glance where a diacritic takes a squint. The hues are
/// Zhongwen's defaults — red, orange, green, blue, grey for tones one to five
/// — so a reader coming from it sees what they are used to; on a light
/// sheet they are darkened enough to read on white.
///
/// Syllables are space-separated, as CC-CEDICT writes them. Pinyin that runs
/// syllables together ("jìnlai") cannot be split reliably, so it is not
/// given here: show it as plain text.
class PinyinText extends StatelessWidget {
  const PinyinText(this.pinyin, {super.key, this.style});

  final String pinyin;
  final TextStyle? style;

  static const _marked = [
    'āēīōūǖĀĒĪŌŪǕ',
    'áéíóúǘÁÉÍÓÚǗńḿ',
    'ǎěǐǒǔǚǍĚǏǑǓǙň',
    'àèìòùǜÀÈÌÒÙǛǹ',
  ];

  /// 1 to 4 by the syllable's tone mark, and 5 — the neutral tone — for a
  /// syllable with none.
  static int toneOf(String syllable) {
    for (final char in syllable.split('')) {
      for (var tone = 0; tone < _marked.length; tone++) {
        if (_marked[tone].contains(char)) return tone + 1;
      }
    }
    return 5;
  }

  static const _light = [
    Color(0xFFC62828),
    Color(0xFFD84315),
    Color(0xFF2E7D32),
    Color(0xFF1565C0),
  ];
  static const _dark = [
    Color(0xFFEE363E),
    Color(0xFFF47C36),
    Color(0xFF73BB4F),
    Color(0xFF649CD3),
  ];

  static Color colorOf(int tone, ThemeData theme) {
    if (tone < 1 || tone > 4) return theme.colorScheme.onSurfaceVariant;
    final dark = theme.brightness == Brightness.dark;
    return (dark ? _dark : _light)[tone - 1];
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final syllables = pinyin.split(' ');
    return Text.rich(
      TextSpan(
        style: style,
        children: [
          for (var i = 0; i < syllables.length; i++)
            TextSpan(
              text: i == 0 ? syllables[i] : ' ${syllables[i]}',
              style: TextStyle(color: colorOf(toneOf(syllables[i]), theme)),
            ),
        ],
      ),
    );
  }
}
