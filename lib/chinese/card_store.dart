import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

/// A word met in a sentence — the thing a generic HSK deck can't carry.
class Card {
  const Card({
    required this.word,
    required this.pinyin,
    required this.gloss,
    required this.sentence,
  });

  final String word;
  final String pinyin;
  final String gloss;
  final String sentence;

  Map<String, String> toJson() => {
    'word': word,
    'pinyin': pinyin,
    'gloss': gloss,
    'sentence': sentence,
  };

  factory Card.fromJson(Map<String, dynamic> j) => Card(
    word: j['word'] as String,
    pinyin: j['pinyin'] as String,
    gloss: j['gloss'] as String,
    sentence: j['sentence'] as String,
  );
}

/// Append-only, one JSON line per card — the AttemptStore discipline. Review
/// is Anki's job, so this store only ever grows and exports; nothing here
/// schedules anything.
class CardStore {
  CardStore._(this._file);

  final File _file;

  static Future<CardStore> open() async {
    final docs = await getApplicationDocumentsDirectory();
    return CardStore._(File('${docs.path}/chinese_cards.jsonl'));
  }

  Future<void> add(Card card) => _file.writeAsString(
    '${jsonEncode(card.toJson())}\n',
    mode: FileMode.append,
  );

  Future<List<Card>> all() async {
    if (!await _file.exists()) return [];
    final cards = <Card>[];
    for (final line in await _file.readAsLines()) {
      if (line.isEmpty) continue;
      try {
        cards.add(Card.fromJson(jsonDecode(line) as Map<String, dynamic>));
      } on FormatException {
        // A bad row is skipped, not fatal — same rule as the attempt log.
      }
    }
    return cards;
  }

  /// Anki's plainest import format: tab-separated, one card per line, fields
  /// word / pinyin / gloss / sentence. Tabs and newlines inside a field would
  /// break the row, so they are flattened to spaces.
  Future<File> exportTsv() async {
    String clean(String s) => s.replaceAll(RegExp(r'[\t\n\r]+'), ' ');
    final cards = await all();
    final tsv = cards
        .map(
          (c) =>
              '${clean(c.word)}\t${clean(c.pinyin)}\t${clean(c.gloss)}\t${clean(c.sentence)}',
        )
        .join('\n');
    final docs = await getApplicationDocumentsDirectory();
    final out = File('${docs.path}/anki_export.tsv');
    await out.writeAsString(tsv);
    return out;
  }
}
