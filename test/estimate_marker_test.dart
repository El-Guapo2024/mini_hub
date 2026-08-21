import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:mini_hub/content/answer.dart';

/// A question graded to a band says so.
///
/// The manual marks an estimation problem `(*)`, and the app grades one to a
/// band rather than a value. A banded question without the marker asks for an
/// exact answer it will not insist on — one estimate had lost its marker at
/// extraction, which is how this got written.
///
/// Not the converse. Twelve marked questions are graded exactly, and they are
/// right to be: `22_{9} - 66_{9}` and the count of divisors of 100 have exact
/// answers, so whatever the marker means on those, a band is not it.
void main() {
  final files = Directory('assets/content')
      .listSync(recursive: true)
      .whereType<File>()
      .where((f) => f.path.endsWith('questions.json'));

  test('a question graded to a band is marked as one', () {
    final unmarked = <String>[];
    var estimates = 0;

    for (final file in files) {
      final questions = jsonDecode(file.readAsStringSync()) as List<dynamic>;
      for (final raw in questions.cast<Map<String, dynamic>>()) {
        final prompt = raw['prompt'] as String;
        final answer = Answer.fromJson(raw['answer'] as Map<String, dynamic>);
        final marked = prompt.trimLeft().startsWith('(*)');
        final banded = answer is ApproxAnswer;

        if (banded) estimates++;
        if (banded && !marked) unmarked.add('${raw['id']}: $prompt');
      }
    }

    expect(estimates, greaterThan(200), reason: 'the estimates were found');
    expect(
      unmarked,
      isEmpty,
      reason: 'graded to a band without saying so:\n${unmarked.join('\n')}',
    );
  });

  test('every band holds the answer it is a band for', () {
    for (final file in files) {
      final questions = jsonDecode(file.readAsStringSync()) as List<dynamic>;
      for (final raw in questions.cast<Map<String, dynamic>>()) {
        final answer = Answer.fromJson(raw['answer'] as Map<String, dynamic>);
        if (answer is! ApproxAnswer) continue;
        // Inverted, a band accepts nothing at all: the question could never be
        // got right, by anyone, however well they estimated.
        expect(
          answer.low,
          lessThanOrEqualTo(answer.high),
          reason: '${raw['id']} has a band nothing falls inside',
        );
      }
    }
  });
}
