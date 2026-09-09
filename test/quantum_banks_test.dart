import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:mini_hub/content/answer.dart';
import 'package:mini_hub/content/question.dart';
import 'package:yaml/yaml.dart';

/// Every quantum question bank parses, every listed id resolves to a question
/// whose stored answer grades itself correct — a bank whose own key fails its
/// own grader would mark every student wrong.
void main() {
  final topics = Directory(
    'assets/content/quantum',
  ).listSync().whereType<Directory>();

  for (final dir in topics) {
    final name = dir.path.split('/').last;
    test('$name: ids resolve and keys grade correct', () {
      final yaml = loadYaml(File('${dir.path}/topic.yml').readAsStringSync());
      final ids = [for (final id in yaml['questionIds'] ?? []) id as String];
      final file = File('${dir.path}/questions.json');
      if (ids.isEmpty) {
        expect(
          file.existsSync(),
          isFalse,
          reason: 'a bank exists but no ids point at it',
        );
        return;
      }
      final qs = (jsonDecode(file.readAsStringSync()) as List)
          .cast<Map<String, dynamic>>()
          .map(Question.fromJson)
          .toList();
      expect(qs.map((q) => q.id.value), ids);
      for (final q in qs) {
        expect(q.topic.value, name);
        // A choice answer reveals the option's content, which is not what a
        // student types — its typable form is the index.
        final key = switch (q.answer) {
          ChoiceAnswer(:final correct) => '$correct',
          // An estimate reveals a band; type its midpoint the way a student
          // would, in scientific notation, proving that entry path works.
          ApproxAnswer(:final low, :final high) => _scientific(
            (low + high) / 2,
          ),
          final a => a.display,
        };
        expect(
          q.answer.accepts(key),
          isTrue,
          reason: '${q.id.value}: its own key fails its grader',
        );
      }
    });
  }
}

/// A value as the keyboard's scientific notation, e.g. `2.6\\cdot10^{18}`.
String _scientific(double v) {
  final exponent = v.abs() >= 1
      ? v.abs().toStringAsExponential().split('e+').last
      : '-${v.abs().toStringAsExponential().split('e-').last}';
  final mantissa = v / double.parse('1e$exponent');
  return '$mantissa\\cdot10^{$exponent}';
}
