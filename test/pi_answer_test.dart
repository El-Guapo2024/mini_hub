import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:math_keyboard/math_keyboard.dart';
import 'package:mini_hub/content/answer.dart';
import 'package:mini_hub/content/fraction.dart';
import 'package:mini_hub/math/tex_answer.dart';

/// Two questions in the bank print their answer with pi, and pi was the one
/// thing the evaluator could not read: `144\pi` — the answer the app itself
/// reveals — evaluated to null and was marked wrong. The keyboard had no pi
/// key either, so the only way to answer was to type nine significant figures
/// of 452.3893421169302.
void main() {
  test('pi evaluates in the forms it can be written', () {
    const pi = 3.141592653589793;
    expect(evaluateTex(r'\pi'), closeTo(pi, 1e-12));
    expect(evaluateTex(r'144\pi'), closeTo(144 * pi, 1e-9));
    // Implicit multiplication has to survive the substitution: the constant is
    // parenthesised so the coefficient multiplies all of it.
    expect(evaluateTex(r'2\pi'), closeTo(2 * pi, 1e-12));
    expect(evaluateTex(r'\frac{\pi}{2}'), closeTo(pi / 2, 1e-12));
    // As the keyboard emits a declared variable.
    expect(evaluateTex(r'\mathrm{\pi}'), closeTo(pi, 1e-12));
  });

  test('a pi answer is typable on the keyboard and grades', () {
    const answer = NumericAnswer(
      value: 452.3893421169302,
      display: r'144\pi',
    );
    expect(answer.inputVariables, [r'\pi'], reason: 'the keyboard offers pi');

    // Exactly what the variable button inserts.
    final controller = MathFieldEditingController();
    for (final character in '144'.split('')) {
      controller.addLeaf(character);
    }
    controller.addLeaf(r'{\pi}');

    expect(answer.accepts(controller.currentEditingValue()), isTrue);
    expect(answer.accepts(r'144\pi'), isTrue);
    // The decimal still works for a student who would rather write it.
    expect(answer.accepts('452.3893421169302'), isTrue);
    expect(answer.accepts(r'143\pi'), isFalse);
  });

  test('only answers written with pi ask for the key', () {
    const plain = NumericAnswer(value: 5);
    expect(plain.inputVariables, isEmpty);
  });

  test('any answer shape written with pi asks for the key', () {
    // Decided on the base type, so a shape that starts printing pi is typable
    // without anyone remembering to override it.
    const fraction = FractionAnswer(
      value: Fraction(1, 2),
      display: r'\frac{\pi}{2}',
    );
    expect(fraction.inputVariables, contains(r'\pi'));

    // A complex answer keeps the key it already needed.
    const complex = ComplexAnswer(real: 0, imaginary: 1, display: r'\pi i');
    expect(complex.inputVariables, containsAll([r'\pi', 'i']));

    const plainComplex = ComplexAnswer(real: 16, imaginary: 16);
    expect(plainComplex.inputVariables, ['i']);
  });

  test('every pi answer in the bank accepts its own printed form', () {
    final files = Directory('assets/content')
        .listSync(recursive: true)
        .whereType<File>()
        .where((f) => f.path.endsWith('questions.json'));

    var checked = 0;
    for (final file in files) {
      final questions = jsonDecode(file.readAsStringSync()) as List<dynamic>;
      for (final raw in questions.cast<Map<String, dynamic>>()) {
        final answer = Answer.fromJson(
          raw['answer'] as Map<String, dynamic>,
        );
        if (!answer.display.contains(r'\pi')) continue;
        checked++;
        expect(
          answer.accepts(answer.display),
          isTrue,
          reason: '${raw['id']} does not accept the answer it reveals',
        );
      }
    }
    expect(checked, greaterThan(0), reason: 'the bank still has pi answers');
  });
}
