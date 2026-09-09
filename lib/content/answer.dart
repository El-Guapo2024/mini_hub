import '../math/tex_answer.dart';
import 'fraction.dart';

/// How a question is answered. Recorded on every attempt, so the names are
/// stored data: renaming one splits a question's history in two.
enum QuestionType { numeric, estimate, complex, fraction, base, choice }

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
      case QuestionType.choice:
        return ChoiceAnswer(
          correct: json['correct'] as int,
          count: json['count'] as int,
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

  /// The question's classification, recorded on every attempt. Derived from
  /// the answer rather than stored beside it, so the two cannot disagree.
  QuestionType get kind;

  /// Whether the student's LaTeX input is a correct response.
  bool accepts(String tex);

  /// The canonical answer, as LaTeX, for revealing after a wrong attempt.
  String get display;

  /// Symbols the on-screen keyboard must offer for this answer to be typable
  /// at all.
  ///
  /// Pi is decided here rather than per subclass, because the question is only
  /// ever "is the answer written with it" — an answer of any shape that prints
  /// pi and is not given the key cannot be entered at all. A subclass adding
  /// its own symbols builds on this rather than replacing it.
  List<String> get inputVariables =>
      display.contains(r'\pi') ? const [r'\pi'] : const [];

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
    // Only where the answer is a percentage. Everywhere else the sign changes
    // what was written — `5%` is a twentieth, not 5 — so dropping it would
    // accept an answer a hundred times too small.
    final entered = evaluateTex(unit == '%' ? _withoutPercent(tex) : tex);
    if (entered == null) return false;
    if (_close(entered, value)) return true;
    // Every percent answer in the bank is keyed as the percentage itself —
    // `\frac{1}{40} = ___%` is 2.5, not 0.025 — but the blank already carries
    // the % sign, so a student may reasonably write the decimal instead.
    //
    // Only that reading is accepted. Also allowing `value * 100` would mean
    // 250 marked correct for 2.5: an answer a hundred times too large, which
    // is the mistake this question type exists to catch.
    if (unit == '%') return _close(entered * 100, value);
    return false;
  }

  static bool _close(double a, double b) {
    final scale = b.abs() > 1 ? b.abs() : 1.0;
    return (a - b).abs() <= _tolerance * scale;
  }

  /// The answer as LaTeX. The unit is escaped, because the display is rendered
  /// as math and a bare `%` opens a comment there: `220%` drew as `220`, so
  /// every percent answer revealed itself without its sign.
  @override
  String get display => _display ?? _trim(value) + _texUnit;

  String get _texUnit => switch (unit) {
    null => '',
    '%' => r'\%',
    final other => other,
  };
}

/// A percent sign written either way, and only at the end, where it is the unit
/// rather than part of the value.
///
/// Dropped before the value is read: `TeXParser` cannot evaluate it, so a
/// student who typed back the `220\%` they were just shown was marked wrong.
/// What the sign means is already carried by the answer's unit.
final _trailingPercent = RegExp(r'\s*\\?%\s*$');

