import 'package:flutter_test/flutter_test.dart';
import 'package:mini_hub/math/tex_answer.dart';
import 'package:mini_hub/models/answer.dart';
import 'package:mini_hub/models/question.dart';

void main() {
  group('NumericAnswer', () {
    test('accepts an equivalent form, not just the stored decimal', () {
      // The key stores 1/3 as a truncated decimal; a student typing the exact
      // fraction must still be marked correct.
      const a = NumericAnswer(value: 0.3333333333);
      expect(a.accepts(r'\frac{1}{3}'), isTrue);
      expect(a.accepts('0.3333333333'), isTrue);
      expect(a.accepts('0.33'), isFalse);
    });

    test('accepts a mixed number', () {
      const a = NumericAnswer(value: 4.25);
      expect(a.accepts(r'4\frac{1}{4}'), isTrue);
      expect(a.accepts('4.25'), isTrue);
    });

    test('percent answers grade either way round', () {
      // The manual keys percentages inconsistently — 7 in one set, .07 in
      // another — so both readings have to be accepted.
      const a = NumericAnswer(value: 2.5, unit: '%');
      expect(a.accepts('2.5'), isTrue);
      expect(a.accepts('0.025'), isTrue);
      expect(a.accepts('25'), isFalse);
    });

    test('rejects unparsable input rather than throwing', () {
      const a = NumericAnswer(value: 5);
      expect(a.accepts(''), isFalse);
      expect(a.accepts(r'\frac{'), isFalse);
    });
  });

  group('ApproxAnswer', () {
    test('accepts anything inside the printed band', () {
      const a = ApproxAnswer(low: 50805, high: 56154);
      expect(a.accepts('53480'), isTrue);
      expect(a.accepts('50805'), isTrue, reason: 'the bounds are inclusive');
      expect(a.accepts('56154'), isTrue);
      expect(a.accepts('50804'), isFalse, reason: 'outside the rule as well');
      expect(a.accepts('60000'), isFalse);
    });

    test('uses the printed bounds even where they miss the ±5% rule', () {
      // The book rounds bounds to whole numbers, so 176-194 around 185 is only
      // ±4.9% and 24-28 around 26 is ±7.7%. Grading follows the printed band
      // either way, so a student is marked exactly as the answer key marks.
      expect(const ApproxAnswer(low: 176, high: 194).accepts('175.8'), isFalse);
      expect(const ApproxAnswer(low: 24, high: 28).accepts('28'), isTrue);
      expect(const ApproxAnswer(low: 24, high: 28).accepts('23'), isFalse);
    });

    test('tells the student it is graded on a range', () {
      const a = ApproxAnswer(low: 1, high: 2);
      expect(a.inputHint, isNotNull);
      expect(a.inputVariables, isEmpty);
    });
  });

  group('input configuration', () {
    test('only complex answers need a symbol on the keyboard', () {
      expect(const NumericAnswer(value: 5).inputVariables, isEmpty);
      expect(const ComplexAnswer(real: 16, imaginary: 16).inputVariables, [
        'i',
      ]);
    });

    test('a plain numeric answer needs no hint', () {
      expect(const NumericAnswer(value: 5).inputHint, isNull);
    });
  });

  group('ComplexAnswer', () {
    const a = ComplexAnswer(real: 16, imaginary: 16, display: '16+16i');

    test('accepts the standard forms', () {
      expect(a.accepts('16+16i'), isTrue);
      expect(a.accepts('16 + 16i'), isTrue);
      expect(a.accepts('16+16 i'), isTrue);
    });

    test('rejects a wrong sign or magnitude', () {
      expect(a.accepts('16-16i'), isFalse);
      expect(a.accepts('16+15i'), isFalse);
      expect(a.accepts('16'), isFalse, reason: 'missing the imaginary part');
      expect(a.accepts('32'), isFalse);
    });

    test('display round-trips', () {
      expect(a.display, '16+16i');
      expect(const ComplexAnswer(real: 3, imaginary: -4).display, '3-4i');
    });
  });

  group('FractionAnswer', () {
    // 6/25, printed by the manual as a plain fraction.
    const sixth = FractionAnswer(numerator: 6, denominator: 25);

    test('requires the reduced form, not merely the right value', () {
      expect(sixth.accepts(r'\frac{6}{25}'), isTrue);
      expect(
        sixth.accepts(r'\frac{12}{50}'),
        isFalse,
        reason: 'same value, not reduced — a real grader marks this wrong',
      );
      expect(sixth.accepts(r'\frac{24}{100}'), isFalse);
    });

    test('rejects a decimal, whatever it evaluates to', () {
      // The question asked for a fraction; 0.24 is a different answer.
      expect(sixth.accepts('0.24'), isFalse);
    });

    test('rejects the wrong value in reduced form', () {
      expect(sixth.accepts(r'\frac{7}{25}'), isFalse);
    });

    group('mixed numbers', () {
      // 35 1/16, held as the improper 561/16.
      const mixed = FractionAnswer(
        numerator: 561,
        denominator: 16,
        display: r'35\frac{1}{16}',
      );

      test('accepts either the mixed or the improper form', () {
        expect(mixed.accepts(r'35\frac{1}{16}'), isTrue);
        expect(mixed.accepts(r'\frac{561}{16}'), isTrue);
      });

      test('still requires the fractional part reduced', () {
        expect(mixed.accepts(r'35\frac{2}{32}'), isFalse);
        expect(mixed.accepts(r'\frac{1122}{32}'), isFalse);
      });

      test('rejects a wrong whole part', () {
        expect(mixed.accepts(r'34\frac{1}{16}'), isFalse);
      });
    });

    test('handles negatives, subtracting the fractional part', () {
      const negative = FractionAnswer(numerator: -7, denominator: 2);
      expect(negative.accepts(r'-3\frac{1}{2}'), isTrue);
      expect(negative.accepts(r'-\frac{7}{2}'), isTrue);
      expect(negative.accepts(r'\frac{7}{2}'), isFalse);
    });

    test('accepts a whole number when the answer is whole', () {
      const four = FractionAnswer(numerator: 4, denominator: 1);
      expect(four.accepts('4'), isTrue);
      expect(four.accepts(r'\frac{4}{1}'), isTrue);
      expect(four.accepts('5'), isFalse);
    });

    test('rejects malformed input rather than throwing', () {
      expect(sixth.accepts(''), isFalse);
      expect(sixth.accepts(r'\frac{6}{0}'), isFalse);
      expect(sixth.accepts(r'\frac{6}'), isFalse);
    });

    test('round-trips through JSON', () {
      final again = Answer.fromJson(sixth.toJson());
      expect(again, isA<FractionAnswer>());
      expect(again.accepts(r'\frac{6}{25}'), isTrue);
      expect(again.accepts(r'\frac{12}{50}'), isFalse);
    });

    group('a course with a different convention', () {
      // The reduction rule belongs to number sense, not to the input box. Any
      // other course reusing the same widget sets its own marking rules on the
      // question, and the widget never knows the difference.
      const lenient = FractionAnswer(
        numerator: 6,
        denominator: 25,
        reduced: false,
      );

      test('accepts an unreduced fraction', () {
        expect(lenient.accepts(r'\frac{12}{50}'), isTrue);
        expect(lenient.accepts(r'\frac{6}{25}'), isTrue);
        expect(
          lenient.accepts(r'\frac{7}{25}'),
          isFalse,
          reason: 'wrong value',
        );
      });

      test('drops the hint that no longer applies', () {
        expect(lenient.inputHint, isNull);
        expect(sixth.inputHint, isNotNull);
      });

      test('survives a round trip, defaulting to strict', () {
        expect(
          (Answer.fromJson(lenient.toJson()) as FractionAnswer).reduced,
          isFalse,
        );
        expect(
          (Answer.fromJson({'type': 'fraction', 'num': 1, 'den': 2})
                  as FractionAnswer)
              .reduced,
          isTrue,
          reason: 'number sense is the default, so strictness is opt-out',
        );
      });
    });
  });

  group('BaseAnswer', () {
    // 15/70 in base 8 is 13/56 = 0.2321…, the manual's answer to 0.1666…₈.
    const a = BaseAnswer(
      value: 13 / 56,
      base: 8,
      display: r'\frac{15}{70}_{8}',
    );

    test('reads the digits in the question\'s base', () {
      expect(a.accepts(r'\frac{15}{70}'), isTrue);
      expect(a.accepts(r'\frac{15}{70}  '), isTrue);
    });

    test('rejects the base-10 reading of the same digits', () {
      // The whole point: 15/70 in base 10 is 0.214, a different number, and it
      // is what the plain evaluator would have computed.
      expect(a.accepts('0.2142857142857143'), isFalse);
      expect(
        const BaseAnswer(value: 15 / 70, base: 8).accepts(r'\frac{15}{70}'),
        isFalse,
      );
    });

    test('rejects digits that do not exist in the base', () {
      // 8 is not a base-8 digit, so this is a typo rather than a number.
      expect(a.accepts(r'\frac{18}{70}'), isFalse);
    });

    test('accepts a whole number', () {
      const twenty = BaseAnswer(value: 16, base: 8);
      expect(twenty.accepts('20'), isTrue, reason: '20 base 8 is 16');
      expect(twenty.accepts('16'), isFalse);
    });

    test('rejects malformed input rather than throwing', () {
      expect(a.accepts(''), isFalse);
      expect(a.accepts(r'\frac{15}{0}'), isFalse);
      expect(a.accepts('15 + 70'), isFalse);
    });

    test('names the base, which the prompt may not', () {
      expect(a.inputHint, contains('8'));
      expect(a.display, r'\frac{15}{70}_{8}');
    });

    test('round-trips through JSON', () {
      final again = Answer.fromJson(a.toJson());
      expect(again, isA<BaseAnswer>());
      expect(again.accepts(r'\frac{15}{70}'), isTrue);
    });
  });

  group('parseComplexTex', () {
    test('handles bare and implicit coefficients', () {
      expect(parseComplexTex('i'), (0.0, 1.0));
      expect(parseComplexTex('-i'), (0.0, -1.0));
      expect(parseComplexTex('5'), (5.0, 0.0));
      expect(parseComplexTex('5i'), (0.0, 5.0));
      expect(parseComplexTex('2-3i'), (2.0, -3.0));
    });

    test('accepts the form math_keyboard actually emits', () {
      // A declared variable comes back as \mathrm{i}, not a bare i.
      expect(parseComplexTex(r'16+16\mathrm{i}'), (16.0, 16.0));
      expect(parseComplexTex(r'\mathrm{i}'), (0.0, 1.0));
      expect(parseComplexTex(r'-\mathrm{i}'), (0.0, -1.0));
      expect(parseComplexTex(r'2-3\imath'), (2.0, -3.0));
    });

    test('returns null for nonsense', () {
      expect(parseComplexTex(''), isNull);
      expect(parseComplexTex('abc'), isNull);
    });
  });

  group('Question deserialization', () {
    test('rejects an answer type it does not know how to grade', () {
      // Grading it as numeric would apply the wrong rule and look like it
      // worked, so the bank fails loudly instead.
      expect(
        () => Question.fromJson({
          'id': 'bh.1.2.1.q1',
          'prompt': '2+2=',
          'answer': {'type': 'multiple-choice', 'answer': 4},
        }),
        throwsFormatException,
      );
    });

    test('reads each richer answer shape', () {
      final approx = Question.fromJson({
        'id': 'a',
        'prompt': 'p',
        'answer': {'type': 'approx', 'low': 1, 'high': 2},
      });
      expect(approx.answer, isA<ApproxAnswer>());

      final complex = Question.fromJson({
        'id': 'b',
        'prompt': r'(1+i)^{9} =',
        'answer': {'type': 'complex', 'real': 16, 'imag': 16},
      });
      expect(complex.answer, isA<ComplexAnswer>());
      expect(complex.answer.accepts('16+16i'), isTrue);
    });

    test('round-trips through JSON', () {
      final q = Question.fromJson({
        'id': 'bh.3.1.10.q27',
        'prompt': r'(1+i)^{9} =',
        'topic': 'complex_numbers',
        'answer': {'type': 'complex', 'real': 16, 'imag': 16},
      });
      final again = Question.fromJson(q.toJson());
      expect(again.answer.accepts('16+16i'), isTrue);
      expect(again.type, 'complex', reason: 'derived from the answer');
      expect(again.topic, 'complex_numbers');
    });
  });
}
