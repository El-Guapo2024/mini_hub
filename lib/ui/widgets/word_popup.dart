import 'package:flutter/material.dart';

import '../../chinese/entry.dart';
import '../../chinese/phrase.dart';
import 'new_deck_dialog.dart';
import 'pinyin_text.dart';

/// The tap-a-word sheet: hanzi, pinyin, glosses, and the actions — hear the
/// word, hear its sentence, have the sentence explained, keep it as a card. A
/// Flutter overlay above the WebView, never HTML inside it.
///
/// The glosses answer "what is this word"; `onExplain` is the other half, and
/// the reason the sentence is on this sheet at all. A word looked up in
/// isolation is the failure mode the module exists to avoid.
///
/// [also] is the other words the tapped character belongs to, as a pop-up
/// dictionary lists them. Tapping one makes it the sheet's word, for when
/// the reader's division of the sentence guessed wrong, and [onWordChanged]
/// says which, so speaking and the card follow it.
///
/// [inContext] is the other answer to a drag-selection: what the run means
/// in this sentence, from the companion, above the dictionary's per-word
/// senses. Null for a single tap, and whenever no Claude key is saved.
///
/// With Anki connected, [deck] is where the card will go and [loadDecks]
/// lists the others: the deck chip changes it for this card (and, through
/// the save, for the next).
Future<void> showWordPopup({
  required BuildContext context,
  required String word,
  required List<DictEntry> entries,
  String? pinyin,
  required String sentence,
  required VoidCallback onSpeakWord,
  required VoidCallback onSpeakSentence,
  required Future<void> Function(String? deck) onAddCard,
  Future<void> Function()? onExplain,
  List<({String word, List<DictEntry> entries})> also = const [],
  ValueChanged<String>? onWordChanged,
  Future<PhraseReading>? inContext,
  String? deck,
  Future<List<String>> Function()? loadDecks,
}) {
  var chosen = deck;
  var head = (word: word, entries: entries);
  var headPinyin = pinyin ?? entries.first.pinyin;
  final others = [...also];
  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    builder: (sheetContext) {
      final theme = Theme.of(sheetContext);
      return StatefulBuilder(
        builder: (sheetContext, setSheet) => SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _Headword(
                  word: head.word,
                  pinyin: headPinyin,
                  onSpeak: onSpeakWord,
                ),
                const SizedBox(height: 8),
                Flexible(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Scrolls with the senses rather than sitting above
                        // them: a sheet is at most about half the screen, and
                        // fixed there a long note pushed the actions off it.
                        if (inContext != null) ...[
                          _InContext(reading: inContext),
                          const SizedBox(height: 8),
                        ],
                        for (final entry in head.entries) ...[
                          if (head.entries.length > 1)
                            Padding(
                              padding: const EdgeInsets.only(top: 6),
                              child: PinyinText(
                                entry.pinyin,
                                style: theme.textTheme.labelMedium,
                              ),
                            ),
                          for (final gloss in entry.glosses)
                            Text('• $gloss', style: theme.textTheme.bodyMedium),
                        ],
                        if (others.isNotEmpty) ...[
                          const SizedBox(height: 12),
                          Text(
                            'Also here',
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                          for (var i = 0; i < others.length; i++)
                            _Alternative(
                              word: others[i].word,
                              entries: others[i].entries,
                              // The word taken and the one it replaces trade
                              // places, so a wrong pick is one tap to undo.
                              onTap: () {
                                final picked = others[i];
                                setSheet(() {
                                  others[i] = head;
                                  head = picked;
                                  headPinyin = picked.entries.first.pinyin;
                                });
                                onWordChanged?.call(picked.word);
                              },
                            ),
                        ],
                      ],
                    ),
                  ),
                ),
                const Divider(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        sentence,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.campaign),
                      tooltip: 'Speak sentence',
                      onPressed: onSpeakSentence,
                    ),
                    if (onExplain != null)
                      IconButton(
                        icon: const Icon(Icons.auto_awesome),
                        tooltip: 'Explain this sentence',
                        // The word sheet closes first: two stacked sheets over
                        // the page hide the sentence they are both about.
                        onPressed: () {
                          Navigator.of(sheetContext).pop();
                          onExplain();
                        },
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    // Shown even before a deck is chosen: this chip is the
                    // only way into the deck list from here, so hiding it
                    // left an account that had chosen none with no way to
                    // choose one.
                    if (loadDecks != null)
                      Flexible(
                        child: ActionChip(
                          avatar: const Icon(Icons.layers_outlined, size: 18),
                          label: Text(
                            chosen ?? 'Choose deck',
                            overflow: TextOverflow.ellipsis,
                          ),
                          tooltip: 'Choose deck',
                          onPressed: () async {
                            final picked = await _pickDeck(
                              sheetContext,
                              current: chosen,
                              loadDecks: loadDecks,
                            );
                            if (picked != null) setSheet(() => chosen = picked);
                          },
                        ),
                      )
                    else
                      const Spacer(),
                    const SizedBox(width: 8),
                    FilledButton.icon(
                      icon: const Icon(Icons.style, size: 18),
                      label: const Text('Card'),
                      onPressed: () async {
                        await onAddCard(chosen);
                        if (sheetContext.mounted) {
                          Navigator.of(sheetContext).pop();
                        }
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      );
    },
  );
}

