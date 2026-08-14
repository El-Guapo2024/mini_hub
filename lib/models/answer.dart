import '../math/tex_answer.dart';

/// What counts as a correct response to a question.
///
/// A single `num` cannot express what this question bank actually contains:
/// 219 estimation problems are graded on a range, 37 numeric answers carry a
/// percent unit that students may enter either way, and one answer is complex.
/// Each shape grades itself, so the widget never has to branch on a type tag.
sealed class Answer {
  const Answer();

  factory Answer.fromJson(Map<String, dynamic> json) {
    switch (json['type'] as String?) {
      case 'approx':
        return ApproxAnswer(
          low: (json['low'] as num).toDouble(),
          high: (json['high'] as num).toDouble(),
        );
      case 'complex':
        return ComplexAnswer(
          real: (json['real'] as num).toDouble(),
          imaginary: (json['imag'] as num).toDouble(),
          display: json['display'] as String?,
        );
      case 'fraction':
        return FractionAnswer(
          numerator: json['num'] as int,
          denominator: json['den'] as int,
          reduced: json['reduced'] as bool? ?? true,
          display: json['display'] as String?,
        );
      case 'base':
        return BaseAnswer(
          value: (json['answer'] as num).toDouble(),
          base: json['base'] as int,
          display: json['display'] as String?,
        );
      default:
        return NumericAnswer(
          value: (json['answer'] as num).toDouble(),
          display: json['display'] as String?,
          unit: json['unit'] as String?,
        );
    }
  }

  Map<String, dynamic> toJson();

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

/// A single value. Comparison is relative, not exact: a student who enters
/// `\frac{1}{3}` must match a key stored as 0.3333333333.
class NumericAnswer extends Answer {
  const NumericAnswer({required this.value, String? display, this.unit})
    : _display = display;

  final double value;
  final String? unit;
  final String? _display;

  static const _tolerance = 1e-6;

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
    'type': 'numeric',
    'answer': value,
    if (_display != null) 'display': _display,
    if (unit != null) 'unit': unit,
  };
}

/// An estimation problem, marked `(*)` in the manual, which states the rule as
/// "±5% accuracy is needed" and then prints the resulting band per question.
/// Grading uses the printed bounds verbatim, so a student is marked exactly as
/// the answer key would mark them — including where the book rounded the bounds
/// to whole numbers and landed slightly off its own rule.
class ApproxAnswer extends Answer {
  const ApproxAnswer({required this.low, required this.high});

  final double low;
  final double high;

  double get midpoint => (low + high) / 2;

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
  Map<String, dynamic> toJson() => {'type': 'approx', 'low': low, 'high': high};
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

  static const _tolerance = 1e-6;

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
    'type': 'complex',
    'real': real,
    'imag': imaginary,
    if (_display != null) 'display': _display,
  };
}

/// An answer the manual prints as a fraction, where the form is part of being
/// right: number sense expects the fully reduced fraction, so `\frac{2}{4}` is
/// wrong wherever `\frac{1}{2}` is the answer even though the values match.
///
/// Which questions this applies to is read from the manual rather than guessed.
/// Within a single problem set the book prints `35\frac{1}{16}` for a mixed
/// number question and `53.04` for a decimal one, so the required form is a
/// property of the question, and the printed key is what records it.
class FractionAnswer extends Answer {
  const FractionAnswer({
    required this.numerator,
    required this.denominator,
    this.reduced = true,
    String? display,
  }) : _display = display;

  /// Whether lowest terms are required. True for number sense, where an
  /// unreduced answer is marked wrong. A course with a different convention
  /// sets it false and gets fraction form without the reduction rule — and one
  /// that does not care about form at all uses [NumericAnswer] instead.
  ///
  /// It lives here rather than in the widget so the same input box serves every
  /// course: the question carries its own marking rules.
  final bool reduced;

  /// Held as an improper fraction in lowest terms, so `35\frac{1}{16}` is
  /// 561/16. That makes a mixed number and its improper form the same answer,
  /// which is the intent: the whole-number part is not what the rule is about.
  final int numerator;
  final int denominator;

  final String? _display;

  double get value => numerator / denominator;

