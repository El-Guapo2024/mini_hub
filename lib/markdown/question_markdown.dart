import 'package:flutter/material.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:markdown/markdown.dart' as md;

import '../models/question.dart';
import '../widgets/question_view.dart';

class QuestionBlockSyntax extends md.BlockSyntax {
  @override
  // Dots are part of the id: they are provenance, as in `bh.1.2.1.q1`.
  RegExp get pattern => RegExp(r'^\[\[question:([\w.\-]+)\s*\]\]\s*$');

  @override
  md.Node parse(md.BlockParser parser) {
    final match = pattern.firstMatch(parser.current.content);
    final id = match?[1] ?? '';
    parser.advance();
    return md.Element.text('question', id);
  }
}

class QuestionElementBuilder extends MarkdownElementBuilder {
  QuestionElementBuilder({required this.pool});

  final Map<String, Question> pool;

  @override
  Widget visitElementAfterWithContext(
    BuildContext context,
    md.Element element,
    TextStyle? preferredStyle,
    TextStyle? parentStyle,
  ) {
    final id = element.textContent;
    final question = pool[id];

    if (question == null) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Text(
          'missing question: $id',
          style: const TextStyle(color: Colors.redAccent),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: QuestionView(key: ValueKey(id), question: question),
    );
  }
}
