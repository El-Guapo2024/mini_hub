import 'package:math_expressions/math_expressions.dart';
import 'package:math_keyboard/math_keyboard.dart';

final _mixedNumber = RegExp(r'(\d+)\\frac');

int _afterMatchingBrace(String s, int open) {
  if (open >= s.length || s[open] != '{') return -1;
  var depth = 0;
  for (var i = open; i < s.length; i++) {
    if (s[i] == '{') {
      depth++;
    } else if (s[i] == '}') {
      depth--;
      if (depth == 0) return i + 1;
    }
  }
  return -1;
}

String expandMixedNumbers(String tex) {
  var result = tex;
  var from = 0;

  while (from < result.length) {
    final match = _mixedNumber.firstMatch(result.substring(from));
    if (match == null) break;

    final start = from + match.start;
    final fracArgs = from + match.end;
    final numeratorEnd = _afterMatchingBrace(result, fracArgs);
    final denominatorEnd =
        numeratorEnd == -1 ? -1 : _afterMatchingBrace(result, numeratorEnd);

    if (denominatorEnd == -1) {
      from = fracArgs;
      continue;
    }

    final whole = match[1]!;
    final frac = result.substring(fracArgs, denominatorEnd);
    final replacement = '($whole+\\frac$frac)';
    result = result.replaceRange(start, denominatorEnd, replacement);
    from = start + replacement.length;
  }

  return result;
}

final _imaginaryUnit = RegExp(r'(?:\\mathrm\{i\}|\\imath|i)$');

/// Splits a complex answer into `(real, imaginary)`, or null if the input is
/// not a well-formed complex number.
///
/// The real evaluator cannot help here: `math_expressions` has no imaginary
/// unit, so `16+16i` parses as a variable expression and evaluates to nothing.
/// Accepts `16+16i`, `16-16i`, `16i`, `16`, and a bare `i`.
(double, double)? parseComplexTex(String tex) {
  var s = tex.replaceAll(RegExp(r'\s|\\,|\\;|\\!|\{|\}'), '');
  if (s.isEmpty) return null;

  // Split into terms at every top-level sign, keeping the sign with its term.
  final terms = <String>[];
  var start = 0;
  for (var i = 1; i < s.length; i++) {
    if ((s[i] == '+' || s[i] == '-') && s[i - 1] != '^' && s[i - 1] != 'e') {
      terms.add(s.substring(start, i));
      start = i;
    }
  }
  terms.add(s.substring(start));

  var real = 0.0;
  var imaginary = 0.0;
  for (final term in terms) {
    if (term.isEmpty) return null;
    final isImaginary = _imaginaryUnit.hasMatch(term);
    var body = isImaginary
        ? term.substring(0, _imaginaryUnit.firstMatch(term)!.start)
        : term;
    if (body == '' || body == '+') body = '1';
    if (body == '-') body = '-1';

    final value = isImaginary
        ? (double.tryParse(body) ?? evaluateTex(body))
        : evaluateTex(body);
    if (value == null) return null;
    if (isImaginary) {
      imaginary += value;
    } else {
      real += value;
    }
  }
  return (real, imaginary);
}

double? evaluateTex(String tex) {
  if (tex.trim().isEmpty) return null;
  try {
    final expression = TeXParser(expandMixedNumbers(tex)).parse();
    final value = expression.evaluate(EvaluationType.REAL, ContextModel());
    return value is double && value.isFinite ? value : null;
  } catch (_) {
    return null;
  }
}
