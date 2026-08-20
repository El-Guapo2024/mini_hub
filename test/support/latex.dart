import 'package:markdown/markdown.dart' as md;
import 'package:mini_hub/ui/widgets/lesson_view.dart';

/// Every math span the app parses out of a lesson, in order.
///
/// Uses the app's own [lessonSyntax] rather than assembling an extension set
/// here: a reader that builds its own is reading a format the app does not
/// ship, which is how tests came to parse lessons without the syntax the
/// screen used.
List<String> latexSpans(String source) {
  final document = md.Document(extensionSet: lessonSyntax());

  final spans = <String>[];
  void walk(List<md.Node> nodes) {
    for (final node in nodes) {
      if (node is! md.Element) continue;
      if (node.tag == 'latex') spans.add(node.textContent);
      final children = node.children;
      if (children != null) walk(children);
    }
  }

  walk(document.parseLines(source.split('\n')));
  return spans;
}

/// Counts how many math spans the app actually parses out of a lesson. A '$$'
/// that is not alone on its line never matches [LatexBlockSyntax] and silently
/// renders as literal text.
int latexBlocks(String source) => latexSpans(source).length;
