import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:mini_hub/content/answer.dart';

/// The answer the app reveals must be an answer the app accepts.
///
/// A key can be perfectly self-consistent and still be untypable, and the
/// display is the one form a student is ever shown: if grading rejects it, the
/// app is showing them something it would mark wrong. Every bug of this shape
/// so far — the percent sign that vanished from the reveal, `\pi` the evaluator
/// could not read, the `{i}` the keyboard emits — was invisible to every check
/// that only asked whether the stored value was correct.
///
/// [ApproxAnswer] is excluded: its display is a band ("189992 to 209992"), not
/// a value, and there is nothing to type back.
void main() {
  test('every revealed answer is accepted as an answer', () {
    final rejected = <String>[];
    var checked = 0;

    for (final file
        in Directory('assets/content')
            .listSync(recursive: true)
            .whereType<File>()
            .where((f) => f.path.endsWith('questions.json'))) {
      final questions = jsonDecode(file.readAsStringSync()) as List<dynamic>;
      for (final raw in questions.cast<Map<String, dynamic>>()) {
        final answer = Answer.fromJson(raw['answer'] as Map<String, dynamic>);
        if (answer is ApproxAnswer) continue;
        checked++;
        if (!answer.accepts(answer.display)) {
          rejected.add('${raw['id']}: ${answer.display}');
        }
      }
    }

    expect(checked, greaterThan(2000), reason: 'the bank was not read');
    expect(rejected, isEmpty, reason: '${rejected.length} untypable answers');
  });
}
