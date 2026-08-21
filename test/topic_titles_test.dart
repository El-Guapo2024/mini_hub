import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// A topic's title is the only name a student ever sees for it — in the list,
/// and in the bar above the lesson. Fifteen of them named a different subject
/// entirely: the derivatives topic was called "Calculus (Limits)", the sets
/// topic "Probability (Basic)", and Celsius to Fahrenheit "Division (Simple)".
///
/// Held to the topic's own folder name, which is derived from the manual's
/// section heading and so says what the topic actually is. A title is allowed
/// to read better than the folder — several deliberately do — but it has to be
/// about the same thing.
void main() {
  /// Topics whose title is the formula itself, written in symbols. `a × a/b
  /// Trick` shares no word with `a_times_a_b_trick` and is the better name:
  /// the slug spells out what the title can simply show.
  const symbolic = {
    'a_over_b_minus_na_minus_1_over_nb_minus_1',
    'a_over_b_minus_na_minus_1_over_nb_plus_1',
    'a_over_b_plus_b_over_a_trick',
    'a_times_a_b_trick',
    'n_squared_plus_n_equals_n_plus_1_squared_minus_n_plus_1',
  };

  /// Words that carry the subject, ignoring the ones every title shares.
  Set<String> subjectWords(String text) =>
      RegExp(r'[a-z]+')
          .allMatches(text.toLowerCase())
          .map((m) => m.group(0)!)
          .where((word) => word.length > 2)
          .toSet()
        ..removeAll(const {
          'the',
          'and',
          'for',
          'with',
          'between',
          'trick',
          'rule',
          'rules',
          'basic',
          'simple',
          'advanced',
        });

  test('a topic is named for what it teaches', () {
    final wrong = <String>[];
    var checked = 0;

    for (final directory
        in Directory('assets/content/number_sense').listSync().whereType<Directory>()) {
      final file = File('${directory.path}/topic.yml');
      if (!file.existsSync()) continue;

      final title = RegExp(
        r'^title:\s*(.+)$',
        multiLine: true,
      ).firstMatch(file.readAsStringSync())?.group(1)?.trim();
      if (title == null) continue;

      checked++;
      final slug = directory.path.split(Platform.pathSeparator).last;
      if (symbolic.contains(slug)) continue;

      // Matched on a stem rather than the whole word, so "Logarithms" counts
      // as naming `log_rules` and "Trigonometric" as naming `trig`.
      final inTitle = subjectWords(title);
      final inSlug = subjectWords(slug.replaceAll('_', ' '));
      final about = inTitle.any(
        (a) => inSlug.any(
          (b) =>
              a.startsWith(b.substring(0, b.length.clamp(0, 4))) ||
              b.startsWith(a.substring(0, a.length.clamp(0, 4))),
        ),
      );
      if (!about) wrong.add('$slug: "$title"');
    }

    expect(checked, greaterThan(100), reason: 'the topics were read');
    expect(
      wrong,
      isEmpty,
      reason:
          '${wrong.length} topics are named for something else:\n'
          '${wrong.join('\n')}',
    );
  });
}
