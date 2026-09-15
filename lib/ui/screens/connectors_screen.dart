import 'package:flutter/material.dart';

import '../../chinese/anki_sync.dart';
import '../../chinese/connections.dart';
import '../../config.dart';

/// Every outside service the reader uses, in one place: Claude API keys for
/// the companion and AnkiWeb accounts for cards. Several of each can be
/// saved under a name; tapping one puts it in use.
class ConnectorsScreen extends StatefulWidget {
  const ConnectorsScreen({
    super.key,
    this.store = const ConnectionStore(),
    this.anki,
  });

  final ConnectionStore store;
  final AnkiSync? anki;

  @override
  State<ConnectorsScreen> createState() => _ConnectorsScreenState();
}

class _ConnectorsScreenState extends State<ConnectorsScreen> {
  late final AnkiSync _anki = widget.anki ?? AnkiSync(store: widget.store);
  List<Connection> _all = const [];
  final Map<ConnectorKind, String?> _active = {};
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final all = await widget.store.all();
    final claude = await widget.store.active(ConnectorKind.claude);
    final anki = await widget.store.active(ConnectorKind.anki);
    if (!mounted) return;
    setState(() {
      _all = all;
      _active[ConnectorKind.claude] = claude?.id;
      _active[ConnectorKind.anki] = anki?.id;
      _loaded = true;
    });
  }

  /// A swipe asks first: removing an Anki account also drops its copy of
  /// the collection on this phone.
  Future<bool> _confirmRemove(Connection c) async =>
      await showDialog<bool>(
        context: context,
        builder: (dialog) => AlertDialog(
          title: Text('Remove ${c.name}?'),
          content: Text(
            c.kind == ConnectorKind.anki
                ? 'Cards already synced stay in AnkiWeb.'
                : 'The key is deleted from this phone.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialog).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialog).pop(true),
              child: const Text('Remove'),
            ),
          ],
        ),
      ) ??
      false;

  Future<void> _remove(Connection c) async {
    // Out of the list at once, so the dismissed row is never rebuilt.
    setState(() => _all = [..._all]..removeWhere((x) => x.id == c.id));
    if (c.kind == ConnectorKind.anki) {
      await _anki.remove(c);
    } else {
      await widget.store.remove(c);
    }
    await _load();
  }

  Future<void> _use(Connection c) async {
    await widget.store.setActive(c);
    await _load();
  }

  Future<void> _open(Widget dialog) async {
    await showDialog<void>(context: context, builder: (_) => dialog);
    await _load();
  }

  /// The one way to add: + asks what kind, then opens that form.
  Future<void> _add() async {
    final kind = await showModalBottomSheet<ConnectorKind>(
      context: context,
      builder: (sheet) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.key),
              title: const Text('Claude API key'),
              subtitle: const Text('For the reading companion'),
              onTap: () => Navigator.of(sheet).pop(ConnectorKind.claude),
            ),
            ListTile(
              leading: const Icon(Icons.style),
              title: const Text('Anki account'),
              subtitle: const Text('For the cards you save'),
              onTap: () => Navigator.of(sheet).pop(ConnectorKind.anki),
            ),
          ],
        ),
      ),
    );
    if (kind == null || !mounted) return;
    await _open(
      kind == ConnectorKind.claude
          ? _ClaudeDialog(store: widget.store)
          : _AnkiLoginDialog(anki: _anki),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Connectors')),
      floatingActionButton: FloatingActionButton(
        onPressed: _add,
        tooltip: 'Add connector',
        child: const Icon(Icons.add),
      ),
      body: !_loaded
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              // Room under the last entry, clear of the + button.
              padding: const EdgeInsets.only(bottom: 96),
              children: [
                _section(
                  kind: ConnectorKind.claude,
                  title: 'Claude API',
                  blurb:
                      'Runs the reading companion. Each key keeps its own '
                      'model.',
                ),
                const Divider(height: 32),
                _section(
                  kind: ConnectorKind.anki,
                  title: 'Anki',
                  blurb:
                      'Cards you save while reading go to the account in '
                      'use, and from AnkiWeb to all your Anki apps.',
                ),
              ],
            ),
    );
  }

  Widget _section({
    required ConnectorKind kind,
    required String title,
    required String blurb,
  }) {
    final theme = Theme.of(context);
    final items = [
      for (final c in _all)
        if (c.kind == kind) c,
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
          child: Text(title, style: theme.textTheme.titleMedium),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(blurb, style: theme.textTheme.bodySmall),
        ),
        for (final c in items)
          Dismissible(
            key: ValueKey(c.id),
            direction: DismissDirection.endToStart,
            background: Container(
              alignment: Alignment.centerRight,
              padding: const EdgeInsets.symmetric(horizontal: 24),
              color: theme.colorScheme.error,
              child: Icon(Icons.delete, color: theme.colorScheme.onError),
            ),
            confirmDismiss: (_) => _confirmRemove(c),
            onDismissed: (_) => _remove(c),
            child: ListTile(
              leading: Icon(
                _active[kind] == c.id
                    ? Icons.radio_button_checked
                    : Icons.radio_button_unchecked,
                color: _active[kind] == c.id ? theme.colorScheme.primary : null,
              ),
              title: Text(c.name),
              subtitle: Text(_subtitle(c)),
              onTap: () => _use(c),
              trailing: IconButton(
                icon: const Icon(Icons.edit_outlined),
                tooltip: 'Edit ${c.name}',
                onPressed: () => _open(
                  kind == ConnectorKind.claude
                      ? _ClaudeDialog(store: widget.store, existing: c)
                      : _AnkiAccountDialog(anki: _anki, account: c),
                ),
              ),
            ),
          ),
        if (items.isEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: Text(
              'None yet — tap + to add one.',
              style: theme.textTheme.bodySmall,
            ),
          ),
      ],
    );
  }

  static String _subtitle(Connection c) => switch (c.kind) {
    ConnectorKind.claude =>
      'Key ${c.hint} · ${(c.model ?? ChineseConfig.defaultModel).label}',
    ConnectorKind.anki => '${c.user ?? ''} · ${c.deck ?? AnkiSync.defaultDeck}',
  };
}

