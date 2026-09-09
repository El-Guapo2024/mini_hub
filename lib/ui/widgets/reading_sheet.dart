import 'package:flutter/material.dart';

import '../../chinese/reading.dart';
import '../../chinese/tutor.dart';

/// The prepared sentence, as a sheet over the page.
///
/// It asks while it is open rather than before, so the gesture that opens it
/// is never held up by a network call. Three states and no more: working,
/// what went wrong, or the reading.
Future<void> showReadingSheet({
  required BuildContext context,
  required String sentence,
  required Future<Reading> Function() prepare,
  required VoidCallback onSpeakSentence,
}) {
  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (sheetContext) => _ReadingSheet(
      sentence: sentence,
      prepare: prepare,
      onSpeakSentence: onSpeakSentence,
    ),
  );
}

class _ReadingSheet extends StatefulWidget {
  const _ReadingSheet({
    required this.sentence,
    required this.prepare,
    required this.onSpeakSentence,
  });

  final String sentence;
  final Future<Reading> Function() prepare;
  final VoidCallback onSpeakSentence;

  @override
  State<_ReadingSheet> createState() => _ReadingSheetState();
}

class _ReadingSheetState extends State<_ReadingSheet> {
  late Future<Reading> _reading;

  @override
  void initState() {
    super.initState();
    _reading = widget.prepare();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.sizeOf(context).height * 0.7,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      widget.sentence,
                      style: theme.textTheme.titleLarge?.copyWith(height: 1.5),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.campaign),
                    tooltip: 'Speak sentence',
                    onPressed: widget.onSpeakSentence,
                  ),
                ],
              ),
              const Divider(height: 24),
              Flexible(
                child: FutureBuilder<Reading>(
                  future: _reading,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState != ConnectionState.done) {
                      return const Padding(
                        padding: EdgeInsets.symmetric(vertical: 24),
                        child: Center(child: CircularProgressIndicator()),
                      );
                    }
                    final error = snapshot.error;
                    if (error != null) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            error is TutorException ? error.message : '$error',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: cs.error,
                            ),
                          ),
                          const SizedBox(height: 12),
                          // A reading that failed on a sleeping server is one
                          // button from working; sending the reader back to
                          // the page to repeat the gesture is not the answer.
                          OutlinedButton.icon(
                            icon: const Icon(Icons.refresh, size: 18),
                            label: const Text('Try again'),
                            // A block body, not an arrow: an arrow returns
                            // the assigned Future, and setState refuses one.
                            onPressed: () {
                              setState(() {
                                _reading = widget.prepare();
                              });
                            },
                          ),
                        ],
                      );
                    }
                    return _ReadingBody(reading: snapshot.data!);
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ReadingBody extends StatelessWidget {
  const _ReadingBody({required this.reading});

  final Reading reading;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          SelectableText(
            reading.translation,
            style: theme.textTheme.bodyLarge?.copyWith(height: 1.4),
          ),
          if (reading.notes.isNotEmpty) ...[
            const SizedBox(height: 20),
            Text(
              'Implied, not written',
              style: theme.textTheme.labelMedium?.copyWith(
                color: cs.secondary,
                letterSpacing: 0.6,
              ),
            ),
            const SizedBox(height: 8),
            for (final note in reading.notes)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (note.about.isNotEmpty)
                      Text(
                        note.about,
                        style: theme.textTheme.titleSmall?.copyWith(
                          color: cs.primary,
                        ),
                      ),
                    Text(
                      note.says,
                      style: theme.textTheme.bodyMedium?.copyWith(height: 1.35),
                    ),
                  ],
                ),
              ),
          ],
        ],
      ),
    );
  }
}
