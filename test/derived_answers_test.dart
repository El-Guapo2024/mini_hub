import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Ninety-nine answers in the key were never printed in the manual. They stand
/// on two independent derivations agreeing, which is a weaker standard than the
/// rest of the bank, and the run that established them read its inputs from a
/// scratch directory that no longer exists — so it cannot be repeated.
///
/// `tools/reconcile_final.py --record` writes down which answers those are.
/// This holds that record to the key, so the weaker standard stays visible and
/// cannot quietly grow.
void main() {
  final source = Directory('content_src/source/bryant_heath');

  test('the derived record matches what the key marks derived', () {
    if (!source.existsSync()) {
      markTestSkipped('source data is not present in this checkout');
      return;
    }

    final answers =
        jsonDecode(File('${source.path}/bh_answers.json').readAsStringSync())
            as Map<String, dynamic>;

    final marked = <String, double>{};
    answers.forEach((section, questions) {
      (questions as Map<String, dynamic>).forEach((number, record) {
        if (record is Map<String, dynamic> && record['derived'] == true) {
          marked['$section#$number'] = (record['answer'] as num).toDouble();
        }
      });
    });

    final recorded =
        (jsonDecode(
                  File(
                    '${source.path}/derived_answers.json',
                  ).readAsStringSync(),
                )
                as Map<String, dynamic>)
            .map((id, value) => MapEntry(id, (value as num).toDouble()));

    expect(
      recorded.keys.toSet(),
      marked.keys.toSet(),
      reason:
          'derived_answers.json is out of step with the key — rerun '
          'tools/reconcile_final.py --record',
    );
    for (final id in marked.keys) {
      expect(recorded[id], marked[id], reason: '$id changed value');
    }
    expect(marked, hasLength(99), reason: 'the weaker standard grew');
  });

  /// Eighty-eight of the ninety-nine are a two-digit product, and a product can
  /// be checked rather than trusted. Doing it here moves them off the weaker
  /// standard for good: they no longer rest on a run that cannot be repeated,
  /// they are recomputed every time the suite runs.
  ///
  /// The remaining eleven are not arithmetic and stay on the record above.
  /// Worked through by hand, all eleven hold:
  ///
  ///   cot^2 60           = (1/sqrt3)^2               = 1/3
  ///   3log_2 x = 6       -> x = 4,    sqrt(x)        = 2
  ///   log_2 x = 9        -> x = 512,  cbrt(x)        = 8
  ///   log_x 64 = 3       -> x = 4,    x^-2           = 1/16
  ///   log_9 x = 2        -> x = 81,   sqrt(x)        = 9
  ///   log_k 1728 = 3     -> k                        = 12
  ///   log_4 x = 3        -> x = 64,   sqrt(x)        = 8
  ///   log_2(log_10 100)  = log_2 2                   = 1
  ///   log_x 64 = 1.5     -> x = 64^(2/3)             = 16
  ///   log_8(log_4 16)    = log_8 2                   = 1/3
  ///   log_9(log_3 27)    = log_9 3                   = 1/2
  test('every derived product is the product', () {
    final multiplication = RegExp(r'^(\d+)\s*\\times\s*(\d+)\s*=$');
    var checked = 0;

    for (final file
        in Directory('assets/content')
            .listSync(recursive: true)
            .whereType<File>()
            .where((f) => f.path.endsWith('questions.json'))) {
      final questions = jsonDecode(file.readAsStringSync()) as List<dynamic>;
      for (final raw in questions.cast<Map<String, dynamic>>()) {
        final match = multiplication.firstMatch(
          (raw['prompt'] as String).trim(),
        );
        if (match == null) continue;
        final answer = raw['answer'] as Map<String, dynamic>;
        if (answer['type'] != 'numeric') continue;
        checked++;
        expect(
          (answer['answer'] as num).toDouble(),
          int.parse(match[1]!) * int.parse(match[2]!),
          reason: '${raw['id']}: ${raw['prompt']}',
        );
      }
    }

    // The eighty-eight derived ones and every other bare product beside them.
    expect(
      checked,
      greaterThanOrEqualTo(88),
      reason: 'the products were found',
    );
  });
}
