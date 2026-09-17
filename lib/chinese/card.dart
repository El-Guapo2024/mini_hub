/// A word met in a sentence — the thing a generic HSK deck can't carry.
///
/// Only ever on its way somewhere: the reader builds one from the
/// dictionary and the sentence around the word, and it goes straight to the
/// user's Anki collection. The phone keeps no cards of its own, so there is
/// nothing here to store or read back.
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
}
