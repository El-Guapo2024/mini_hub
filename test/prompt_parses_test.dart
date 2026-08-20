import 'dart:convert';
import 'dart:io';

import 'package:flutter_math_fork/flutter_math.dart';
import 'package:flutter_test/flutter_test.dart';

/// Every prompt and every revealed answer is rendered as TeX. A prompt TeX
/// cannot parse does not throw and does not fail a widget test: `Math.tex`
/// catches the error and returns a box reading "Parser Error: ..." where the
/// question should be. So the student is shown the error, and nothing else
/// notices.
///
/// Checked here through `parseError`, which the widget sets at construction, so
/// the whole bank is covered without pumping a frame for each of them.
void main() {
  final files = Directory('assets/content')
      .listSync(recursive: true)
      .whereType<File>()
      .where((f) => f.path.endsWith('questions.json'))
      .toList();

  test('there are generated questions to parse', () {
    expect(files, isNotEmpty);
  });

  test('every prompt and revealed answer parses as TeX', () {
    final broken = <String>[];
    var checked = 0;

    for (final file in files) {
      final questions = jsonDecode(file.readAsStringSync()) as List<dynamic>;
      for (final raw in questions.cast<Map<String, dynamic>>()) {
        final id = raw['id'] as String;
        final answer = raw['answer'] as Map<String, dynamic>;

        for (final tex in [raw['prompt'], answer['display']]) {
          if (tex is! String || tex.isEmpty) continue;
          checked++;
          final error = Math.tex(tex).parseError;
          if (error != null) broken.add('$id: $tex\n    ${error.message}');
        }
      }
    }

    expect(checked, greaterThan(2000), reason: 'the whole bank was read');
    expect(
      broken,
      isEmpty,
      reason:
          '${broken.length} of $checked would show a parser error instead of '
          'the question:\n${broken.take(20).join('\n')}',
    );
  });
}