String _withoutPercent(String tex) => tex.replaceFirst(_trailingPercent, '');

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

  /// Added to whatever the answer already needs, rather than replacing it: a
  /// complex answer written with pi needs both keys, and dropping either one
  /// leaves it unanswerable.
  @override
  List<String> get inputVariables => [...super.inputVariables, 'i'];

  @override
  String? get inputHint => 'Answer in the form a+bi';

  @override
  String get display {
    if (_display != null) return _display;
    final sign = imaginary < 0 ? '-' : '+';
    return '${_trim(real)}$sign${_trim(imaginary.abs())}i';
  }
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

  /// A whole number, or a fraction of two whole numbers, either possibly
  /// signed. Anything else — a decimal point, an operator — is not a form
  /// these questions ask for.
  /// The minus may sit before the fraction or inside either part, as it may in
  /// [Fraction.parseTex] — the fraction template puts the cursor in the
  /// numerator, so that is where a student types it.
  /// `\dfrac` and `\tfrac` differ from `\frac` only in size, and are read as
  /// the same fraction everywhere else, so they are accepted here too rather
  /// than leaving base answers the one place a display form changes the verdict.
  static final _fraction = RegExp(
    r'^(-?)\\[dt]?frac\{(-?)([0-9a-zA-Z]+)\}\{(-?)([0-9a-zA-Z]+)\}$',
  );
  static final _integer = RegExp(r'^(-?)([0-9a-zA-Z]+)$');

  /// A base written as a subscript at the end, the way the manual writes one
  /// and the way this answer reveals itself: `\frac{4}{7}_{8}`.
  static final _baseTag = RegExp(r'_\{?([0-9]+)\}?$');

  @override
  bool accepts(String tex) {
    var s = tex.replaceAll(_decoration, '');
    if (s.isEmpty) return false;

    // A student copying the revealed answer types the subscript with it, and
    // every base answer in the bank reveals itself carrying one — so without
    // this, the one form the app ever shows them is the one form it rejects.
    //
    // Only this answer's own base is dropped. A subscript naming a different
    // one is a claim about what was written, not decoration: `\frac{4}{7}_{10}`
    // is a different number from `\frac{4}{7}_{8}` and must not be taken for it.
    final tag = _baseTag.firstMatch(s);
    if (tag != null) {
      if (int.parse(tag[1]!) != base) return false;
      s = s.substring(0, tag.start);
      if (s.isEmpty) return false;
    }

    final fraction = _fraction.firstMatch(s);
    if (fraction != null) {
      final numerator = _digits(fraction[3]!);
      final denominator = _digits(fraction[5]!);
      if (numerator == null || denominator == null || denominator == 0) {
        return false;
      }
      // Three places may each carry a minus; an even number of them is positive.
      final minuses = [
        fraction[1]!,
        fraction[2]!,
        fraction[4]!,
      ].where((sign) => sign == '-').length;
      final magnitude = numerator / denominator;
      return _matches(minuses.isOdd ? -magnitude : magnitude);
    }

    final integer = _integer.firstMatch(s);
    if (integer != null) {
      final whole = _digits(integer[2]!);
      return whole != null && _matches(_signed(integer[1]!, whole));
    }
    return false;
  }

  bool _matches(double entered) => (entered - value).abs() <= _exact;

  static double _signed(String sign, double magnitude) =>
      sign == '-' ? -magnitude : magnitude;

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
}

/// One option among several printed in the prompt, answered by its number.
///
/// The options themselves live in the prompt's LaTeX, so the shared math
/// keyboard is the input and the widget stays type-blind — a student types
/// `2` for option 2. The answer knows how many options exist, so a number
/// outside the range is wrong rather than a parse error.
class ChoiceAnswer extends Answer {
  const ChoiceAnswer({
    required this.correct,
    required this.count,
    String? display,
  }) : _display = display;

  /// The right option, 1-based, as the prompt numbers them.
  final int correct;

  /// How many options the prompt offers.
  final int count;

  /// The correct option restated, e.g. `(2)\ L_1L_2`, shown on reveal so a
  /// wrong answer teaches the content rather than a bare index.
  final String? _display;

  @override
  QuestionType get kind => QuestionType.choice;

  @override
  bool accepts(String tex) {
    final entered = evaluateTex(tex);
    if (entered == null) return false;
    if (entered != entered.roundToDouble()) return false;
    return entered.round() == correct;
  }

  @override
  String? get inputHint => 'Enter the number of your choice (1–$count)';

  @override
  String get display => _display ?? '$correct';
}

/// Renders a double without a trailing `.0` on whole numbers.
String _trim(double v) => v == v.roundToDouble() && v.abs() < 1e15
    ? v.toInt().toString()
    : v.toString();
