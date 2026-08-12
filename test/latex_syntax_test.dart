import 'package:flutter_markdown_plus_latex/flutter_markdown_plus_latex.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:markdown/markdown.dart' as md;

int latexBlocks(String source) {
  final doc = md.Document(
    extensionSet: md.ExtensionSet([LatexBlockSyntax()], [LatexInlineSyntax()]),
  );
  var count = 0;
  void walk(List<md.Node> nodes) {
    for (final n in nodes) {
      if (n is md.Element) {
        if (n.tag == 'latex') count++;
        if (n.children != null) walk(n.children!);
      }
    }
  }
  walk(doc.parseLines(source.split('\n')));
  return count;
}

const multiLineOld = r'''
$$523 \times 11 = \begin{array}{ll}
\text{Ones:} & 3 \\
\text{Answer:} & 5753
\end{array}$$
''';

const multiLineNew = r'''
$$
523 \times 11 = \begin{array}{ll}
\text{Ones:} & 3 \\
\text{Answer:} & 5753
\end{array}
$$
''';

void main() {
  test('multi-line math with same-line delimiters does NOT parse', () {
    expect(latexBlocks(multiLineOld), 0);
  });
  test('multi-line math with own-line delimiters DOES parse', () {
    expect(latexBlocks(multiLineNew), 1);
  });
}
