import 'package:flutter_markdown_plus_latex/flutter_markdown_plus_latex.dart';
import 'package:markdown/markdown.dart' as md;

/// Counts how many display-math blocks the app's extension set actually parses
/// out of a lesson. A '$$' that is not alone on its line never matches
/// [LatexBlockSyntax] and silently renders as literal text.
int latexBlocks(String source) {
  final document = md.Document(
    extensionSet: md.ExtensionSet([LatexBlockSyntax()], [LatexInlineSyntax()]),
  );

  var count = 0;
  void walk(List<md.Node> nodes) {
    for (final node in nodes) {
      if (node is! md.Element) continue;
      if (node.tag == 'latex') count++;
      if (node.children != null) walk(node.children!);
    }
  }

  walk(document.parseLines(source.split('\n')));
  return count;
}
