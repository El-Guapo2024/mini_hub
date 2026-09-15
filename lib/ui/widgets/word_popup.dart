import 'package:flutter/material.dart';

import '../../chinese/entry.dart';

/// The tap-a-word sheet: hanzi, pinyin, glosses, and the actions — hear the
/// word, hear its sentence, have the sentence explained, keep it as a card. A
/// Flutter overlay above the WebView, never HTML inside it.
///
/// The glosses answer "what is this word"; `onExplain` is the other half, and
/// the reason the sentence is on this sheet at all. A word looked up in
/// isolation is the failure mode the module exists to avoid.
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
  String? deck,
  Future<List<String>> Function()? loadDecks,
}) {
  var chosen = deck;
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
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(word, style: theme.textTheme.displaySmall),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Text(
                          pinyin ?? entries.first.pinyin,
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: theme.colorScheme.primary,
                          ),
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.volume_up),
                      tooltip: 'Speak word',
                      onPressed: onSpeakWord,
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Flexible(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        for (final entry in entries) ...[
                          if (entries.length > 1)
                            Padding(
                              padding: const EdgeInsets.only(top: 6),
                              child: Text(
                                entry.pinyin,
                                style: theme.textTheme.labelMedium?.copyWith(
                                  color: theme.colorScheme.secondary,
                                ),
                              ),
                            ),
                          for (final gloss in entry.glosses)
                            Text('• $gloss', style: theme.textTheme.bodyMedium),
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
                    if (chosen != null && loadDecks != null)
                      Flexible(
                        child: ActionChip(
                          avatar: const Icon(Icons.layers_outlined, size: 18),
                          label: Text(chosen!, overflow: TextOverflow.ellipsis),
                          tooltip: 'Choose deck',
                          onPressed: () async {
                            final picked = await _pickDeck(
                              sheetContext,
                              current: chosen!,
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

/// Every deck in the connected collection, the current one ticked. Returns
/// the one tapped, or null when dismissed.
Future<String?> _pickDeck(
  BuildContext context, {
  required String current,
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
