import 'package:math_expressions/math_expressions.dart';
import 'package:math_keyboard/math_keyboard.dart';

/// Sizing and spacing markup a math keyboard wraps around what was typed. It
/// carries no value, and `TeXParser` cannot read `\left`/`\right` at all, so it
/// is dropped before any input is parsed — otherwise every answer a student
/// grouped with the keyboard's brackets is unparseable and marked wrong.
final _decoration = RegExp(r'\\,|\\;|\\!|\\left|\\right');

/// `\dfrac` and `\tfrac` are the same fraction as `\frac`, differing only in
/// how large they render. The keyboard may emit any of the three.
final _fractionForms = RegExp(r'\\[dt]frac');

/// Strips what does not change the value, so everything downstream — mixed
/// number expansion, term splitting, evaluation — sees one spelling.
String _normalize(String tex) =>
    tex.replaceAll(_decoration, '').replaceAll(_fractionForms, r'\frac');

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
    final denominatorEnd = numeratorEnd == -1
        ? -1
        : _afterMatchingBrace(result, numeratorEnd);

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

/// A trailing `i` that is the imaginary unit rather than the last letter of a
/// command: `2i` and `\frac{1}{2}i` end in the unit, `\pi` does not.
final _imaginaryUnit = RegExp(r'(?<![a-zA-Z])i$');

/// `math_keyboard` emits a declared variable as `\mathrm{i}`, so the unit has
/// to be folded to a bare `i` *before* braces are stripped — otherwise
/// `\mathrm{i}` collapses to `\mathrmi` and the `\mathrm` reads as a coefficient.
final _imaginaryForms = RegExp(
  r'\\(?:mathrm|text|mathit)\s*\{\s*i\s*\}|\\imath',
);

/// Splits a complex answer into `(real, imaginary)`, or null if the input is
/// not a well-formed complex number.
///
/// The real evaluator cannot help here: `math_expressions` has no imaginary
/// unit, so `16+16i` parses as a variable expression and evaluates to nothing.
/// Accepts `16+16i`, `16-16i`, `16i`, `16`, and a bare `i`.
(double, double)? parseComplexTex(String tex) {
  final s = _normalize(
    tex.replaceAll(_imaginaryForms, 'i'),
  ).replaceAll(RegExp(r'\s'), '');
  if (s.isEmpty) return null;

  // Split into terms at every top-level sign, keeping the sign with its term.
  //
  // Braces and parentheses are counted rather than stripped: the sign inside
  // `\frac{2+2}{2}` groups the numerator and is not a term boundary. Stripping
  // them first split that fraction in half and rejected a correct answer.
  final terms = <String>[];
  var start = 0;
  var depth = 0;
  for (var i = 0; i < s.length; i++) {
    final c = s[i];
    if (c == '{' || c == '(') {
      depth++;
    } else if (c == '}' || c == ')') {
      depth--;
      if (depth < 0) return null;
    } else if (i > 0 &&
        depth == 0 &&
        (c == '+' || c == '-') &&
        s[i - 1] != '^' &&
        s[i - 1] != 'e') {
      terms.add(s.substring(start, i));
      start = i;
    }
  }
  if (depth != 0) return null;
  terms.add(s.substring(start));

  var real = 0.0;
  var imaginary = 0.0;
  for (final term in terms) {
    if (term.isEmpty) return null;
    final isImaginary = _imaginaryUnit.hasMatch(term);
    var body = isImaginary
        ? term.substring(0, _imaginaryUnit.firstMatch(term)!.start)
        : term;
    // The sign is taken off here rather than left for the evaluator, which
    // cannot read a leading `+` at all: `16i+3` and `+3+16i` were rejected
    // outright, though both name a number a student may reasonably write.
    var sign = 1.0;
    if (body.startsWith('+')) {
      body = body.substring(1);
    } else if (body.startsWith('-')) {
      sign = -1.0;
      body = body.substring(1);
    }
    // A term that is only a sign is a unit: `i` and `-i` are 1 and -1.
    if (body.isEmpty) body = '1';

    final magnitude = double.tryParse(body) ?? evaluateTex(body);
    if (magnitude == null) return null;
    final value = sign * magnitude;
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
    final expression = TeXParser(expandMixedNumbers(_normalize(tex))).parse();
    final value = expression.evaluate(EvaluationType.REAL, ContextModel());
    return value is double && value.isFinite ? value : null;
  } catch (_) {
    return null;
  }
}
