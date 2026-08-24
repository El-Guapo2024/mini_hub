import 'package:flutter_test/flutter_test.dart';
import 'package:mini_hub/content/answer.dart';
import 'package:mini_hub/content/fraction.dart';
import 'package:mini_hub/math/tex_answer.dart';

/// What the math keyboard actually emits, as opposed to what an answer key is
/// written as. Every case here was once graded wrong while being right.
void main() {
  group('sizing markup carries no value', () {
    test('auto-sized brackets evaluate as ordinary ones', () {
      expect(evaluateTex(r'\left(1+2\right)'), 3.0);
      expect(evaluateTex(r'3\cdot\left(4+5\right)'), 27.0);
    });

    test('a numeric answer accepts a bracketed input', () {
      expect(
        const NumericAnswer(value: 27).accepts(r'\left(4+5\right)\cdot3'),
        isTrue,
      );
    });

    test('an estimate accepts a bracketed input inside its band', () {
      expect(
        const ApproxAnswer(low: 26, high: 28).accepts(r'\left(4+5\right)3'),
        isTrue,
      );
    });
  });

  group('a fraction is a fraction however it is sized', () {
    test('dfrac evaluates as frac', () {
      expect(evaluateTex(r'\dfrac{1}{2}'), 0.5);
      expect(evaluateTex(r'\tfrac{1}{2}'), 0.5);
    });

    test('a mixed number expands whichever form it uses', () {
      expect(evaluateTex(r'2\frac{1}{2}'), 2.5);
      expect(evaluateTex(r'2\dfrac{1}{2}'), 2.5);
    });
  });

  group('a minus typed into the numerator is the same number', () {
    test('Fraction reads the sign from either place', () {
      expect(Fraction.parseTex(r'\frac{-3}{4}'), const Fraction(-3, 4));
      expect(Fraction.parseTex(r'-\frac{3}{4}'), const Fraction(-3, 4));
      expect(Fraction.parseTex(r'\frac{3}{-4}'), const Fraction(-3, 4));
    });

    test('a fraction answer accepts it', () {
      const answer = FractionAnswer(value: Fraction(-3, 4));
      expect(answer.accepts(r'\frac{-3}{4}'), isTrue);
      expect(answer.accepts(r'-\frac{3}{4}'), isTrue);
    });

    test('a base answer accepts it, and two minuses cancel', () {
      const answer = BaseAnswer(value: -0.5, base: 8);
      expect(answer.accepts(r'\frac{-4}{10}'), isTrue);
      expect(answer.accepts(r'-\frac{4}{10}'), isTrue);
      expect(
        const BaseAnswer(value: 0.5, base: 8).accepts(r'-\frac{-4}{10}'),
        isTrue,
      );
    });
  });

  group('grouping inside a complex term is not a term boundary', () {
    test('a fraction with a sum in its numerator survives the split', () {
      expect(parseComplexTex(r'\frac{2+2}{2}+16i'), (2.0, 16.0));
    });

    test('a bracketed exponent survives the split', () {
      expect(parseComplexTex(r'2^{-3}i'), (0.0, 0.125));
    });

    test('parenthesised grouping survives the split', () {
      expect(parseComplexTex(r'\left(1+3\right)+2i'), (4.0, 2.0));
    });

    test('a complex answer accepts an unsimplified equivalent', () {
      expect(
        const ComplexAnswer(
          real: 2,
          imaginary: 16,
        ).accepts(r'\frac{2+2}{2}+16i'),
        isTrue,
      );
    });

    test('a real term may be written after the imaginary one', () {
      // TeXParser cannot read a leading `+`, so these were rejected outright.
      expect(parseComplexTex('16i+3'), (3.0, 16.0));
      expect(parseComplexTex('+3+16i'), (3.0, 16.0));
      expect(parseComplexTex(r'16i+\frac{1}{2}'), (0.5, 16.0));
    });

    test('a term that is only a sign is a unit', () {
      expect(parseComplexTex('-i'), (0.0, -1.0));
      expect(parseComplexTex('3-i'), (3.0, -1.0));
      expect(parseComplexTex('3+i'), (3.0, 1.0));
    });

    test('unbalanced grouping is still rejected', () {
      expect(parseComplexTex(r'\frac{2+2}{2'), isNull);
      expect(parseComplexTex(r'1+2)i'), isNull);
    });
  });

  group('what was already right stays right', () {
    test('the ordinary complex forms still parse', () {
      expect(parseComplexTex('16+16i'), (16.0, 16.0));
      expect(parseComplexTex('16-16i'), (16.0, -16.0));
      expect(parseComplexTex('16i'), (0.0, 16.0));
      expect(parseComplexTex('16'), (16.0, 0.0));
      expect(parseComplexTex('i'), (0.0, 1.0));
    });

    test('a wrong answer is still wrong', () {
      expect(
        const NumericAnswer(value: 27).accepts(r'\left(4+5\right)\cdot2'),
        isFalse,
      );
      expect(
        const FractionAnswer(value: Fraction(-3, 4)).accepts(r'\frac{3}{4}'),
        isFalse,
      );
    });
  });
}
