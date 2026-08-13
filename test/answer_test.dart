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
    test('reads a bare numeric answer, the pre-existing shape', () {
      final q = Question.fromJson({
        'id': 'bh.1.2.1.q1',
        'type': 'numerical',
        'prompt': '2+2=',
        'answer': 4,
      });
      expect(q.answer, isA<NumericAnswer>());
      expect(q.answer.accepts('4'), isTrue);
    });

    test('reads each richer answer shape', () {
      final approx = Question.fromJson({
        'id': 'a',
        'type': 'numerical',
        'prompt': 'p',
        'answer': {'type': 'approx', 'low': 1, 'high': 2},
      });
      expect(approx.answer, isA<ApproxAnswer>());

      final complex = Question.fromJson({
        'id': 'b',
        'type': 'numerical',
        'prompt': r'(1+i)^{9} =',
        'answer': {'type': 'complex', 'real': 16, 'imag': 16},
      });
      expect(complex.answer, isA<ComplexAnswer>());
      expect(complex.answer.accepts('16+16i'), isTrue);
    });

    test('round-trips through JSON', () {
      final q = Question.fromJson({
        'id': 'bh.3.1.10.q27',
        'type': 'numerical',
        'prompt': r'(1+i)^{9} =',
        'answer': {'type': 'complex', 'real': 16, 'imag': 16},
        'derived': true,
      });
      final again = Question.fromJson(q.toJson());
      expect(again.answer.accepts('16+16i'), isTrue);
      expect(again.derived, isTrue);
    });
  });
}
