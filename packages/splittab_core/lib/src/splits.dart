import 'errors.dart';
import 'model.dart';
import 'rational.dart';

void _requireKnown(Iterable<String> names, Set<String> members) {
  for (final m in names) {
    if (!members.contains(m)) throw SplitError('unknown_member', m);
  }
}

/// Turns a [Split] into per-member weights that sum to 1 (see `fixtures/README.md`).
Map<String, Rational> splitWeights(
    Split split, int amount, Set<String> members) {
  final w = <String, Rational>{};
  switch (split) {
    case EqualSplit(:final among):
      if (among.isEmpty) throw const SplitError('empty_split');
      _requireKnown(among, members);
      final each = Rational(BigInt.one, BigInt.from(among.length));
      for (final m in among) {
        w[m] = (w[m] ?? Rational.zero) + each;
      }
    case ExactSplit(:final amounts):
      _requireKnown(amounts.keys, members);
      if (amounts.values.fold(0, (a, b) => a + b) != amount) {
        throw const SplitError('split_sum_mismatch');
      }
      for (final e in amounts.entries) {
        w[e.key] = amount == 0
            ? Rational.zero
            : Rational(BigInt.from(e.value), BigInt.from(amount));
      }
    case PercentSplit(:final percents):
      _requireKnown(percents.keys, members);
      final hundred = Rational.fromInt(100);
      final sum = percents.values.fold(Rational.zero, (a, b) => a + b);
      if (percents.values.any((p) => p.isNegative) || sum != hundred) {
        throw const SplitError('percent_sum_invalid');
      }
      for (final e in percents.entries) {
        w[e.key] = e.value / hundred;
      }
    case SharesSplit(:final shares):
      _requireKnown(shares.keys, members);
      final total = shares.values.fold(Rational.zero, (a, b) => a + b);
      if (shares.values.any((s) => s.isNegative) || total.isZero) {
        throw const SplitError('invalid_shares');
      }
      for (final e in shares.entries) {
        w[e.key] = e.value / total;
      }
    case NightsSplit(:final totalNights, :final nights):
      _requireKnown(nights.keys, members);
      final outOfRange = nights.values
          .any((ns) => ns.any((night) => night < 1 || night > totalNights));
      if (totalNights < 1 || outOfRange) {
        throw const SplitError('invalid_nights');
      }
      for (var night = 1; night <= totalNights; night++) {
        final present = [
          for (final e in nights.entries)
            if (e.value.contains(night)) e.key,
        ];
        if (present.isEmpty) throw SplitError('night_uncovered', '$night');
        final each =
            Rational(BigInt.one, BigInt.from(totalNights * present.length));
        for (final m in present) {
          w[m] = (w[m] ?? Rational.zero) + each;
        }
      }
  }
  return w;
}
