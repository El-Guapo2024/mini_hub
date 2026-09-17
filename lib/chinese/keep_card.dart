import 'dart:io';

import 'package:path_provider/path_provider.dart';

import 'anki_sync.dart';
import 'card.dart';

/// Where every saved card goes: the user's Anki collection, and nowhere
/// else. Anki owns the cards — the phone keeps no copy of its own — so a
/// card Anki would not take is a card that was not saved, and the reader
/// says so rather than reassuring the user about a log that no longer
/// exists.
///
/// Returns null when the card is safely in Anki, otherwise a line the
/// reader can show.
Future<String?> keepCard(Card card, {String? deck, AnkiSync? anki}) async {
  final sync = anki ?? AnkiSync();
  try {
    // Into [deck], or the account's usual one; null when none is connected.
    final id = await sync.add(card, deck: deck);
    if (id == null) {
      return 'No Anki account connected, so the card was not saved.';
    }
    return null;
  } on AnkiException catch (e) {
    await _log('add failed: $e');
    return 'Anki refused the card, so it was not saved: $e';
  } catch (e) {
    await _log('add failed: $e');
    return 'Anki could not be reached, so the card was not saved.';
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
