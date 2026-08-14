import 'package:flutter_test/flutter_test.dart';
import 'package:mini_hub/content/fraction.dart';

void main() {
  group('parseTex', () {
    test('reads a plain fraction, signed or not', () {
      expect(Fraction.parseTex(r'\frac{3}{4}'), const Fraction(3, 4));
      expect(Fraction.parseTex(r'-\frac{3}{4}'), const Fraction(-3, 4));
    });

    test('reads a mixed number as its improper form', () {
      expect(Fraction.parseTex(r'35\frac{1}{16}'), const Fraction(561, 16));
    });

    test('a negative mixed number subtracts its fractional part', () {
      // -2\frac{1}{2} is -5/2. Adding instead would give -3/2, which is a
      // different number and would mark a correct answer wrong.
      expect(Fraction.parseTex(r'-2\frac{1}{2}'), const Fraction(-5, 2));
    });

    test('a whole number is a fraction over one', () {
      expect(Fraction.parseTex('7'), const Fraction(7, 1));
    });

    test('rejects a zero denominator rather than building one', () {
      expect(Fraction.parseTex(r'\frac{1}{0}'), isNull);
      expect(Fraction.parseTex(r'1\frac{1}{0}'), isNull);
    });

    test('rejects what is not a fraction, whatever it evaluates to', () {
      expect(Fraction.parseTex('0.75'), isNull);
      expect(Fraction.parseTex(r'\frac{1}{2}+\frac{1}{4}'), isNull);
      expect(Fraction.parseTex(''), isNull);
    });
  });

  test('equality is by value, not by form', () {
    expect(const Fraction(1, 2), const Fraction(2, 4));
    expect(const Fraction(1, 2).hashCode, const Fraction(2, 4).hashCode);
    expect(const Fraction(1, 2), isNot(const Fraction(1, 3)));
  });

  test('isReduced is about the pair as written', () {
    expect(const Fraction(1, 2).isReduced, isTrue);
    expect(const Fraction(2, 4).isReduced, isFalse);
    expect(const Fraction(-3, 9).isReduced, isFalse);
  });

  test('reduced puts a fraction in lowest terms, sign kept', () {
    expect(const Fraction(2, 4).reduced, const Fraction(1, 2));
    expect(const Fraction(-6, 8).reduced.numerator, -3);
    expect(const Fraction(-6, 8).reduced.denominator, 4);
  });
}
