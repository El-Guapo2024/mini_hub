import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'support/latex.dart';

void main() {
  test('every generated lesson parses its display math', () {
    final dir = Directory('assets/content/number_sense');
    final lessons = dir
        .listSync()
        .whereType<Directory>()
        .map((d) => File('${d.path}/lesson.md'))
        .where((f) => f.existsSync());

    final broken = <String>[];
    final sameLine = <String>[];
    var withMath = 0;
    for (final f in lessons) {
      final src = f.readAsStringSync();
      if (!src.contains(r'$$')) continue;
      withMath++;
      final name = f.parent.path.split('/').last;
      if (latexBlocks(src) == 0) broken.add(name);
      // A '$$' followed by anything but a newline is the shape that silently
      // renders as raw text when the math spans lines — see latex_syntax_test.
      if (RegExp(r'\$\$[^\n]').hasMatch(src)) sameLine.add(name);
    }

    expect(
      withMath,
      greaterThan(50),
      reason: 'expected many lessons to use display math',
    );
    expect(
      broken,
      isEmpty,
      reason: 'lessons whose display math renders as raw text: $broken',
    );
    expect(
      sameLine,
      isEmpty,
      reason: 'lessons with same-line \$\$ delimiters: $sameLine',
    );
  });

  test('no topic title contains LaTeX', () {
    // The app bar renders the title as a plain Text widget, so a '$...$' span
    // there shows up as literal source. Titles must be plain unicode.
    final withMath = Directory('assets/content/number_sense')
        .listSync()
        .whereType<Directory>()
        .map((d) => File('${d.path}/topic.yml'))
        .where(
          (f) =>
              f.existsSync() &&
              f
                  .readAsStringSync()
                  .split('\n')
                  .any((l) => l.startsWith('title:') && l.contains(r'$')),
        )
        .map((f) => f.parent.path.split('/').last)
        .toList();

    expect(
      withMath,
      isEmpty,
      reason: 'topics whose title renders as raw LaTeX: $withMath',
    );
  });

  test('no lesson uses a markdown table', () {
    // MarkdownBody lays tables out at the available width with no horizontal
    // scroll, so on a phone the columns crush together. Wide tabular content
    // belongs in a display-math array, which scrolls sideways instead.
    final tables = Directory('assets/content/number_sense')
        .listSync()
        .whereType<Directory>()
        .map((d) => File('${d.path}/lesson.md'))
        .where(
          (f) =>
              f.existsSync() &&
              f.readAsStringSync().split('\n').any((l) => l.startsWith('|')),
        )
        .map((f) => f.parent.path.split('/').last)
        .toList();

    expect(tables, isEmpty, reason: 'lessons using markdown tables: $tables');
  });
}
