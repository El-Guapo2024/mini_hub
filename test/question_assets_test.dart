import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:mini_hub/content/answer.dart';
import 'package:mini_hub/content/question.dart';
import 'package:yaml/yaml.dart';

/// Guards the generated bank against the failure that would otherwise only show
/// up on a device: a question that will not parse, or a tag pointing at nothing.
/// Both render as an error inside an otherwise healthy lesson, which is easy to
/// ship and easy to miss.
void main() {
  // Both content sources, since either can be the one a build ships.
  final topics = ['assets/content', 'assets/sample']
      .map(Directory.new)
      .expand((root) => root.listSync().whereType<Directory>())
      .expand((course) => course.listSync().whereType<Directory>())
      .where((d) => File('${d.path}/questions.json').existsSync())
      .toList();

  test('there are topics with questions to check', () {
    expect(topics, isNotEmpty, reason: 'run tools/build_questions.py');
  });

  test('every question parses into the model the app renders', () {
    final failures = <String>[];
    var count = 0;

    for (final dir in topics) {
      final raw = File('${dir.path}/questions.json').readAsStringSync();
      for (final row in jsonDecode(raw) as List<dynamic>) {
        try {
          final question = Question.fromJson(row as Map<String, dynamic>);
          // A question whose answer nothing can satisfy is worse than a missing
          // one: the student cannot tell it is broken.
          expect(question.answer, isA<Answer>());
          expect(question.prompt, isNotEmpty);
          expect(question.topic, dir.path.split('/').last);
          expect(
            row['type'],
            isNull,
            reason: 'type is the answer\'s, not a field',
          );
          count++;
        } on Object catch (e) {
          failures.add('${dir.path}: $row\n  $e');
        }
      }
    }

    expect(failures, isEmpty);
    expect(count, greaterThan(0));
  });

  test('every question tag in a lesson resolves to a question', () {
    final tag = RegExp(r'\[\[question:([\w.\-]+)\s*\]\]');
    final dangling = <String>[];

    for (final dir in topics) {
      final ids =
          (jsonDecode(File('${dir.path}/questions.json').readAsStringSync())
                  as List<dynamic>)
              .map((q) => (q as Map<String, dynamic>)['id'] as String)
              .toSet();

      final lesson = File('${dir.path}/lesson.md');
      if (!lesson.existsSync()) continue;
      for (final match in tag.allMatches(lesson.readAsStringSync())) {
        if (!ids.contains(match[1])) dangling.add('${dir.path}: ${match[1]}');
      }
    }

    expect(
      dangling,
      isEmpty,
      reason: 'these tags render as "missing question"',
    );
  });

  test('questionIds matches the questions file', () {
    // TopicScreen treats an empty questionIds as "this lesson has no questions"
    // and never opens the file, so a mismatch silently hides the whole set.
    final mismatched = <String>[];

    for (final dir in topics) {
      final yaml = loadYaml(File('${dir.path}/topic.yml').readAsStringSync());
      final declared = (yaml['questionIds'] as YamlList?)?.cast<String>() ?? [];
      final actual =
          (jsonDecode(File('${dir.path}/questions.json').readAsStringSync())
                  as List<dynamic>)
              .map((q) => (q as Map<String, dynamic>)['id'] as String)
              .toList();

      if (declared.length != actual.length ||
          !declared.toSet().containsAll(actual)) {
        mismatched.add(
          '${dir.path}: ${declared.length} declared, '
          '${actual.length} in questions.json',
        );
      }
    }

    expect(mismatched, isEmpty);
  });

  test('ids are unique across the whole bank', () {
    // Attempts key off the id, so a duplicate would merge two questions'
    // history into one.
    final seen = <String, String>{};
    final clashes = <String>[];

    for (final dir in topics) {
      final raw = File('${dir.path}/questions.json').readAsStringSync();
      for (final row in jsonDecode(raw) as List<dynamic>) {
        final id = (row as Map<String, dynamic>)['id'] as String;
        final previous = seen[id];
        if (previous != null) clashes.add('$id in $previous and ${dir.path}');
        seen[id] = dir.path;
      }
    }

    expect(clashes, isEmpty);
  });
}
