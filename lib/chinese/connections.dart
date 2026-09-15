import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../config.dart';

enum ConnectorKind { claude, anki }

/// One saved way into an outside service: a named Claude API key with the
/// model chosen for it, or a logged-in AnkiWeb account with its deck. Several
/// of each can be kept; one of each kind is in use at a time.
class Connection {
  const Connection({
    required this.id,
    required this.kind,
    required this.name,
    required this.secret,
    this.model,
    this.user,
    this.endpoint,
    this.deck,
  });

  final String id;
  final ConnectorKind kind;
  final String name;

  /// The Claude API key, or the sync key AnkiWeb hands back at login —
  /// never an AnkiWeb password.
  final String secret;

  /// Claude only: the model this key runs.
  final CompanionModel? model;

  /// Anki only: the account's email, the sync server it was moved to, and
  /// the deck new cards go into.
  final String? user;
  final String? endpoint;
  final String? deck;

  Connection copyWith({
    String? name,
    CompanionModel? model,
    String? endpoint,
    String? deck,
  }) => Connection(
    id: id,
    kind: kind,
    name: name ?? this.name,
    secret: secret,
    model: model ?? this.model,
    user: user,
    endpoint: endpoint ?? this.endpoint,
    deck: deck ?? this.deck,
  );

  /// The last four characters — enough to tell keys apart without showing
  /// one.
  String get hint =>
      secret.length <= 4 ? '••••' : '…${secret.substring(secret.length - 4)}';

  Map<String, String> toJson() => {
    'id': id,
    'kind': kind.name,
    'name': name,
    'secret': secret,
    if (model != null) 'model': model!.name,
    'user': ?user,
    'endpoint': ?endpoint,
    'deck': ?deck,
  };

  static Connection? fromJson(Map<String, dynamic> j) {
    final kind = ConnectorKind.values.asNameMap()[j['kind']];
    final id = j['id'];
    final secret = j['secret'];
    if (kind == null || id is! String || secret is! String) return null;
    return Connection(
      id: id,
      kind: kind,
      name: j['name'] as String? ?? '',
      secret: secret,
      model: CompanionModel.values.asNameMap()[j['model']],
      user: j['user'] as String?,
      endpoint: j['endpoint'] as String?,
      deck: j['deck'] as String?,
    );
  }
}

/// The saved connections, in the Keychain. Secrets included, so the whole
/// list lives there rather than in plain preferences.
class ConnectionStore {
  const ConnectionStore([this._storage = const FlutterSecureStorage()]);

  final FlutterSecureStorage _storage;

  static const String _listKey = 'connections';
  static String _activeKey(ConnectorKind kind) => 'active_${kind.name}';

  static String newId() => DateTime.now().microsecondsSinceEpoch.toString();

  Future<List<Connection>> all() async {
    await _migrate();
    return _read();
  }

  Future<List<Connection>> ofKind(ConnectorKind kind) async => [
    for (final c in await all())
      if (c.kind == kind) c,
  ];

  /// The one of [kind] in use; the first saved when none was chosen.
  Future<Connection?> active(ConnectorKind kind) async {
    final list = await ofKind(kind);
    if (list.isEmpty) return null;
    final id = await _storage.read(key: _activeKey(kind));
    return list.firstWhere((c) => c.id == id, orElse: () => list.first);
  }

  Future<void> setActive(Connection c) =>
      _storage.write(key: _activeKey(c.kind), value: c.id);

  /// Adds [c], or replaces the saved one with its id. The first of a kind
  /// goes straight into use.
  Future<void> save(Connection c) async {
    final list = await all();
    final i = list.indexWhere((x) => x.id == c.id);
    if (i >= 0) {
      list[i] = c;
    } else {
      list.add(c);
    }
    await _write(list);
    if (await _storage.read(key: _activeKey(c.kind)) == null) {
      await setActive(c);
    }
  }

  /// Removing the one in use hands over to another of its kind, if any.
  Future<void> remove(Connection c) async {
    final list = (await all())..removeWhere((x) => x.id == c.id);
    await _write(list);
    if (await _storage.read(key: _activeKey(c.kind)) != c.id) return;
    final next = list.where((x) => x.kind == c.kind);
    if (next.isEmpty) {
      await _storage.delete(key: _activeKey(c.kind));
    } else {
      await setActive(next.first);
    }
  }

  Future<List<Connection>> _read() async {
    final raw = await _storage.read(key: _listKey);
    if (raw == null) return [];
    try {
      final list = <Connection>[];
      for (final j in jsonDecode(raw) as List) {
        final c = j is Map<String, dynamic> ? Connection.fromJson(j) : null;
        if (c != null) list.add(c);
      }
      return list;
    } on FormatException {
      return []; // an unreadable list costs the saved entries, not the app
    }
  }

  Future<void> _write(List<Connection> list) => _storage.write(
    key: _listKey,
    value: jsonEncode([for (final c in list) c.toJson()]),
  );

  /// Before connectors there was one Claude key and one model, stored on
  /// their own. Carried over once, so a reader keeps the key they pasted.
  /// (The single-account Anki keys never shipped; they are just dropped.)
  Future<void> _migrate() async {
    const legacyKey = 'anthropic_api_key';
    const legacyModel = 'companion_model';
    final key = (await _storage.read(key: legacyKey))?.trim();
    if (key != null) {
      if (key.isNotEmpty) {
        final model = CompanionModel.values
            .asNameMap()[await _storage.read(key: legacyModel)];
        final c = Connection(
          id: newId(),
          kind: ConnectorKind.claude,
          name: 'Claude key',
          secret: key,
          model: model ?? ChineseConfig.defaultModel,
        );
        await _write([...await _read(), c]);
        await setActive(c);
      }
      await _storage.delete(key: legacyKey);
      await _storage.delete(key: legacyModel);
    }
    if (await _storage.read(key: 'anki_hkey') != null) {
      for (final k in ['anki_hkey', 'anki_endpoint', 'anki_deck']) {
        await _storage.delete(key: k);
      }
    }
  }
}
