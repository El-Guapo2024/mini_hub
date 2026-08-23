import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:math_keyboard/math_keyboard.dart';
import 'package:mini_hub/content/answer.dart';

/// An answer that cannot be typed cannot be got right.
///
/// The keyboard offers digits, operators and templates, plus whatever an answer
/// declares in `inputVariables` — and it inserts a declared variable as
/// `{name}`, braces included, which is not a spelling anything else in the app
/// produces. The one complex question was answered `16+16{i}` and marked wrong,
/// with no other way to type an `i` at all.
///
/// Driven through the controller the buttons themselves use, rather than the
/// tex a person would write, because the difference between those two is where
/// this hid.
void main() {
  /// What the keyboard produces for a run of key presses. A variable button
  /// inserts `{name}`; every other key inserts itself.
  String typed(List<String> presses) {
    final controller = MathFieldEditingController();
    for (final press in presses) {
      controller.addLeaf(press);
    }
    return controller.currentEditingValue();
  }

  test('the imaginary unit is typable', () {
    const answer = ComplexAnswer(real: 16, imaginary: 16);
    expect(answer.inputVariables, contains('i'));

    final input = typed(['1', '6', '+', '1', '6', '{i}']);
    expect(input, '16+16{i}');
    expect(answer.accepts(input), isTrue);

    // The wrong sign is still wrong.
    expect(answer.accepts(typed(['1', '6', '-', '1', '6', '{i}'])), isFalse);
  });

  test('a braced group belonging to a command is left alone', () {
    // `\frac{i}{2}` must keep its numerator rather than lose the brace.
    expect(const NumericAnswer(value: 0.5).accepts(r'\frac{1}{2}'), isTrue);
  });

  test('every answer in the bank is typable in the form it reveals', () {
    var checked = 0;
    final unreachable = <String>[];

    for (final file
        in Directory('assets/content')
            .listSync(recursive: true)
            .whereType<File>()
            .where((f) => f.path.endsWith('questions.json'))) {
      final questions = jsonDecode(file.readAsStringSync()) as List<dynamic>;
      for (final raw in questions.cast<Map<String, dynamic>>()) {
        final answer = Answer.fromJson(raw['answer'] as Map<String, dynamic>);
        // An estimate reveals a range to aim at, not a value to type back.
        if (answer is ApproxAnswer) continue;
        checked++;

        // A base answer prints the base it is written in — `\frac{4}{7}_{8}`
        // — and that subscript says which base, rather than being part of the
        // answer. The digits are what is typed.
        final revealed = answer is BaseAnswer
            ? answer.display.replaceFirst(RegExp(r'_\{\d+\}$'), '')
            : answer.display;

        if (!answer.accepts(revealed)) {
          unreachable.add('${raw['id']}: $revealed');
        }
      }
    }

    expect(checked, greaterThan(2000));
    expect(
      unreachable,
      isEmpty,
      reason:
          '${unreachable.length} answers reject what they reveal:\n'
          '${unreachable.take(20).join('\n')}',
    );
  });
}