/// One of the other words the tapped character is part of: the word, its
/// pinyin and its first sense, a line each, and tappable.
class _Alternative extends StatelessWidget {
  const _Alternative({
    required this.word,
    required this.entries,
    required this.onTap,
  });

  final String word;
  final List<DictEntry> entries;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final first = entries.first;
    return InkWell(
      onTap: onTap,
      child: ConstrainedBox(
        // A tap target, not a line of small print.
        constraints: const BoxConstraints(minHeight: 48),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            children: [
              Text(word, style: theme.textTheme.titleMedium),
              const SizedBox(width: 10),
              PinyinText(first.pinyin, style: theme.textTheme.bodyMedium),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  first.glosses.first,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The word or run, its pinyin, and the button that says it. A run longer
/// than a word would push its pinyin off the sheet beside it at display
/// size, so it is set smaller with the pinyin underneath.
class _Headword extends StatelessWidget {
  const _Headword({
    required this.word,
    required this.pinyin,
    required this.onSpeak,
  });

  final String word;
  final String pinyin;
  final VoidCallback onSpeak;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final long = word.characters.length > 4;
    final reading = PinyinText(pinyin, style: theme.textTheme.titleMedium);
    final speak = IconButton(
      icon: const Icon(Icons.volume_up),
      tooltip: 'Speak word',
      onPressed: onSpeak,
    );
    if (long) {
      return Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(word, style: theme.textTheme.headlineSmall),
                if (pinyin.isNotEmpty) reading,
              ],
            ),
          ),
          speak,
        ],
      );
    }
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(word, style: theme.textTheme.displaySmall),
        const SizedBox(width: 16),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: reading,
          ),
        ),
        speak,
      ],
    );
  }
}

/// What the selection means in its sentence: one sense, the one it has
/// here, where the dictionary below can only list the ones it might have.
class _InContext extends StatelessWidget {
  const _InContext({required this.reading});

  final Future<PhraseReading> reading;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final ink = cs.onSecondaryContainer;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 10),
      decoration: BoxDecoration(
        color: cs.secondaryContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: FutureBuilder<PhraseReading>(
        future: reading,
        builder: (context, snap) {
          final label = Text(
            'In this sentence',
            style: theme.textTheme.labelSmall?.copyWith(color: ink),
          );
          if (snap.hasError) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                label,
                Text(
                  '${snap.error}',
                  style: theme.textTheme.bodySmall?.copyWith(color: ink),
                ),
              ],
            );
          }
          final read = snap.data;
          if (read == null) {
            return Row(
              children: [
                SizedBox.square(
                  dimension: 14,
                  child: CircularProgressIndicator(strokeWidth: 2, color: ink),
                ),
                const SizedBox(width: 10),
                Text(
                  'Reading it in this sentence…',
                  style: theme.textTheme.bodySmall?.copyWith(color: ink),
                ),
              ],
            );
          }
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              label,
              Text(
                read.translation,
                style: theme.textTheme.titleMedium?.copyWith(color: ink),
              ),
              if (read.pinyin.isNotEmpty)
                Text(
                  read.pinyin,
                  style: theme.textTheme.bodySmall?.copyWith(color: ink),
                ),
              if (read.note.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    read.note,
                    style: theme.textTheme.bodySmall?.copyWith(color: ink),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

/// Every deck in the connected collection, the current one ticked. Returns
/// the one tapped, or null when dismissed.
Future<String?> _pickDeck(
  BuildContext context, {
  required String? current,
  required Future<List<String>> Function() loadDecks,
}) {
  final decks = loadDecks();
  return showDialog<String>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: const Text('Add to deck'),
      contentPadding: const EdgeInsets.symmetric(vertical: 12),
      content: SizedBox(
        width: double.maxFinite,
        child: FutureBuilder<List<String>>(
          future: decks,
          builder: (_, snap) {
            if (snap.hasError) {
              return Padding(
                padding: const EdgeInsets.all(24),
                child: Text('Could not read your decks: ${snap.error}'),
              );
            }
            final names = snap.data;
            if (names == null) {
              return const Padding(
                padding: EdgeInsets.all(24),
                child: Center(child: CircularProgressIndicator()),
              );
            }
            return ListView(
              shrinkWrap: true,
              children: [
                for (final name in names)
                  ListTile(
                    title: Text(name),
                    trailing: name == current ? const Icon(Icons.check) : null,
                    onTap: () => Navigator.of(dialogContext).pop(name),
                  ),
                // Anki makes the deck when the first card lands in it, so
                // naming one here creates nothing until a card is saved.
                ListTile(
                  leading: const Icon(Icons.add),
                  title: const Text('New deck…'),
                  onTap: () async {
                    final made = await askNewDeckName(dialogContext);
                    if (made != null && dialogContext.mounted) {
                      Navigator.of(dialogContext).pop(made);
                    }
                  },
                ),
              ],
            );
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(),
          child: const Text('Cancel'),
        ),
      ],
    ),
  );
}
