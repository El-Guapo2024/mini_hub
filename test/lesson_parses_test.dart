import 'dart:io';

import 'package:flutter_math_fork/flutter_math.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/latex.dart';

/// A lesson's math that TeX cannot read does not throw and does not fail a
/// widget test: `Math.tex` catches the error and draws "Parser Error: ..."
/// where the working should be. So pumping a lesson and finding no exception
/// proves only that it did not crash — the student is still shown the error.
///
/// Checked here through `parseError`, which the widget sets at construction,
/// and through the app's own lesson dialect, so a span that renders as an
/// error fails here instead of on a device.
void main() {
  final lessons = [
    for (final root in ['assets/content', 'assets/sample'])
      ...Directory(root)
          .listSync(recursive: true)
          .whereType<File>()
          .where((f) => f.path.endsWith('lesson.md')),
  ];

  test('there are lessons to parse', () {
    expect(lessons, isNotEmpty);
  });

  test('every lesson renders its math rather than an error', () {
    final broken = <String>[];
    var spans = 0;

    for (final lesson in lessons) {
      for (final tex in latexSpans(lesson.readAsStringSync())) {
        spans++;
        final error = Math.tex(tex).parseError;
        if (error != null) {
          broken.add('${lesson.parent.path}: $tex\n    ${error.message}');
        }
      }
    }

    expect(spans, greaterThan(500), reason: 'the lessons were read');
    expect(
      broken,
      isEmpty,
      reason:
          '${broken.length} of $spans spans would draw a parser error:\n'
          '${broken.take(20).join('\n')}',
    );
  });
}
