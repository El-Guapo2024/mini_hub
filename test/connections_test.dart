import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mini_hub/chinese/claude.dart';
import 'package:mini_hub/chinese/connections.dart';
import 'package:mini_hub/config.dart';

/// Several named keys and accounts, one of each kind in use: the companion
/// and the card sync both follow whichever is chosen.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const store = ConnectionStore();

  Connection claude(String id, CompanionModel model) => Connection(
    id: id,
    kind: ConnectorKind.claude,
    name: 'key $id',
    secret: 'sk-ant-$id-abcd',
    model: model,
  );

  setUp(() => FlutterSecureStorage.setMockInitialValues({}));

  test('the first saved goes into use; choosing another switches', () async {
    await store.save(claude('1', CompanionModel.haiku));
    await store.save(claude('2', CompanionModel.opus));
    expect((await store.active(ConnectorKind.claude))?.id, '1');

    await store.setActive(claude('2', CompanionModel.opus));
    expect(await ApiKeyStore.read(), 'sk-ant-2-abcd');
    expect(await ApiKeyStore.readModel(), CompanionModel.opus);
  });

  test(
    'removing the one in use hands over; removing the last clears',
    () async {
      final one = claude('1', CompanionModel.haiku);
      final two = claude('2', CompanionModel.sonnet);
      await store.save(one);
      await store.save(two);
      await store.remove(one);
      expect((await store.active(ConnectorKind.claude))?.id, '2');
      await store.remove(two);
      expect(await store.active(ConnectorKind.claude), isNull);
      expect(await ApiKeyStore.read(), isNull);
    },
  );

  test('Claude and Anki each keep their own choice', () async {
    await store.save(claude('1', CompanionModel.haiku));
    const account = Connection(
      id: 'a',
      kind: ConnectorKind.anki,
      name: 'Main',
      secret: 'hkey',
      user: 'me@x',
      deck: 'Chinese::Reader',
    );
    await store.save(account);
    expect((await store.active(ConnectorKind.claude))?.id, '1');
    expect((await store.active(ConnectorKind.anki))?.id, 'a');
  });

  test('an edit replaces the saved entry rather than adding one', () async {
    await store.save(claude('1', CompanionModel.haiku));
    await store.save(
      claude('1', CompanionModel.haiku).copyWith(model: CompanionModel.opus),
    );
    final list = await store.ofKind(ConnectorKind.claude);
    expect(list, hasLength(1));
    expect(list.single.model, CompanionModel.opus);
  });

  test('the key pasted before connectors is carried over', () async {
    FlutterSecureStorage.setMockInitialValues({
      'anthropic_api_key': 'sk-ant-old-9876',
      'companion_model': 'haiku',
    });
    expect(await ApiKeyStore.read(), 'sk-ant-old-9876');
    expect(await ApiKeyStore.readModel(), CompanionModel.haiku);
    final stored = await const FlutterSecureStorage().readAll();
    expect(stored.containsKey('anthropic_api_key'), isFalse);
    expect(await store.ofKind(ConnectorKind.claude), hasLength(1));
  });

  test('no key means the default model and no key', () async {
    expect(await ApiKeyStore.read(), isNull);
    expect(await ApiKeyStore.readModel(), ChineseConfig.defaultModel);
  });

  test('a hint shows only the last four characters', () {
    expect(claude('1', CompanionModel.haiku).hint, '…abcd');
  });
}
