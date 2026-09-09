import 'package:flutter/material.dart';

import '../../chinese/entry.dart';

/// The tap-a-word sheet: hanzi, pinyin, glosses, and the actions — hear the
/// word, hear its sentence, have the sentence explained, keep it as a card. A
/// Flutter overlay above the WebView, never HTML inside it.
///
/// The glosses answer "what is this word"; `onExplain` is the other half, and
/// the reason the sentence is on this sheet at all. A word looked up in
/// isolation is the failure mode the module exists to avoid.
Future<void> showWordPopup({
  required BuildContext context,
  required String word,
  required List<DictEntry> entries,
  String? pinyin,
  required String sentence,
  required VoidCallback onSpeakWord,
  required VoidCallback onSpeakSentence,
  required Future<void> Function() onAddCard,
  Future<void> Function()? onExplain,
}) {
  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    builder: (sheetContext) {
      final theme = Theme.of(sheetContext);
      return SafeArea(
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
                  FilledButton.icon(
                    icon: const Icon(Icons.style, size: 18),
                    label: const Text('Card'),
                    onPressed: () async {
                      await onAddCard();
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
      );
    },
  );
}
