import 'package:flutter_test/flutter_test.dart';
import 'package:mini_hub/chinese/dictionary.dart';
import 'package:mini_hub/config.dart';

/// The shipped CC-CEDICT must actually parse — the file is CRLF, which once
/// silently reduced 124k entries to 2 and made every tap in the reader a
/// no-op. Loads the real asset, so a bad file or path fails here, not on
/// the phone.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('the shipped dictionary parses whole and resolves words', () async {
    // Route the real asset file through the test bundle.
    final dictionary = await Dictionary.load(ChineseConfig.cedictAsset);

    expect(
      dictionary.wordCount,
      greaterThan(100000),
      reason: 'CEDICT should carry ~120k surface forms',
    );

    // Longest match wins: tapping 走 in 走进 finds the compound.
    final match = dictionary.matchAt('他走进了房间', 1);
    expect(match, isNotNull);
    expect(match!.word, '走进');

    // Pinyin arrives accented, not numbered.
    final zhongguo = dictionary.matchAt('中国', 0);
    expect(zhongguo!.entries.first.pinyin, 'Zhōng guó');

    // Traditional forms resolve too.
    expect(dictionary.matchAt('中國', 0), isNotNull);
  });
}
