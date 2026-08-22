import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:mini_hub/content/answer.dart';
import 'package:mini_hub/content/fraction.dart';

/// Forms a student may reasonably write, and the answer the app reveals to
/// them. An answer that is not accepted in the form it is shown in is a
/// question that cannot be got right by copying the key.
void main() {
  group('percent', () {
    const answer = NumericAnswer(value: 220, unit: '%');

    test('reveals its sign', () {
      // A bare `%` opens a comment in TeX, so the display rendered as `220`
      // and the sign the question asks for went missing.
      expect(answer.display, r'220\%');
    });

    test('accepts the answer it reveals', () {
      expect(answer.accepts(answer.display), isTrue);
      expect(answer.accepts('220%'), isTrue);
      expect(answer.accepts('220'), isTrue);
      // The decimal reading the blank's own sign invites.
      expect(answer.accepts('2.2'), isTrue);
      expect(answer.accepts('221'), isFalse);
    });

    test('the sign is only dropped where the answer is a percentage', () {
      // `5%` is a twentieth. An answer of 5 that took it would be accepting
      // one a hundred times too small.
      const plain = NumericAnswer(value: 5);
      expect(plain.accepts('5'), isTrue);
      expect(plain.accepts('5%'), isFalse);
    });

    test('every percent answer in the bank accepts what it reveals', () {
      var checked = 0;
      for (final file
          in Directory('assets/content')
              .listSync(recursive: true)
              .whereType<File>()
              .where((f) => f.path.endsWith('questions.json'))) {
        final questions = jsonDecode(file.readAsStringSync()) as List<dynamic>;
        for (final raw in questions.cast<Map<String, dynamic>>()) {
          final json = raw['answer'] as Map<String, dynamic>;
          if (json['unit'] != '%') continue;
          final parsed = Answer.fromJson(json);
          checked++;
          expect(
            parsed.accepts(parsed.display),
            isTrue,
            reason: '${raw['id']} rejects the answer it reveals',
          );
        }
      }
      expect(checked, 25, reason: 'the percent answers were all checked');
    });
  });

  group('fraction', () {
    test('zero is reduced however it is written', () {
      expect(const Fraction(0, 5).isReduced, isTrue);
      const zero = FractionAnswer(value: Fraction(0, 1));
      expect(zero.accepts('0'), isTrue);
      expect(zero.accepts(r'\frac{0}{5}'), isTrue);
    });

    test('lowest terms are still required elsewhere', () {
      const half = FractionAnswer(value: Fraction(1, 2));
      expect(half.accepts(r'\frac{1}{2}'), isTrue);
      expect(half.accepts(r'\frac{2}{4}'), isFalse);
    });
  });

  group('base', () {
    // The three fraction spellings differ only in how large they render.
    const answer = BaseAnswer(value: 4 / 7, base: 8);

    test('reads a fraction however it is spelled', () {
      expect(answer.accepts(r'\frac{4}{7}'), isTrue);
      expect(answer.accepts(r'\dfrac{4}{7}'), isTrue);
      expect(answer.accepts(r'\tfrac{4}{7}'), isTrue);
    });

    test('still reads the digits in the answer base', () {
      const ten = BaseAnswer(value: 8, base: 8);
      expect(ten.accepts('10'), isTrue);
      expect(ten.accepts('8'), isFalse);
    });

    // Every base answer in the bank reveals itself with its base written as a
    // subscript, which is how the manual writes one — and all eleven of them
    // were rejected in exactly that form. A student copying down the answer
    // they had just been shown was marked wrong for it.
    const revealed = BaseAnswer(
      value: 4 / 7,
      base: 8,
      display: r'\frac{4}{7}_{8}',
    );

    test('accepts the answer it reveals, subscript and all', () {
      expect(revealed.accepts(revealed.display), isTrue);
      expect(revealed.accepts(r'\frac{4}{7}_8'), isTrue);
      // And still accepts it written without one.
      expect(revealed.accepts(r'\frac{4}{7}'), isTrue);
    });

    test('a subscript naming another base is a different number', () {
      // Not decoration to be dropped: 4/7 in base 10 is not 4/7 in base 8.
      expect(revealed.accepts(r'\frac{4}{7}_{10}'), isFalse);
      expect(revealed.accepts(r'\frac{4}{7}_{9}'), isFalse);
    });

    test('digits invalid for the base are rejected, subscript or not', () {
      expect(revealed.accepts(r'\frac{8}{7}_{8}'), isFalse);
    });
  });
}
