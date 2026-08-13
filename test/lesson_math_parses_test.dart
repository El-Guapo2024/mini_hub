import 'dart:io';

import 'package:flutter_math_fork/flutter_math.dart';
import 'package:flutter_test/flutter_test.dart';

/// Every display-math block in every lesson must actually parse.
/// A block that fails here renders as a red error (or garbage) in the app,
/// which reading the markdown source will not reveal.
void main() {
  test('all lesson math parses', () {
    final dir = Directory('assets/content/number_sense');
    final failures = <String>[];
    var blocks = 0;

    for (final d in dir.listSync().whereType<Directory>()) {
      final f = File('${d.path}/lesson.md');
      if (!f.existsSync()) continue;
      final src = f.readAsStringSync();
      for (final m in RegExp(
        r'\$\$\n(.*?)\n\$\$',
        dotAll: true,
      ).allMatches(src)) {
        blocks++;
        final tex = m.group(1)!;
        final error = Math.tex(tex).parseError;
        if (error != null) {
          failures.add(
            '${d.path.split('/').last}: ${tex.split('\n').first}  ->  $error',
          );
        }
      }
    }

    expect(blocks, greaterThan(200), reason: 'expected many math blocks');
    expect(
      failures,
      isEmpty,
      reason: 'unparseable math:\n${failures.join('\n')}',
    );
  });
}
