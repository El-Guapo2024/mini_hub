import 'dart:io';

import 'package:path_provider/path_provider.dart';

import 'anki_sync.dart';
import 'card_store.dart';

/// Where every saved card goes: the phone's own log first, always, then the
/// user's Anki collection once they have connected AnkiWeb. Anki refusing
/// or being out of reach never loses the card — it is already in the log.
///
/// Returns null when all went well (or Anki isn't connected), otherwise a
/// line the reader can be shown.
Future<String?> keepCard(Card card, {String? deck, AnkiSync? anki}) async {
  await (await CardStore.open()).add(card);
  final sync = anki ?? AnkiSync();
  try {
    // Into [deck], or the account's usual one; nothing without an account.
    await sync.add(card, deck: deck);
    return null;
  } on AnkiException catch (e) {
    await _log('add failed: $e');
    return 'Saved on the phone, but Anki refused it: $e';
  } catch (e) {
    await _log('add failed: $e');
    return 'Saved on the phone; Anki could not be reached.';
  }
}

/// Same trace file the reader writes — the only observable channel from a
/// simctl-launched app.
Future<void> _log(String line) async {
  try {
    final d = await getApplicationDocumentsDirectory();
    File('${d.path}/reader_log.txt').writeAsStringSync(
      '${DateTime.now().toIso8601String()} anki: $line\n',
      mode: FileMode.append,
    );
  } catch (_) {}
}
