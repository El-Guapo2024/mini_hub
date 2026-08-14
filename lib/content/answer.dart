import '../math/tex_answer.dart';
import 'fraction.dart';

/// How a question is answered. Recorded on every attempt, so the names are
/// stored data: renaming one splits a question's history in two.
enum QuestionType { numeric, estimate, complex, fraction, base }

/// What counts as a correct response to a question.
///
/// Each shape grades itself, so the input widget never branches on a type tag
/// and a question carries its own marking rules — which differ by course, not
/// just by question.
sealed class Answer {
  const Answer();

  factory Answer.fromJson(Map<String, dynamic> json) {
    final raw = json['type'];
    // Falling back to a numeric answer would grade an unknown type by the
    // wrong rule and look like it worked. The bank is generated, so an
    // unrecognised type is a bug in the generator, not a student's input.
    if (raw is! String || !QuestionType.values.any((t) => t.name == raw)) {
      throw FormatException('unknown answer type: $raw');
    }
    switch (QuestionType.values.byName(raw)) {
      case QuestionType.estimate:
        return ApproxAnswer(
          low: (json['low'] as num).toDouble(),
          high: (json['high'] as num).toDouble(),
        );
      case QuestionType.complex:
        return ComplexAnswer(
          real: (json['real'] as num).toDouble(),
          imaginary: (json['imag'] as num).toDouble(),
          display: json['display'] as String?,
        );
      case QuestionType.fraction:
        return FractionAnswer(
          value: Fraction(json['num'] as int, json['den'] as int),
          reduced: json['reduced'] as bool? ?? true,
          display: json['display'] as String?,
        );
      case QuestionType.base:
        return BaseAnswer(
          value: (json['answer'] as num).toDouble(),
          base: json['base'] as int,
          display: json['display'] as String?,
        );
      case QuestionType.numeric:
        return NumericAnswer(
          value: (json['answer'] as num).toDouble(),
          display: json['display'] as String?,
          unit: json['unit'] as String?,
        );
    }
  }

  Map<String, dynamic> toJson();

  /// The question's classification, recorded on every attempt. Derived from
  /// the answer rather than stored beside it, so the two cannot disagree.
  QuestionType get kind;

  /// Whether the student's LaTeX input is a correct response.
  bool accepts(String tex);

  /// The canonical answer, as LaTeX, for revealing after a wrong attempt.
  String get display;

  /// Symbols the on-screen keyboard must offer for this answer to be typable
  /// at all. Empty for everything except complex answers.
  List<String> get inputVariables => const [];

  /// Shown under the input when the grading rule isn't obvious from the
  /// prompt — a student can't tell an estimation problem from an exact one.
  String? get inputHint => null;
}

/// Spacing and sizing markup a math keyboard emits around what was typed. It
/// carries no value, so it is dropped before an input is read as a form.
final _decoration = RegExp(r'\s|\\,|\\;|\\!|\\left|\\right');

/// The margin within which two computed values count as the same number: a
/// student entering `\frac{1}{3}` must match a key stored as 0.3333333333.
const _tolerance = 1e-6;

/// A single value, graded on what it evaluates to rather than how it is written.
class NumericAnswer extends Answer {
  const NumericAnswer({required this.value, String? display, this.unit})
    : _display = display;

  final double value;
  final String? unit;
  final String? _display;

  @override
  QuestionType get kind => QuestionType.numeric;

  @override
  bool accepts(String tex) {
    final entered = evaluateTex(tex);
    if (entered == null) return false;
    if (_close(entered, value)) return true;
    // A percent answer is keyed inconsistently across the manual — 7 in one
    // set, .07 in another — so accept whichever form the student used.
    if (unit == '%') {
      return _close(entered * 100, value) || _close(entered, value * 100);
    }
    return false;
  }

  static bool _close(double a, double b) {
    final scale = b.abs() > 1 ? b.abs() : 1.0;
    return (a - b).abs() <= _tolerance * scale;
  }

  @override
  String get display => _display ?? _trim(value) + (unit ?? '');

  @override
  Map<String, dynamic> toJson() => {
    'type': kind.name,
    'answer': value,
    if (_display != null) 'display': _display,
    if (unit != null) 'unit': unit,
  };
}

/// An estimation problem, marked `(*)` in the manual. Grading uses the printed
/// band verbatim — including where rounding it to whole numbers left it slightly
/// off the stated ±5% — so a student is marked exactly as the key marks them.
class ApproxAnswer extends Answer {
  const ApproxAnswer({required this.low, required this.high});

  final double low;
  final double high;

  @override
  QuestionType get kind => QuestionType.estimate;

  @override
  bool accepts(String tex) {
    final entered = evaluateTex(tex);
    return entered != null && entered >= low && entered <= high;
  }

  @override
  String get display => '${_trim(low)} \\text{ to } ${_trim(high)}';

  @override
  String? get inputHint => 'Estimate — within ±5% counts';

  @override
  Map<String, dynamic> toJson() => {
    'type': kind.name,
    'low': low,
    'high': high,
  };
}

