/// Exact rational number backed by [BigInt]. No floating point anywhere.
///
/// All intermediate products in SplitTab's money maths go through this type, so results never
/// depend on 53-bit double precision (Flutter web) or 64-bit overflow.
class Rational implements Comparable<Rational> {
  /// Always carries the sign.
  final BigInt numerator;

  /// Always > 0, and gcd(numerator, denominator) == 1.
  final BigInt denominator;

  const Rational._(this.numerator, this.denominator);

  factory Rational(BigInt numerator, [BigInt? denominator]) {
    var d = denominator ?? BigInt.one;
    if (d == BigInt.zero) throw ArgumentError('Rational with zero denominator');
    var n = numerator;
    if (d.isNegative) {
      n = -n;
      d = -d;
    }
    final g = n.gcd(d);
    if (g > BigInt.one) {
      n = n ~/ g;
      d = d ~/ g;
    }
    return Rational._(n, d);
  }

  factory Rational.fromInt(int value) =>
      Rational._(BigInt.from(value), BigInt.one);

  /// Parses an exact decimal such as `"1.10"`, `"-0.00003987"` or `"83"`.
  /// Anything else (exponents, spaces, empty text) throws [FormatException].
  factory Rational.parse(String text) {
    final m = RegExp(r'^([+-]?)(\d+)(?:\.(\d+))?$').firstMatch(text);
    if (m == null) throw FormatException('Not a decimal number', text);
    final fraction = m.group(3) ?? '';
    var n = BigInt.parse('${m.group(2)}$fraction');
    if (m.group(1) == '-') n = -n;
    return Rational(n, BigInt.from(10).pow(fraction.length));
  }

  static final Rational zero = Rational._(BigInt.zero, BigInt.one);
  static final Rational one = Rational._(BigInt.one, BigInt.one);
  static final Rational half = Rational._(BigInt.one, BigInt.two);

  bool get isNegative => numerator.isNegative;
  bool get isZero => numerator == BigInt.zero;

  Rational abs() => isNegative ? Rational._(-numerator, denominator) : this;

  Rational operator +(Rational o) => Rational(
      numerator * o.denominator + o.numerator * denominator,
      denominator * o.denominator);

  Rational operator -(Rational o) => Rational(
      numerator * o.denominator - o.numerator * denominator,
      denominator * o.denominator);

  Rational operator *(Rational o) =>
      Rational(numerator * o.numerator, denominator * o.denominator);

  Rational operator /(Rational o) {
    if (o.isZero) throw ArgumentError('Division by zero');
    return Rational(numerator * o.denominator, denominator * o.numerator);
  }

  /// Largest integer <= this (rounds toward negative infinity).
  BigInt floor() => (numerator - (numerator % denominator)) ~/ denominator;

  @override
  int compareTo(Rational other) =>
      (numerator * other.denominator).compareTo(other.numerator * denominator);

  bool operator <(Rational o) => compareTo(o) < 0;
  bool operator >(Rational o) => compareTo(o) > 0;
  bool operator <=(Rational o) => compareTo(o) <= 0;
  bool operator >=(Rational o) => compareTo(o) >= 0;

  @override
  bool operator ==(Object other) =>
      other is Rational &&
      numerator == other.numerator &&
      denominator == other.denominator;

  @override
  int get hashCode => Object.hash(numerator, denominator);

  @override
  String toString() =>
      denominator == BigInt.one ? '$numerator' : '$numerator/$denominator';
}
