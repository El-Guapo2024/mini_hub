import 'package:flutter/material.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:flutter_markdown_plus_latex/flutter_markdown_plus_latex.dart';
import 'package:markdown/markdown.dart' as md;

/// The markdown dialect a lesson is written in.
///
/// Declared once, because a reader that assembles its own set is reading a
/// format the app does not ship — which is how tests came to parse lessons
/// without the syntax the screen used.
///
/// Lessons are plain markdown plus LaTeX. They carry no questions: a lesson is
/// prose, and practice is a separate screen over `questions.json`. That keeps
/// the render path to what the packages already do, with nothing of ours
/// between the file and the screen.
md.ExtensionSet lessonSyntax() =>
    md.ExtensionSet([LatexBlockSyntax()], [LatexInlineSyntax()]);

/// Renders a lesson's markdown. The one place lesson typography is decided.
class LessonView extends StatelessWidget {
  const LessonView({super.key, required this.markdown});

  final String markdown;

  @override
  Widget build(BuildContext context) {
    return MarkdownBody(
      data: markdown,
      extensionSet: lessonSyntax(),
      builders: {
        'latex': LatexElementBuilder(
          textStyle: const TextStyle(color: Colors.white),
        ),
      },
      styleSheet: MarkdownStyleSheet(
        p: const TextStyle(color: Colors.white70, fontSize: 16, height: 1.6),
        h1: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 26,
        ),
        code: TextStyle(
          color: Colors.tealAccent.shade100,
          backgroundColor: Colors.grey.shade800,
        ),
      ),
    );
  }
}
