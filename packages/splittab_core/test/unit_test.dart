import 'package:splittab_core/splittab_core.dart';
import 'package:test/test.dart';

void main() {
  group('Rational', () {
    test('parses exact decimals', () {
      expect(
          Rational.parse('1.10'), Rational(BigInt.from(11), BigInt.from(10)));
      expect(Rational.parse('0.00003987'),
          Rational(BigInt.from(3987), BigInt.from(100000000)));
      expect(Rational.parse('-2.5'), Rational(BigInt.from(-5), BigInt.two));
      expect(Rational.parse('83'), Rational.fromInt(83));
    });
    test('rejects anything that is not a plain decimal', () {
      for (final bad in ['', ' 1', '1e5', '1,5', '.5', '5.', 'abc', '--1']) {
        expect(() => Rational.parse(bad), throwsFormatException, reason: bad);
      }
    });
    test('floor rounds toward negative infinity', () {
      expect(Rational.parse('2.5').floor(), BigInt.two);
      expect(Rational.parse('-2.5').floor(), BigInt.from(-3));
      expect(Rational.parse('-3').floor(), BigInt.from(-3));
    });
    test('arithmetic is exact', () {
      final third = Rational(BigInt.one, BigInt.from(3));
      expect(third + third + third, Rational.one);
      expect(
          Rational.parse('0.1') + Rational.parse('0.2'), Rational.parse('0.3'));
    });
  });

  group('rounding and allocation', () {
    test('roundHalfAway', () {
      expect(roundHalfAway(Rational.parse('10.5')), 11);
      expect(roundHalfAway(Rational.parse('-10.5')), -11);
      expect(roundHalfAway(Rational.parse('10.49')), 10);
      expect(roundHalfAway(Rational.parse('0.5')), 1);
    });
    test(
        'allocate hands leftovers to the largest remainders, ties to the lowest index',
        () {
      final third = Rational(BigInt.one, BigInt.from(3));
      expect(allocate(100, [third, third, third], [0, 1, 2]), [34, 33, 33]);
      expect(allocate(100, [third, third, third], [2, 1, 0]), [33, 33, 34]);
      expect(allocate(-100, [third, third, third], [0, 1, 2]), [-34, -33, -33]);
    });
    test('allocate always sums to the total', () {
      final w = [
        for (final s in ['1', '2', '3', '7']) Rational.parse(s)
      ];
      final total = w.fold(Rational.zero, (a, b) => a + b);
      final weights = [for (final x in w) x / total];
      for (final t in [0, 1, 7, 99, 1000003, -57]) {
        expect(allocate(t, weights, [0, 1, 2, 3]).fold(0, (a, b) => a + b), t);
      }
    });
  });

  group('limits', () {
    final trip = const Trip(homeCurrency: 'USD', members: ['a', 'b']);
    test('amounts above maxAmount are rejected', () {
      final e = Expense(
          id: 'e',
          amount: maxAmount + 1,
          paidBy: {'a': maxAmount + 1},
          split: const EqualSplit(['a', 'b']));
      expect(
          () => computeTrip(trip, [e]),
          throwsA(isA<SplitError>()
              .having((x) => x.code, 'code', 'amount_too_large')));
    });
    test('maxAmount itself is fine and splits exactly', () {
      final e = Expense(
          id: 'e',
          amount: maxAmount,
          paidBy: {'a': maxAmount},
          split: const EqualSplit(['a', 'b']));
      final r = computeTrip(trip, [e]);
      expect(r.balances, {'a': maxAmount ~/ 2, 'b': -maxAmount ~/ 2});
    });
    test('a conversion that overflows the limit is rejected', () {
      const t = Trip(
          homeCurrency: 'USD',
          members: ['a', 'b'],
          currencyExponents: {'USD': 2, 'VND': 0});
      final e = Expense(
        id: 'e',
        amount: 5000000000,
        currency: 'VND',
        rate: Rational.parse('100'),
        paidBy: {'a': 5000000000},
        split: const EqualSplit(['a', 'b']),
      );
      expect(
          () => computeTrip(t, [e]),
          throwsA(isA<SplitError>()
              .having((x) => x.code, 'code', 'amount_too_large')));
    });
  });
}
