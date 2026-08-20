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
                  File('${source.path}/derived_answers.json').readAsStringSync(),
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
}