/// Adds a named Claude key, or edits one: rename, pick its model, replace
/// or remove the key. Its own widget so the text controllers are disposed
/// with the dialog, not while its closing animation still uses them.
class _ClaudeDialog extends StatefulWidget {
  const _ClaudeDialog({required this.store, this.existing});

  final ConnectionStore store;
  final Connection? existing;

  @override
  State<_ClaudeDialog> createState() => _ClaudeDialogState();
}

class _ClaudeDialogState extends State<_ClaudeDialog> {
  late final TextEditingController _name = TextEditingController(
    text: widget.existing?.name ?? '',
  );
  final TextEditingController _key = TextEditingController();
  late CompanionModel _model =
      widget.existing?.model ?? ChineseConfig.defaultModel;
  String? _error;

  @override
  void dispose() {
    _name.dispose();
    _key.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final existing = widget.existing;
    final key = _key.text.trim();
    if (existing == null && key.isEmpty) {
      setState(() => _error = 'Paste an API key from console.anthropic.com.');
      return;
    }
    final name = _name.text.trim();
    await widget.store.save(
      Connection(
        id: existing?.id ?? ConnectionStore.newId(),
        kind: ConnectorKind.claude,
        name: name.isEmpty ? (existing?.name ?? 'Claude key') : name,
        secret: key.isEmpty ? existing!.secret : key,
        model: _model,
      ),
    );
    if (mounted) Navigator.of(context).pop();
  }

  Future<void> _remove() async {
    await widget.store.remove(widget.existing!);
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final existing = widget.existing;
    final theme = Theme.of(context);
    final error = _error;
    return AlertDialog(
      title: Text(existing == null ? 'Add Claude API key' : existing.name),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _name,
              decoration: const InputDecoration(
                labelText: 'Name',
                hintText: 'e.g. Personal, Work',
              ),
            ),
            TextField(
              controller: _key,
              obscureText: true,
              autocorrect: false,
              enableSuggestions: false,
              decoration: InputDecoration(
                labelText: existing == null
                    ? 'API key'
                    : 'Replace key (${existing.hint})',
                hintText: 'sk-ant-…',
              ),
            ),
            const SizedBox(height: 20),
            const Text('Model'),
            const SizedBox(height: 8),
            SegmentedButton<CompanionModel>(
              showSelectedIcon: false,
              segments: [
                for (final m in CompanionModel.values)
                  ButtonSegment(value: m, label: Text(m.label)),
              ],
              selected: {_model},
              onSelectionChanged: (s) => setState(() => _model = s.single),
            ),
            const SizedBox(height: 6),
            Text(_model.blurb, style: theme.textTheme.bodySmall),
            if (error != null) ...[
              const SizedBox(height: 12),
              Text(error, style: TextStyle(color: theme.colorScheme.error)),
            ],
          ],
        ),
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

/// Logs in a new AnkiWeb account: a name, the email and the password. The
/// password is used for this login only; the account then stays signed in
/// on its sync key.
class _AnkiLoginDialog extends StatefulWidget {
  const _AnkiLoginDialog({required this.anki});

  final AnkiSync anki;

  @override
  State<_AnkiLoginDialog> createState() => _AnkiLoginDialogState();
}

