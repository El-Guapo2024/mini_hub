import 'package:flutter/material.dart';

/// A screen with nothing to show yet, or nothing to show at all.
///
/// Three screens each wrote their own centred grey text, and each had drifted
/// — one styled differently, one worded its failure as though it were an empty
/// result. Loading and failure look the same everywhere because they are the
/// same thing everywhere.
class ScreenMessage extends StatelessWidget {
  const ScreenMessage(this.text, {super.key});

  /// What went wrong, said plainly. An error left to speak for itself reads as
  /// "there is nothing here" rather than "this is broken".
  const ScreenMessage.failure(Object error, {super.key})
    : text = 'could not load: $error';

  final String text;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: const TextStyle(color: Colors.white54),
      ),
    ),
  );
}

class ScreenLoading extends StatelessWidget {
  const ScreenLoading({super.key});

  @override
  Widget build(BuildContext context) =>
      const Center(child: CircularProgressIndicator());
}
