import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mini_hub/chinese/anki_sync.dart';
import 'package:mini_hub/chinese/card.dart';
import 'package:mini_hub/chinese/connections.dart';

/// The Rust side is proven against AnkiWeb by hand; these pin what the app
/// asks of it — and, above all, that it never pushes a full copy up.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const store = ConnectionStore();
  late List<(String, Map<String, Object?>)> calls;
  late String syncStatus;
  late int logins;

  AnkiSync anki() => AnkiSync(
    store: store,
    root: () async => '/tmp/mini_hub_anki_test',
    call: (method, args) async {
      calls.add((method, args));
      switch (method) {
        case 'login':
          return {'hkey': 'key${++logins}'};
        case 'sync':
          return {'status': syncStatus, 'endpoint': null};
        case 'download':
          return {'notes': 12};
        case 'add':
          return {'id': 7};
        case 'decks':
          return {
            'decks': ['Default', 'Mandarin::Books'],
          };
      }
      return {};
    },
  );

  const card = Card(word: '了', pinyin: 'le', gloss: 'done', sentence: '他来了');

  setUp(() {
    FlutterSecureStorage.setMockInitialValues({});
    calls = [];
    syncStatus = 'ok';
    logins = 0;
  });

  test('connect saves an account on its sync key, not the password', () async {
    syncStatus = 'full_download_required';
    final result = await anki().connect(user: 'me@x', password: 'pw-9f3kq');
    expect(result.notes, 12);
    expect(result.account.name, 'me@x');
    expect(result.account.secret, 'key1');
    expect((await store.active(ConnectorKind.anki))?.id, result.account.id);
    final stored = await const FlutterSecureStorage().readAll();
    expect(stored.values.join(), isNot(contains('pw-9f3kq')));
  });

  test('a failed connect saves nothing', () async {
    final a = AnkiSync(
      store: store,
      root: () async => '/tmp/mini_hub_anki_test',
      call: (method, args) async {
        if (method == 'sync') throw AnkiException('offline');
        return {'hkey': 'k'};
      },
    );
    await expectLater(
      a.connect(user: 'me@x', password: 'pw'),
      throwsA(isA<AnkiException>()),
    );
    expect(await store.ofKind(ConnectorKind.anki), isEmpty);
  });

  test('cards go to the account in use, with its own deck', () async {
    final a = anki();
    final first = (await a.connect(user: 'a@x', password: 'pw')).account;
    final second = (await a.connect(user: 'b@x', password: 'pw')).account;
    expect((await store.active(ConnectorKind.anki))?.id, first.id);

    await a.setDeck(second, 'Mandarin::Books');
    await store.setActive(second);
    calls.clear();
    expect(await a.add(card), 7);

    final add = calls.firstWhere((c) => c.$1 == 'add').$2;
    expect(add['hkey'], 'key2');
    expect(add['deck'], 'Mandarin::Books');
  });

  test('decks lists the collection, and nothing of our own', () async {
    final a = anki();
    await a.connect(user: 'me@x', password: 'pw');
    // No deck of ours in the list. It used to carry one whether or not the
    // collection had ever heard of it, which read as a real deck.
    expect(await a.decks(), ['Default', 'Mandarin::Books']);
  });

  test('a card can go to any deck, which becomes the usual one', () async {
    final a = anki();
    await a.connect(user: 'me@x', password: 'pw');
    calls.clear();
    await a.add(card, deck: 'Mandarin::Books');
    expect(
      calls.firstWhere((c) => c.$1 == 'add').$2['deck'],
      'Mandarin::Books',
    );
    expect((await a.activeAccount())?.deck, 'Mandarin::Books');

    calls.clear();
    await a.add(card);
    expect(
      calls.firstWhere((c) => c.$1 == 'add').$2['deck'],
      'Mandarin::Books',
    );
  });

  test('with no Anki account, decks is empty', () async {
    expect(await anki().decks(), isEmpty);
    expect(calls, isEmpty);
  });

  test('with no Anki account, add does nothing', () async {
    expect(await anki().add(card), isNull);
    expect(calls, isEmpty);
  });

  test('an add survives a sync that asks for a full sync', () async {
    final a = anki();
    await a.connect(user: 'me@x', password: 'pw');
    syncStatus = 'full_upload_required'; // must not be acted on
    calls.clear();
    expect(await a.add(card), 7);
    expect(calls.map((c) => c.$1), ['add', 'sync']);
  });

  test('a diverged collection is replaced from AnkiWeb, not refused', () async {
    final a = anki();
    final account = (await a.connect(user: 'me@x', password: 'pw')).account;
    // What an upload from desktop Anki looks like from here: the two no
    // longer share a history, and AnkiWeb's copy is the one that counts.
    syncStatus = 'full_download_required';
    calls.clear();

    await a.syncNow(account);
    expect(calls.map((c) => c.$1), ['sync', 'download']);
  });

  test('syncNow still refuses to push this phone up', () async {
    final a = anki();
    final account = (await a.connect(user: 'me@x', password: 'pw')).account;
    syncStatus = 'full_upload_required';
    calls.clear();

    await expectLater(a.syncNow(account), throwsA(isA<AnkiException>()));
    expect(calls.map((c) => c.$1), ['sync']);
  });

  test('an empty AnkiWeb account connects without a download', () async {
    expect((await anki().connect(user: 'me@x', password: 'pw')).notes, 0);
    expect(calls.map((c) => c.$1), ['login', 'sync']);
  });

  test('removing an account forgets it', () async {
    final a = anki();
    final account = (await a.connect(user: 'me@x', password: 'pw')).account;
    await a.remove(account);
    expect(await store.ofKind(ConnectorKind.anki), isEmpty);
  });

  test('fields are escaped HTML, one per part of the card', () {
    final f = AnkiSync.chineseFields(
      const Card(word: 'a<b', pinyin: 'pīn', gloss: 'x & y', sentence: '句子'),
    );
    expect(f, ['a&lt;b', 'pīn', 'x &amp; y', '句子']);
  });

  test('cards are added as the speaking note type', () async {
    final a = anki();
    await a.connect(user: 'me@x', password: 'pw');
    calls.clear();
    await a.add(card);
    final add = calls.firstWhere((c) => c.$1 == 'add').$2;
    expect(add['notetype'], AnkiSync.noteType);
    expect(add['fields'], ['了', 'le', 'done', '他来了']);
  });
}
