import 'dart:io';

import 'package:path_provider/path_provider.dart';

import 'anki_bridge.dart';
import 'card.dart';
import 'connections.dart';

export 'anki_bridge.dart' show AnkiException;

typedef AnkiCall =
    Future<Map<String, dynamic>> Function(
      String method,
      Map<String, Object?> args,
    );

/// Cards go straight into the user's own Anki collection and on to AnkiWeb,
/// so they turn up in every Anki app they review in. Each saved account
/// keeps its own copy of its collection on the phone (Anki syncs by
/// collection, not by card); an add lands in that copy at once and rides the
/// next sync that gets through, so a card made offline is never lost.
class AnkiSync {
  AnkiSync({
    ConnectionStore? store,
    AnkiCall? call,
    Future<String> Function()? root,
  }) : _store = store ?? const ConnectionStore(),
       _call = call ?? AnkiBridge.call,
       _root = root ?? _defaultRoot;

  final ConnectionStore _store;
  final AnkiCall _call;
  final Future<String> Function() _root;

  /// Where a card goes when the user has not chosen a deck. Anki's own
  /// deck, which every collection has — not a deck of ours invented in the
  /// user's collection. The decks belong to AnkiWeb; this app names none.
  static const String fallbackDeck = 'Default';

  static Future<String> _defaultRoot() async =>
      '${(await getApplicationSupportDirectory()).path}/anki';

  Future<String> _dir(Connection account) async =>
      '${await _root()}/${account.id}';

  Future<Map<String, Object?>> _auth(Connection account) async => {
    'dir': await _dir(account),
    'hkey': account.secret,
    'endpoint': account.endpoint,
  };

  /// Logs in to AnkiWeb and brings that collection onto the phone as a new
  /// saved account. Only the sync key Anki hands back is kept; the password
  /// goes no further than this call. Nothing is saved unless it all works.
  Future<({Connection account, int notes})> connect({
    required String user,
    required String password,
    String name = '',
  }) async {
    final login = await _call('login', {'user': user, 'pass': password});
    var account = Connection(
      id: ConnectionStore.newId(),
      kind: ConnectorKind.anki,
      name: name.trim().isEmpty ? user : name.trim(),
      secret: login['hkey'] as String,
      user: user,
      // No deck chosen yet: the collection's own decks are what to choose
      // from, and they are not known until it has come down.
      deck: null,
    );
    try {
      // A fresh, empty copy can only be asked to pull.
      final (status, updated) = await _sync(account);
      account = updated;
      if (status == 'full_upload_required') {
        throw AnkiException(
          'AnkiWeb asks for a full sync. Sync in desktop Anki first, then '
          'connect again.',
        );
      }
      var notes = 0;
      if (status == 'full_download_required') {
        final pulled = await _call('download', await _auth(account));
        notes = pulled['notes'] as int;
      }
      await _store.save(account);
      return (account: account, notes: notes);
    } catch (_) {
      await _deleteCopy(account);
      rethrow;
    }
  }

  /// Forgets the account and its copy of the collection on this phone.
  /// Its cards already synced stay in AnkiWeb.
  Future<void> remove(Connection account) async {
    await _deleteCopy(account);
    await _store.remove(account);
  }

  /// Remembers which deck this account's cards go into. An empty name
  /// clears the choice rather than standing in a deck of our own.
  Future<Connection> setDeck(Connection account, String deck) async {
    final chosen = deck.trim();
    final updated = account.copyWith(deck: chosen.isEmpty ? null : chosen);
    await _store.save(updated);
    return updated;
  }

  /// Brings this phone in step with AnkiWeb, which is the collection that
  /// counts.
  ///
  /// When the two no longer share a history — someone uploaded from desktop
  /// Anki, which replaces the cloud collection outright — the phone's copy
  /// is replaced rather than defended. That costs nothing, because nothing
  /// lives only here: cards go to Anki as they are made, and the copy on
  /// the phone is a working copy, not a record.
  ///
  /// The other direction stays refused. This phone's copy going up over the
  /// real collection is the one mistake with no undo, and no amount of
  /// convenience is worth it.
  Future<void> syncNow(Connection account) async {
    final (status, updated) = await _sync(account);
    if (status == 'full_download_required') {
      await _call('download', await _auth(updated));
      return;
    }
    if (status == 'full_upload_required') {
      throw AnkiException(
        'AnkiWeb wants this phone to replace the collection, which it will '
        'not do. Sync in desktop Anki first, then try again.',
      );
    }
  }