  static final _mixed = RegExp(r'^(-?\d+)\\d?frac\{(\d+)\}\{(\d+)\}$');
  static final _plain = RegExp(r'^(-?)\\d?frac\{(\d+)\}\{(\d+)\}$');

  @override
  bool accepts(String tex) {
    final s = tex.replaceAll(RegExp(r'\s|\\,|\\;|\\!|\\left|\\right|\\!'), '');
    if (s.isEmpty) return false;

    final mixed = _mixed.firstMatch(s);
    if (mixed != null) {
      final whole = int.parse(mixed[1]!);
      final part = int.parse(mixed[2]!);
      final over = int.parse(mixed[3]!);
      if (over == 0 || (reduced && !_isReduced(part, over))) return false;
      // The fractional part of a negative mixed number is subtracted, not added.
      final magnitude = whole.abs() * over + part;
      final improper = whole.isNegative ? -magnitude : magnitude;
      return _equals(improper, over);
    }

    final plain = _plain.firstMatch(s);
    if (plain != null) {
      final over = int.parse(plain[3]!);
      final top = int.parse(plain[2]!) * (plain[1] == '-' ? -1 : 1);
      if (over == 0 || (reduced && !_isReduced(top, over))) return false;
      return _equals(top, over);
    }

    // A whole number is a fraction with denominator 1, and is the right form
    // when the answer happens to be whole.
    final whole = int.tryParse(s);
    if (whole != null) return _equals(whole, 1);

    // Anything else — a decimal, an unevaluated expression — is not the form
    // the question asked for, whatever it evaluates to.
    return false;
  }

  bool _equals(int top, int over) => top * denominator == numerator * over;

  static bool _isReduced(int a, int b) => _gcd(a.abs(), b.abs()) == 1;

  static int _gcd(int a, int b) => b == 0 ? a : _gcd(b, a % b);

  @override
  String? get inputHint => reduced ? 'Reduce the fraction' : null;

  @override
  String get display => _display ?? '\\frac{$numerator}{$denominator}';

  @override
  Map<String, dynamic> toJson() => {
    'type': 'fraction',
    'num': numerator,
    'den': denominator,
    if (!reduced) 'reduced': false,
    if (_display != null) 'display': _display,
  };
}

/// A value written in another base, e.g. `15/70` in base 8.
///
/// The digits mean something different from what [evaluateTex] would read: it
/// evaluates `\frac{15}{70}` as 15/70 in base 10, or 0.214, where the answer is
/// 13/56 — 0.232. So the digits are converted out of the question's base first,
/// and only then compared against the stored decimal value.
class BaseAnswer extends Answer {
  const BaseAnswer({required this.value, required this.base, String? display})
    : _display = display;

  /// The answer's value in base 10, so comparison is ordinary arithmetic.
  final double value;

  /// The base the student is expected to answer in, 2 to 36.
  final int base;

  final String? _display;

  static const _tolerance = 1e-9;

  /// A whole number, or a fraction of two whole numbers. Anything else — a
  /// decimal point, an operator — is not a form these questions ask for.
  static final _fraction = RegExp(
    r'^\\d?frac\{([0-9a-zA-Z]+)\}\{([0-9a-zA-Z]+)\}$',
  );
  static final _integer = RegExp(r'^[0-9a-zA-Z]+$');

  @override
  bool accepts(String tex) {
    final s = tex.replaceAll(RegExp(r'\s|\\,|\\;|\\!|\\left|\\right'), '');
    if (s.isEmpty) return false;

    final fraction = _fraction.firstMatch(s);
    if (fraction != null) {
      final numerator = _digits(fraction[1]!);
      final denominator = _digits(fraction[2]!);
      if (numerator == null || denominator == null || denominator == 0) {
        return false;
      }
      return (numerator / denominator - value).abs() <= _tolerance;
    }

    if (_integer.hasMatch(s)) {
      final whole = _digits(s);
      return whole != null && (whole - value).abs() <= _tolerance;
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
    'type': 'base',
    'answer': value,
    'base': base,
    if (_display != null) 'display': _display,
  };
}

/// Renders a double without a trailing `.0` on whole numbers.
String _trim(double v) => v == v.roundToDouble() && v.abs() < 1e15
    ? v.toInt().toString()
    : v.toString();
