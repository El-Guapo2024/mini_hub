import 'package:flutter_test/flutter_test.dart';

import 'support/latex.dart';

/// Where the display-math delimiters may sit. The two shapes below look alike
/// in a diff and behave completely differently, which is why the corpus check
/// in lesson_latex_test exists at all.
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
