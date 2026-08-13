import 'package:flutter_test/flutter_test.dart';
import 'package:mini_hub/math/tex_answer.dart';

void main() {
  test('expands mixed numbers', () {
    expect(expandMixedNumbers(r'2\frac{1}{2}'), r'(2+\frac{1}{2})');
    expect(
      expandMixedNumbers(r'1\frac{1}{3}+2\frac{1}{6}'),
      r'(1+\frac{1}{3})+(2+\frac{1}{6})',
    );
  });

  test('leaves plain fractions alone', () {
    expect(expandMixedNumbers(r'\frac{3}{4}'), r'\frac{3}{4}');
  });

  test('handles nested fractions', () {
    expect(
      expandMixedNumbers(r'2\frac{\frac{1}{2}}{3}'),
      r'(2+\frac{\frac{1}{2}}{3})',
    );
  });

  test('evaluates equivalent notations', () {
    expect(evaluateTex(r'3.5'), closeTo(3.5, 1e-9));
    expect(evaluateTex(r'\frac{7}{2}'), closeTo(3.5, 1e-9));
    expect(evaluateTex(r'3\frac{1}{2}'), closeTo(3.5, 1e-9));
    expect(evaluateTex(r'1\frac{1}{3}+2\frac{1}{6}'), closeTo(3.5, 1e-9));
  });

  test('returns null on garbage and empty', () {
    expect(evaluateTex(''), isNull);
    expect(evaluateTex(r'\frac{1}{'), isNull);
  });
}
