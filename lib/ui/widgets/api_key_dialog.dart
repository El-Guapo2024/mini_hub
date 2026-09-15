import 'package:flutter/material.dart';

import '../../chinese/claude.dart';
import '../../config.dart';

/// Where a reader puts their own Anthropic API key. The companion runs on
/// it; nothing about the key leaves the Keychain except the calls it signs.
Future<void> showApiKeyDialog(BuildContext context) async {
  final existing = await ApiKeyStore.read();
  final model = await ApiKeyStore.readModel();
  if (!context.mounted) return;

  final saved = await showDialog<bool>(
    context: context,
    builder: (_) => _ApiKeyDialog(existing: existing, model: model),
  );

  if (saved != null && context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(saved ? 'Key saved.' : 'Key removed.')),
    );
  }
}

/// A widget of its own so the text field's controller is disposed with the
/// dialog. Disposed by the caller as soon as showDialog returned, it was
/// torn down while the closing animation still depended on it — a red
/// `_dependents.isEmpty` screen on Save.
class _ApiKeyDialog extends StatefulWidget {
  const _ApiKeyDialog({required this.existing, required this.model});

  final String? existing;
  final CompanionModel model;

  @override
  State<_ApiKeyDialog> createState() => _ApiKeyDialogState();
}

class _ApiKeyDialogState extends State<_ApiKeyDialog> {
  final TextEditingController _field = TextEditingController();
  late CompanionModel _model = widget.model;

  @override
  void dispose() {
    _field.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_field.text.trim().isEmpty) return;
    await ApiKeyStore.write(_field.text);
    if (mounted) Navigator.of(context).pop(true);
  }

  Future<void> _remove() async {
    await ApiKeyStore.delete();
    if (mounted) Navigator.of(context).pop(false);
  }

  @override
  Widget build(BuildContext context) {
    final existing = widget.existing;
    return AlertDialog(
      title: const Text('Anthropic API key'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            existing == null
                ? 'The companion runs on your own key, from '
                      'console.anthropic.com. It stays in this phone\'s '
                      'Keychain.'
                : 'A key ending in ${existing.substring(existing.length - 4)} '
                      'is saved. Paste a new one to replace it.',
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _field,
            obscureText: true,
            autocorrect: false,
            enableSuggestions: false,
            decoration: const InputDecoration(hintText: 'sk-ant-…'),
            onSubmitted: (_) => _save(),
          ),
          const SizedBox(height: 20),
          const Text('Model'),
          const SizedBox(height: 8),
          // Applies at once, key or no key: it is a cost choice, not part
          // of the key.
          SegmentedButton<CompanionModel>(
            showSelectedIcon: false,
            segments: [
              for (final m in CompanionModel.values)
                ButtonSegment(value: m, label: Text(m.label)),
            ],
            selected: {_model},
            onSelectionChanged: (s) {
              setState(() => _model = s.single);
              ApiKeyStore.writeModel(s.single);
            },
          ),
          const SizedBox(height: 6),
          Text(_model.blurb, style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
      actions: [
        if (existing != null)
          TextButton(onPressed: _remove, child: const Text('Remove')),
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(onPressed: _save, child: const Text('Save')),
      ],
    );
  }
}
