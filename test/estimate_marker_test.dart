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
/// Not the converse. Eighteen marked questions are graded exactly, and they are
/// right to be: `22_{9} - 66_{9}` and the count of divisors of 100 have exact
/// answers, so whatever the marker means on those, a band is not it.
///
/// They fall in six sections, and in each one every marked question is typed
/// the same as its unmarked neighbours. Section 2.1.1 is the opposite: there,
/// every marked question is banded but one — which is the one that had lost its
/// marker. That asymmetry is what says the mark means estimation there and
/// something else in the other six.
///
/// The manual's own answer key settles it, and is the reason to stop looking.
/// Its preface says every `(*)` problem is an approximation needing ±5%, which
/// reads as a rule covering all eighteen — but the key does not follow its own
/// preface. Where the mark means a band, the key prints one:
///
///     Problem Set 2.1.1:   27. (*) 972 - 1075     28. (*) 372 - 412
///
/// and where these eighteen live, it prints a single exact value, with no
/// marker and no range:
///
///     Problem Set 2.2.3:    9. 9     24. 55     31. 160
///     Problem Set 3.6.3:   24. 12    26. 84     34. 6
///
/// So the app grades them as the manual grades them. Banding them to match the
/// preface would accept 750 for 748 and 168 for 160, which the key does not.
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
