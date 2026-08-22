import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// A sequence a question calls Fibonacci must be one.
///
/// Two topics drill summing an arbitrary Fibonacci sequence, and both print the
/// sequence into the prompt: `1 + 1 + 2 + 3 + 5 + 8 + \ldots + 34 + 55 =`. Each
/// term after the first two is the sum of the two before it, so the printed
/// terms are checkable — and one was wrong.
///
/// The manual prints that question's eighth term as 24. It cannot be: 13 + 21
/// is 34, and nothing plus 24 is 55. Text extraction and a vision read of the
/// page agree the book says 24, so the typo is the book's, and the book's own
/// key of 133 was computed from it. What shipped was worse than either — the
/// book's broken prompt beside a key of 143 derived from the sequence the book
/// meant. A student adding up what was printed got 133 and was marked wrong.
void main() {
  /// A sum written out term by term: numbers joined by `+`, an optional
  /// elision, and nothing else. The worded questions are read by [named].
  final spelledOut = RegExp(r'^[\d\s+=]+$');
  final elision = RegExp(r'\\ldots|\\cdots');

  /// The comma-separated run that follows the word "sequence" in a worded
  /// prompt: `the Fibonacci sequence 0, 3, 3, 6, 9, 15, \ldots`. Anchored on
  /// the word so the ordinal in "the first ten terms" is never read as a term.
  final named = RegExp(r'[Ss]equence\s+((?:-?\d+\s*,\s*)+)');

  List<int> numbers(String s) =>
      RegExp(r'-?\d+').allMatches(s).map((m) => int.parse(m[0]!)).toList();

  test('every printed Fibonacci sequence obeys its own recurrence', () {
    final broken = <String>[];
    var spelled = 0;
    var worded = 0;

    for (final file
        in Directory('assets/content')
            .listSync(recursive: true)
            .whereType<File>()
            .where((f) => f.path.endsWith('questions.json'))) {
      if (!file.path.contains('fibonacci')) continue;
      final questions = jsonDecode(file.readAsStringSync()) as List<dynamic>;

      for (final raw in questions.cast<Map<String, dynamic>>()) {
        final prompt = raw['prompt'] as String;
        final parts = prompt.split(elision);

        List<int> leading;
        List<int> trailing;

        if (parts.every((p) => spelledOut.hasMatch(p))) {
          leading = numbers(parts.first);
          trailing = parts.length > 1 ? numbers(parts[1]) : const [];
          spelled++;
        } else {
          final match = named.firstMatch(prompt);
          if (match == null) continue;
          leading = numbers(match[1]!);
          // A worded prompt names a prefix and stops; there is nothing printed
          // past the elision to walk towards.
          trailing = const [];
          worded++;
        }

        if (leading.length < 3) continue;

        // The visible opening must already be a Fibonacci run.
        for (var i = 2; i < leading.length; i++) {
          if (leading[i] != leading[i - 1] + leading[i - 2]) {
            broken.add('${raw['id']}: $prompt — ${leading[i]} breaks the run');
          }
        }

        // And continuing the run must reach every term printed after the
        // elision, or the elided middle hides a term that does not fit.
        if (trailing.isEmpty) continue;
        var a = leading[leading.length - 2];
        var b = leading.last;
        final reached = <int>{};
        for (var step = 0; step < 200 && b <= trailing.last; step++) {
          final next = a + b;
          reached.add(next);
          a = b;
          b = next;
        }
        for (final term in trailing) {
          if (!reached.contains(term)) {
            broken.add('${raw['id']}: $prompt — $term is not in the sequence');
          }
        }
      }
    }

    expect(spelled, greaterThan(3), reason: 'the spelled-out sums were found');
    expect(worded, greaterThan(10), reason: 'the worded sequences were found');
    expect(broken, isEmpty, reason: '\n${broken.join('\n')}');
  });
}
