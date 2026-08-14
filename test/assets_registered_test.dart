import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:mini_hub/config.dart';
import 'package:yaml/yaml.dart';

/// Every content directory has to be listed in pubspec.yaml by hand, and a
/// missing line fails at runtime rather than at build: the folder is simply
/// absent from the bundle and the lesson 404s on a real device while looking
/// perfectly fine on disk. With 120 topics maintained by hand this is the
/// easiest mistake in the project to make and the hardest to spot.
void main() {
  test('every content directory is registered in pubspec.yaml', () {
    final pubspec = loadYaml(File('pubspec.yaml').readAsStringSync());
    final registered = (pubspec['flutter']['assets'] as YamlList)
        .map((e) => (e as String).replaceAll(RegExp(r'/$'), ''))
        .toSet();

    final missing = <String>[];
    for (final dir
        in ['assets/content', 'assets/sample']
            .map(Directory.new)
            .expand((d) => d.listSync(recursive: true))
            .whereType<Directory>()) {
      final path = dir.path.replaceAll(RegExp(r'/$'), '');
      // Only directories holding files need registering; Flutter's asset
      // entries are per-directory and do not recurse.
      final hasFiles = dir.listSync().whereType<File>().isNotEmpty;
      if (hasFiles && !registered.contains(path)) missing.add(path);
    }

    expect(
      missing,
      isEmpty,
      reason:
          'these folders ship no files to the device — add them under '
          'flutter.assets in pubspec.yaml',
    );
  });

  test('every registered content directory still exists', () {
    final pubspec = loadYaml(File('pubspec.yaml').readAsStringSync());
    final stale = <String>[];
    for (final entry in pubspec['flutter']['assets'] as YamlList) {
      final path = (entry as String).replaceAll(RegExp(r'/$'), '');
      if (!path.startsWith('assets/content') &&
          !path.startsWith('assets/sample')) {
        continue;
      }
      if (!Directory(path).existsSync()) stale.add(path);
    }

    // A renamed folder left behind in pubspec.yaml fails the whole build with
    // a message that names the asset, not the rename that caused it.
    expect(stale, isEmpty, reason: 'listed in pubspec.yaml but not on disk');
  });

  // Both are selectable at build time, so a broken sample index is a broken
  // build for whoever picks it — not a second-class file.
  for (final source in ContentSource.values) {
    test('the ${source.name} index resolves to real courses and topics', () {
      // A course reaches the student only by being named here, so an index
      // that has drifted from disk hides content with no error anywhere.
      final index =
          jsonDecode(File(source.indexPath).readAsStringSync())
              as List<dynamic>;
      expect(index, isNotEmpty);

      final missing = <String>[];
      for (final entry in index.cast<Map<String, dynamic>>()) {
        final path = (entry['path'] as String).replaceAll(RegExp(r'/$'), '');
        final file = File('$path/course.yml');
        if (!file.existsSync()) {
          missing.add('$path/course.yml');
          continue;
        }
        final course = loadYaml(file.readAsStringSync());
        for (final topic in course['topics'] as YamlList) {
          if (!File('$path/$topic/topic.yml').existsSync()) {
            missing.add('$path/$topic');
          }
        }
      }

      expect(missing, isEmpty, reason: 'named in the index but not on disk');
    });
  }
}
