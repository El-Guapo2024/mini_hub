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
