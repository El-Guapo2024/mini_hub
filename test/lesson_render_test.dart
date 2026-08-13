import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:flutter_markdown_plus_latex/flutter_markdown_plus_latex.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:markdown/markdown.dart' as md;

void main() {
  testWidgets('every lesson renders without throwing', (t) async {
    // iPhone 15 Pro logical size — where the user hit the exception.
    await t.binding.setSurfaceSize(const Size(393, 852));
    final failures = <String>[];
    for (final d in Directory(
      'assets/content/number_sense',
    ).listSync().whereType<Directory>()) {
      final f = File('${d.path}/lesson.md');
      if (!f.existsSync()) continue;
      final name = d.path.split('/').last;
      try {
        // Mirrors TopicScreen.build: same extension set, same builders.
        await t.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SingleChildScrollView(
                child: MarkdownBody(
                  data: f.readAsStringSync(),
                  extensionSet: md.ExtensionSet(
                    [LatexBlockSyntax()],
                    [LatexInlineSyntax()],
                  ),
                  builders: {'latex': LatexElementBuilder()},
                ),
              ),
            ),
          ),
        );
        final e = t.takeException();
        if (e != null) failures.add('$name  ->  $e');
      } catch (e) {
        failures.add('$name  ->  $e');
      }
    }
    expect(
      failures,
      isEmpty,
      reason: 'lessons that throw:\n${failures.join('\n')}',
    );
  });
}