/// A complex answer, e.g. `(1+i)^9 = 16+16i`. The real evaluator cannot grade
/// these, so the input is parsed into its real and imaginary parts instead.
class ComplexAnswer extends Answer {
  const ComplexAnswer({
    required this.real,
    required this.imaginary,
    String? display,
  }) : _display = display;

  final double real;
  final double imaginary;
  final String? _display;

  @override
  QuestionType get kind => QuestionType.complex;

  @override
  bool accepts(String tex) {
    final parsed = parseComplexTex(tex);
    if (parsed == null) return false;
    return (parsed.$1 - real).abs() <= _tolerance &&
        (parsed.$2 - imaginary).abs() <= _tolerance;
  }

  @override
  List<String> get inputVariables => const ['i'];

  @override
  String? get inputHint => 'Answer in the form a+bi';

  @override
  String get display {
    if (_display != null) return _display;
    final sign = imaginary < 0 ? '-' : '+';
    return '${_trim(real)}$sign${_trim(imaginary.abs())}i';
  }

  @override
  Map<String, dynamic> toJson() => {
    'type': kind.name,
    'real': real,
    'imag': imaginary,
    if (_display != null) 'display': _display,
  };
}

/// An answer where the form is part of being right: number sense wants the
/// reduced fraction, so `\frac{2}{4}` is wrong where `\frac{1}{2}` is the answer.
///
/// Which questions this applies to is read from the manual, not assumed — one
/// problem set prints `35\frac{1}{16}` and `53.04` side by side.
class FractionAnswer extends Answer {
  const FractionAnswer({
    required this.value,
    this.reduced = true,
    String? display,
  }) : _display = display;

  /// The answer, held improper: `35\frac{1}{16}` is 561/16, so a mixed number
  /// and its improper form are the same answer. The whole-number part is not
  /// what the form rule is about.
  final Fraction value;

  /// Whether lowest terms are required. A course with another convention sets
  /// it false; one that does not care about form uses [NumericAnswer]. It lives
  /// on the question so the shared input box needs no course-specific rules.
  final bool reduced;

  final String? _display;

  @override
  QuestionType get kind => QuestionType.fraction;

  @override
  bool accepts(String tex) {
    final entered = Fraction.parseTex(tex.replaceAll(_decoration, ''));
    if (entered == null) return false;
    if (reduced && !entered.isReduced) return false;
    return entered == value;
  }

  @override
  String? get inputHint => reduced ? 'Reduce the fraction' : null;

  @override
  String get display => _display ?? value.toString();

  @override
  Map<String, dynamic> toJson() => {
    'type': kind.name,
    'num': value.numerator,
    'den': value.denominator,
    if (!reduced) 'reduced': false,
    if (_display != null) 'display': _display,
  };
}

/// A value written in another base, e.g. `15/70` in base 8, which is 13/56.
/// The digits are converted out of the question's base before comparison —
/// [evaluateTex] would read them as base 10 and mark a right answer wrong.
class BaseAnswer extends Answer {
  const BaseAnswer({required this.value, required this.base, String? display})
    : _display = display;

  /// The answer's value in base 10, so comparison is ordinary arithmetic.
  final double value;

  /// The base the student is expected to answer in, 2 to 36.
  final int base;

  final String? _display;

  /// Tighter than the shared one: these keys are stored as a long decimal
  /// expansion of an exact ratio, so a correct answer matches to many places.
  static const _exact = 1e-9;

  @override
  QuestionType get kind => QuestionType.base;

  /// A whole number, or a fraction of two whole numbers. Anything else — a
  /// decimal point, an operator — is not a form these questions ask for.
  static final _fraction = RegExp(
    r'^\\d?frac\{([0-9a-zA-Z]+)\}\{([0-9a-zA-Z]+)\}$',
  );
  static final _integer = RegExp(r'^[0-9a-zA-Z]+$');

  @override
  bool accepts(String tex) {
    final s = tex.replaceAll(_decoration, '');
    if (s.isEmpty) return false;

    final fraction = _fraction.firstMatch(s);
    if (fraction != null) {
      final numerator = _digits(fraction[1]!);
      final denominator = _digits(fraction[2]!);
      if (numerator == null || denominator == null || denominator == 0) {
        return false;
      }
      return (numerator / denominator - value).abs() <= _exact;
    }

    if (_integer.hasMatch(s)) {
      final whole = _digits(s);
      return whole != null && (whole - value).abs() <= _exact;
    }
    return false;
  }

  /// Reads [digits] in this answer's base, or null if any digit is invalid for
  /// it — `8` in base 8 is a typo, not a number.
  double? _digits(String digits) {
    final parsed = int.tryParse(digits, radix: base);
    return parsed?.toDouble();
  }

  @override
  String? get inputHint => 'Answer in base $base';

  @override
  String get display => _display ?? '${_trim(value)}_{$base}';

  @override
  Map<String, dynamic> toJson() => {
    'type': kind.name,
    'answer': value,
    'base': base,
    if (_display != null) 'display': _display,
  };
}

/// Renders a double without a trailing `.0` on whole numbers.
String _trim(double v) => v == v.roundToDouble() && v.abs() < 1e15
    ? v.toInt().toString()
    : v.toString();
