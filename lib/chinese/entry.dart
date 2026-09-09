/// One CC-CEDICT entry: a surface form, its pronunciation, its meanings.
class DictEntry {
  const DictEntry({
    required this.simplified,
    required this.traditional,
    required this.pinyin,
    required this.glosses,
  });

  final String simplified;
  final String traditional;

  /// Accented ("zhōng guó"), converted once at parse time from CEDICT's
  /// numbered form, because every place that shows pinyin wants it readable.
  final String pinyin;

  final List<String> glosses;
}