  Future<Connection?> activeAccount() => _store.active(ConnectorKind.anki);

  /// The decks in the collection of the account in use — synced first, so a
  /// deck just made in desktop Anki shows. The account's own deck is always
  /// listed, even before a first card has created it. Empty with no account.
  Future<List<String>> decks() async {
    final account = await activeAccount();
    return account == null ? [] : decksFor(account);
  }

  /// The decks of [account], whether or not it is the one in use.
  Future<List<String>> decksFor(Connection account) async {
    try {
      await syncNow(account);
    } catch (_) {
      // Offline: the phone's copy still knows every deck it has seen.
    }
    final out = await _call('decks', {'dir': await _dir(account)});
    // Exactly the collection's decks. A deck the user has not made is not
    // offered: the list used to carry our own name whether or not Anki had
    // ever heard of it, which read as a real deck and was not one.
    return [for (final d in out['decks'] as List) d as String];
  }

  /// Adds [card] to the Anki account in use — into [deck], or the account's
  /// usual deck — and tries to sync. A chosen deck becomes the usual one, so
  /// the next card goes where the last did. The card is safe in the phone's
  /// copy even when the sync fails. Returns the note id, or null when no
  /// Anki account is connected.
  Future<int?> add(Card card, {String? deck}) async {
    var account = await activeAccount();
    if (account == null) return null;
    final chosen = deck?.trim() ?? '';
    if (chosen.isNotEmpty && chosen != account.deck) {
      account = await setDeck(account, chosen);
    }
    final added = await _call('add', {
      ...await _auth(account),
      'deck': account.deck ?? fallbackDeck,
      'notetype': noteType,
      'create_notetype': noteTypeSpec,
      'fields': chineseFields(card),
      'tags': ['mini_hub'],
    });
    try {
      await syncNow(account);
    } catch (_) {
      // Offline or AnkiWeb busy — the next sync carries it.
    }
    return added['id'] as int;
  }

  /// Syncs, keeping any new sync server AnkiWeb moves the account to.
  Future<(String, Connection)> _sync(Connection account) async {
    final out = await _call('sync', await _auth(account));
    final endpoint = out['endpoint'] as String?;
    var updated = account;
    if (endpoint != null && endpoint != account.endpoint) {
      updated = account.copyWith(endpoint: endpoint);
      final saved = await _store.ofKind(ConnectorKind.anki);
      if (saved.any((c) => c.id == account.id)) await _store.save(updated);
    }
    return (out['status'] as String, updated);
  }

  Future<void> _deleteCopy(Connection account) async {
    final dir = Directory(await _dir(account));
    if (await dir.exists()) await dir.delete(recursive: true);
  }

  /// The note type cards are added as. The bridge creates it in the user's
  /// collection the first time: the word on the front, spoken by Anki's own
  /// Chinese text-to-speech; pinyin, meaning and the sentence on the back,
  /// the sentence spoken too. Anki speaks it on every device, so no audio
  /// files are made or synced.
  static const String noteType = 'mini_hub Chinese';

  /// How that note type looks, used only when the collection lacks it.
  /// `{{tts zh_CN:…}}` is Anki's own text-to-speech tag: the word is spoken
  /// when the card is shown, and the sentence with the answer. Changing
  /// this later won't touch a note type already made — Anki would need a
  /// full sync for that.
  static const Map<String, Object> noteTypeSpec = {
    'fields': ['Word', 'Pinyin', 'Meaning', 'Sentence'],
    'front':
        '<div style="font-size: 48px; text-align: center">{{Word}}</div>\n'
        '{{tts zh_CN:Word}}',
    'back':
        '{{FrontSide}}\n\n<hr id=answer>\n\n'
        '<div style="text-align: center">\n'
        '<div style="font-size: 22px">{{Pinyin}}</div>\n'
        '<div>{{Meaning}}</div>\n'
        '<p style="font-size: 24px">{{Sentence}}</p>\n'
        '</div>\n'
        '{{tts zh_CN:Sentence}}',
  };

  /// That note type's fields, in order: Word, Pinyin, Meaning, Sentence.
  /// Anki fields are HTML, so text is escaped.
  static List<String> chineseFields(Card card) {
    String esc(String s) => s
        .replaceAll('&', '&amp;')
        .replaceAll('<', '&lt;')
        .replaceAll('>', '&gt;');
    return [
      esc(card.word),
      esc(card.pinyin),
      esc(card.gloss),
      esc(card.sentence),
    ];
  }
}
