import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

import 'reading.dart';

/// Prepared readings on disk, addressed by the sentence they are for.
///
/// A reading is expensive once and free forever after: the sentence does not
/// change, so neither does its reading. Re-reading a page therefore costs
/// nothing, which is what makes going back over a paragraph affordable.
class ReadingCache {
  ReadingCache(this.directory);

  final Directory directory;

  static Future<ReadingCache> open() async {
    final docs = await getApplicationDocumentsDirectory();
    return ReadingCache(Directory('${docs.path}/chinese_readings'));
  }

  /// FNV-1a over the UTF-8 bytes. A hash, not a dependency: `String.hashCode`
  /// carries no promise of staying the same between Dart releases, and a
  /// cache keyed on a value that can shift underneath it is a cache that
  /// quietly stops hitting.
  static String keyFor(String sentence) {
    var hash = 0xcbf29ce484222325;
    for (final byte in utf8.encode(sentence.trim())) {
      hash = (hash ^ byte) * 0x100000001b3;
      hash &= 0xFFFFFFFFFFFFFFFF;
    }
    return hash.toRadixString(16).padLeft(16, '0');
  }

  File _fileFor(String sentence) =>
      File('${directory.path}/${keyFor(sentence)}.json');

  /// Null for anything not prepared before. A collision, a half-written file
  /// or a reading from an older shape all read as a miss — the cost of being
  /// wrong here is one more call, so nothing about a bad entry is fatal.
  Future<Reading?> get(String sentence) async {
    final file = _fileFor(sentence);
    if (!await file.exists()) return null;
    try {
      final json =
          jsonDecode(await file.readAsString()) as Map<String, dynamic>;
      final reading = Reading.fromJson(json);
      if (reading.sentence != sentence.trim()) return null;
      return reading;
    } on FormatException {
      return null;
    } on TypeError {
      return null;
    }
  }

  Future<void> put(Reading reading) async {
    if (reading.sentence.isEmpty) return;
    await directory.create(recursive: true);
    await _fileFor(
      reading.sentence,
    ).writeAsString(jsonEncode(reading.toJson()));
  }
}
