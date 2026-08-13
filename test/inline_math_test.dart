import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// LatexInlineSyntax ends its pattern with a lookahead:
///     (?=[\s?!.,:？！。，：]|$)
/// so a closing '$' followed by anything else (an apostrophe, ')', '-', '*')
/// never matches and the whole span renders as raw '$...$' text.
const allowedAfterInlineMath = ' \t\n?!.,:？！。，：';

void main() {
  test('inline math is always followed by whitespace or punctuation', () {
    final dir = Directory('assets/content/number_sense');
    final offenders = <String>[];

    for (final d in dir.listSync().whereType<Directory>()) {
      final f = File('${d.path}/lesson.md');
      if (!f.existsSync()) continue;
      // Drop display blocks; only inline spans are subject to the lookahead.
      final inline = f.readAsStringSync().replaceAll(
        RegExp(r'\$\$.*?\$\$', dotAll: true),
        '',
      );

      for (final m in RegExp(r'(?<!\$)\$([^$\n]+)\$').allMatches(inline)) {
        if (m.end >= inline.length) continue;
        final next = inline[m.end];
        if (!allowedAfterInlineMath.contains(next)) {
          offenders.add(
            '${d.path.split('/').last}: "${m.group(0)}" followed by "$next"',
          );
        }
      }
    }

    expect(
      offenders,
      isEmpty,
      reason: 'inline math that renders as raw text:\n${offenders.join('\n')}',
    );
  });
}
