import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// A topic that sets questions teaches how to answer them.
///
/// Nineteen topics shipped a stub — a heading and the line "(appendix entry —
/// no extended lesson in source)" — while setting 501 questions between them.
/// A student opening the lesson for any of those was told nothing at all and
/// then drilled on it.
///
/// A topic may still be lesson-only: seven are, where the manual sets no
/// problems. What is not allowed is questions without a lesson.
void main() {
  /// Prose and worked examples, without the heading that every lesson has.
  int bodyLength(File lesson) => lesson
      .readAsLinesSync()
      .where((line) => line.trim().isNotEmpty && !line.startsWith('#'))
      .join()
      .length;

  test('a topic that asks questions teaches something', () {
    final silent = <String>[];
    var withQuestions = 0;

    for (final directory in Directory(
      'assets/content/number_sense',
    ).listSync().whereType<Directory>()) {
      final lesson = File('${directory.path}/lesson.md');
      final questions = File('${directory.path}/questions.json');
      if (!lesson.existsSync() || !questions.existsSync()) continue;

      final count =
          (jsonDecode(questions.readAsStringSync()) as List<dynamic>).length;
      if (count == 0) continue;
      withQuestions++;

      final body = bodyLength(lesson);
      if (body < 200) {
        silent.add(
          '${directory.path.split(Platform.pathSeparator).last}: '
          '$count questions, $body characters of lesson',
        );
      }
    }

    expect(withQuestions, greaterThan(100), reason: 'the topics were read');
    expect(
      silent,
      isEmpty,
      reason:
          '${silent.length} topics drill what they never taught:\n'
          '${silent.join('\n')}',
    );
  });

  test('no lesson still says it is a placeholder', () {
    final placeholders = <String>[];
    for (final lesson in Directory('assets/content')
        .listSync(recursive: true)
        .whereType<File>()
        .where((f) => f.path.endsWith('lesson.md'))) {
      final text = lesson.readAsStringSync();
      if (text.contains('appendix entry') || text.contains('no extended')) {
        placeholders.add(lesson.parent.path);
      }
    }
    expect(placeholders, isEmpty, reason: placeholders.join('\n'));
  });
}
