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

/// Renders a double without a trailing `.0` on whole numbers.
String _trim(double v) => v == v.roundToDouble() && v.abs() < 1e15
    ? v.toInt().toString()
    : v.toString();
