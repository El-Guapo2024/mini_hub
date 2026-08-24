/// A ratio of two whole numbers, kept improper.
///
/// A pair of loose ints invites the mistakes this exists to stop: comparing
/// them by division, forgetting that a negative mixed number subtracts its
/// fractional part, or answering "is this reduced?" about the wrong pair.
class Fraction {
  const Fraction(this.numerator, this.denominator);

  final int numerator;

  /// Never zero: [parseTex] rejects a zero denominator rather than building
  /// a fraction that cannot be compared.
  final int denominator;

  /// A mixed number, e.g. `35\frac{1}{16}`. The whole part carries the sign.
  /// The `d` is a literal made optional, so `\dfrac` matches too.
  static final _mixed = RegExp(r'^(-?\d+)\\d?frac\{(\d+)\}\{(\d+)\}$');

  /// A plain fraction, e.g. `-\frac{3}{4}`. The minus may be written before the
  /// fraction or inside either part — a student editing the numerator field of
  /// a fraction template types `\frac{-3}{4}`, which is the same number.
  static final _plain = RegExp(r'^(-?)\\d?frac\{(-?\d+)\}\{(-?\d+)\}$');

  /// Reads a fraction written as LaTeX, or null if [tex] is not one.
  ///
  /// A mixed number and its improper form are the same fraction, so both
  /// arrive here as the same value. A bare whole number is a fraction over 1.
  /// Anything else — a decimal, an expression — is not a fraction, whatever it
  /// would evaluate to.
  static Fraction? parseTex(String tex) {
    final mixed = _mixed.firstMatch(tex);
    if (mixed != null) {
      final whole = int.parse(mixed[1]!);
      final part = int.parse(mixed[2]!);
      final over = int.parse(mixed[3]!);
      if (over == 0) return null;
      // The fractional part of a negative mixed number is subtracted, not
      // added: -2\frac{1}{2} is -5/2, not -3/2.
      final magnitude = whole.abs() * over + part;
      return Fraction(whole.isNegative ? -magnitude : magnitude, over);
    }

    final plain = _plain.firstMatch(tex);
    if (plain != null) {
      final over = int.parse(plain[3]!);
      if (over == 0) return null;
      final magnitude = int.parse(plain[2]!) * (plain[1] == '-' ? -1 : 1);
      // The sign is carried by the numerator, wherever it was written, so
      // `\frac{3}{-4}` and `-\frac{3}{4}` are the same fraction.
      return over.isNegative
          ? Fraction(-magnitude, -over)
          : Fraction(magnitude, over);
    }

    final whole = int.tryParse(tex);
    return whole == null ? null : Fraction(whole, 1);
  }

  /// Whether this is in lowest terms.
  ///
  /// Zero is, however it is written: `\frac{0}{5}` names the same number as
  /// `0` and cannot be reduced any further, but its gcd with the denominator is
  /// the denominator, so the general rule would call it unreduced and mark a
  /// student wrong for writing zero as a fraction.
  bool get isReduced =>
      numerator == 0 || _gcd(numerator.abs(), denominator.abs()) == 1;

  /// Lowest terms, with the sign on the numerator.
  ///
  /// The sign is moved because equality cross-multiplies and so calls `1/-2`
  /// and `-1/2` the same number, while a hash built from the pair as written
  /// gave them different codes — two objects equal to each other and hashing
  /// apart, which is the one thing a hash may not do.
  Fraction get reduced {
    final divisor = _gcd(numerator.abs(), denominator.abs());
    if (divisor == 0) return this;
    final sign = denominator.isNegative ? -1 : 1;
    return Fraction(
      sign * (numerator ~/ divisor),
      sign * (denominator ~/ divisor),
    );
  }

  static int _gcd(int a, int b) => b == 0 ? a : _gcd(b, a % b);

  /// Cross-multiplied, so 1/2 and 2/4 are equal without either being reduced
  /// first and without the rounding that dividing would introduce.
  @override
  bool operator ==(Object other) =>
      other is Fraction &&
      numerator * other.denominator == other.numerator * denominator;

  @override
  int get hashCode => Object.hash(reduced.numerator, reduced.denominator);

  @override
  String toString() => '\\frac{$numerator}{$denominator}';
}
