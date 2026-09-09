import 'package:flutter_test/flutter_test.dart';
import 'package:mini_hub/content/answer.dart';

void main() {
  group('ChoiceAnswer', () {
    const answer = ChoiceAnswer(correct: 2, count: 4, display: r'(2)\ L_1L_2');

    test('accepts the right option number', () {
      expect(answer.accepts('2'), isTrue);
    });

    test('rejects another option, a non-integer, and nonsense', () {
      expect(answer.accepts('3'), isFalse);
      expect(answer.accepts('2.5'), isFalse);
      expect(answer.accepts(r'\frac{}{}'), isFalse);
    });

    test('reveals the option content, not a bare index', () {
      expect(answer.display, r'(2)\ L_1L_2');
      expect(const ChoiceAnswer(correct: 1, count: 3).display, '1');
    });

    test('tells the student the range', () {
      expect(answer.inputHint, 'Enter the number of your choice (1–4)');
    });

    test('deserializes through the discriminator', () {
      final parsed = Answer.fromJson({
        'type': 'choice',
        'correct': 3,
        'count': 4,
      });
      expect(parsed, isA<ChoiceAnswer>());
      expect(parsed.accepts('3'), isTrue);
      expect(parsed.kind, QuestionType.choice);
    });
  });
}
