import 'errors.dart';
import 'rational.dart';

/// Largest absolute amount accepted (minor units). Keeps every plain-`int` sum exact even on
/// Flutter web, where `int` is a double (exact only up to 2^53). Products and conversions are
/// done in [BigInt]/[Rational], so they have no such limit.
const int maxAmount = 9000000000000;

void checkAmount(int value) {
  if (value.abs() > maxAmount) throw SplitError('amount_too_large', '$value');
}

/// Nearest integer; exact ties go away from zero (10.5 -> 11, -10.5 -> -11).
int roundHalfAway(Rational x) {
  final n = (x.abs() + Rational.half).floor();
  final signed = x.isNegative ? -n : n;
  if (signed.abs() > BigInt.from(maxAmount)) {
    throw const SplitError('amount_too_large');
  }
  return signed.toInt();
}

/// Converts [amount] (minor units of [currency]) into minor units of [home].
///
/// [rate] = home MAJOR units per 1 MAJOR unit of [currency].
int toHomeMinor(int amount, String currency, Rational? rate, String home,
    Map<String, int> exponents) {
  if (currency == home) return amount;
  if (rate == null) throw SplitError('missing_rate', currency);
  if (rate <= Rational.zero) throw SplitError('invalid_rate', '$rate');
  final from = exponents[currency];
  final to = exponents[home];
  if (from == null || to == null) {
    throw SplitError('unknown_currency', currency);
  }
  final shift = to - from;
  final ten = BigInt.from(10);
  final factor = shift >= 0
      ? Rational(ten.pow(shift))
      : Rational(BigInt.one, ten.pow(-shift));
  return roundHalfAway(Rational.fromInt(amount) * rate * factor);
}

/// Largest-remainder allocation of [total] by [weights] (which must sum to 1).
///
/// Each share is floor(|total| * weight); the leftover minor units go one each to the largest
/// fractional remainders, ties to the lowest [tieIndex]. The sign of [total] is re-applied at the
/// end, so a refund mirrors the original expense exactly.
List<int> allocate(int total, List<Rational> weights, List<int> tieIndex) {
  final sign = total < 0 ? -1 : 1;
  final absTotal = Rational.fromInt(total.abs());
  final exact = [for (final w in weights) absTotal * w];
  final base = [for (final x in exact) x.floor()];
  final remainder = [
    for (var i = 0; i < weights.length; i++) exact[i] - Rational(base[i])
  ];
  final left =
      (BigInt.from(total.abs()) - base.fold(BigInt.zero, (a, b) => a + b))
          .toInt();

  final order = List<int>.generate(weights.length, (i) => i)
    ..sort((a, b) {
      final c = remainder[b].compareTo(remainder[a]);
      return c != 0 ? c : tieIndex[a].compareTo(tieIndex[b]);
    });
  final out = [for (final b in base) b.toInt()];
  for (var k = 0; k < left; k++) {
    out[order[k]] += 1;
  }
  // `sign * 0` would be -0 under JavaScript numbers (Flutter web) and could print as "-0".
  return [for (final v in out) v == 0 || sign > 0 ? v : -v];
}