class _AnkiLoginDialogState extends State<_AnkiLoginDialog> {
  final TextEditingController _name = TextEditingController();
  final TextEditingController _email = TextEditingController();
  final TextEditingController _password = TextEditingController();
  bool _busy = false;
  String? _message;

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _connect() async {
    final email = _email.text.trim();
    if (email.isEmpty || _password.text.isEmpty) {
      setState(() => _message = 'Enter your AnkiWeb email and password.');
      return;
    }
    setState(() {
      _busy = true;
      _message = null;
    });
    String message;
    try {
      final result = await widget.anki.connect(
        user: email,
        password: _password.text,
        name: _name.text,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Connected ${result.account.name} — ${result.notes} notes.',
          ),
        ),
      );
      Navigator.of(context).pop();
      return;
    } on AnkiException catch (e) {
      message = e.message;
    } catch (e) {
      message = 'Could not connect: $e';
    }
    if (!mounted) return;
    setState(() {
      _busy = false;
      _message = message;
    });
  }

  @override
  Widget build(BuildContext context) {
    final message = _message;
    return AlertDialog(
      title: const Text('Add Anki account'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _name,
              enabled: !_busy,
              decoration: const InputDecoration(
                labelText: 'Name',
                hintText: 'optional, e.g. Main',
              ),
            ),
            TextField(
              controller: _email,
              enabled: !_busy,
              keyboardType: TextInputType.emailAddress,
              autocorrect: false,
              enableSuggestions: false,
              decoration: const InputDecoration(labelText: 'AnkiWeb email'),
            ),
            TextField(
              controller: _password,
              enabled: !_busy,
              obscureText: true,
              autocorrect: false,
              enableSuggestions: false,
              decoration: const InputDecoration(labelText: 'Password'),
              onSubmitted: (_) => _connect(),
            ),
            if (_busy) ...[
              const SizedBox(height: 16),
              const LinearProgressIndicator(),
            ],
            if (message != null) ...[const SizedBox(height: 12), Text(message)],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _busy ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _busy ? null : _connect,
          child: const Text('Connect'),
        ),
      ],
    );
  }
}

/// A saved Anki account: rename it, choose its deck, sync, or remove it.
class _AnkiAccountDialog extends StatefulWidget {
  const _AnkiAccountDialog({required this.anki, required this.account});

  final AnkiSync anki;
  final Connection account;

  @override
  State<_AnkiAccountDialog> createState() => _AnkiAccountDialogState();
}

class _AnkiAccountDialogState extends State<_AnkiAccountDialog> {
  late final TextEditingController _name = TextEditingController(
    text: widget.account.name,
  );
  late String _deck = widget.account.deck ?? AnkiSync.defaultDeck;

  /// The collection's decks, read from Anki — chosen from, never typed.
  late final Future<List<String>> _decks = widget.anki.decksFor(widget.account);
  bool _busy = false;
  String? _message;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _run(Future<void> Function() task, String done) async {
    setState(() {
      _busy = true;
      _message = null;
    });
    String message;
    try {
      await task();
      message = done;
    } on AnkiException catch (e) {
      message = e.message;
    } catch (e) {
      message = 'Something went wrong: $e';
    }
    if (!mounted) return;
    setState(() {
      _busy = false;
      _message = message;
    });
  }

  Future<void> _save() async {
    final name = _name.text.trim();
    await widget.anki.setDeck(
      widget.account.copyWith(name: name.isEmpty ? null : name),
      _deck,
    );
    if (mounted) Navigator.of(context).pop();
  }

  Future<void> _remove() async {
    await widget.anki.remove(widget.account);
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final message = _message;
    return AlertDialog(
      title: Text(widget.account.name),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.account.user ?? ''),
            TextField(
              controller: _name,
              enabled: !_busy,
              decoration: const InputDecoration(labelText: 'Name'),
            ),
            const SizedBox(height: 12),
            FutureBuilder<List<String>>(
              future: _decks,
              builder: (_, snap) {
                if (snap.hasError) {
                  return Text('Could not read decks: ${snap.error}');
                }
                final names = snap.data;
                if (names == null) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    child: LinearProgressIndicator(),
                  );
                }
                return DropdownButtonFormField<String>(
                  initialValue: names.contains(_deck) ? _deck : null,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: 'Default deck',
                    helperText: 'You can still pick another for each card.',
                  ),
                  items: [
                    for (final name in names)
                      DropdownMenuItem(value: name, child: Text(name)),
                  ],
                  onChanged: _busy
                      ? null
                      : (name) {
                          if (name != null) setState(() => _deck = name);
                        },
                );
              },
            ),
            if (_busy) ...[
              const SizedBox(height: 16),
              const LinearProgressIndicator(),
            ],
            if (message != null) ...[const SizedBox(height: 12), Text(message)],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _busy ? null : _remove,
          child: const Text('Remove'),
        ),
        TextButton(
          onPressed: _busy
              ? null
              : () => _run(
                  () => widget.anki.syncNow(widget.account),
                  'In step with AnkiWeb.',
                ),
          child: const Text('Sync now'),
        ),
        FilledButton(
          onPressed: _busy ? null : _save,
          child: const Text('Save'),
        ),
      ],
    );
  }
}
