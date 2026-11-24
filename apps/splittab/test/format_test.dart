import 'package:flutter_test/flutter_test.dart';
import 'package:splittab/data/currencies.dart';

void main() {
  group('formatMoney', () {
    test('uses the currency symbol, grouping and minor units', () {
      expect(formatMoney(9000, 'USD'), r'$90.00');
      expect(formatMoney(120000, 'INR'), '₹1,200.00');
      expect(formatMoney(1500, 'JPY'), '¥1,500');
      expect(formatMoney(12345, 'KWD'), 'KWD 12.345');
      expect(formatMoney(5, 'USD'), r'$0.05');
      expect(formatMoney(100000000, 'EUR'), '€1,000,000.00');
    });
    test('negative amounts use a real minus sign, not a hyphen', () {
      expect(formatMoney(-3000, 'USD'), '−\$30.00');
      expect(formatMoney(-3000, 'USD').contains('-'), isFalse);
    });
    test('showPlus marks positive amounts only', () {
      expect(formatMoney(500, 'USD', showPlus: true), r'+$5.00');
      expect(formatMoney(0, 'USD', showPlus: true), r'$0.00');
    });
  });

  group('parseMinor', () {
    test('reads plain amounts', () {
      expect(parseMinor('90', 2), 9000);
      expect(parseMinor('12.5', 2), 1250);
      expect(parseMinor('12.50', 2), 1250);
      expect(parseMinor('0.05', 2), 5);
      expect(parseMinor('1,200.75', 2), 120075);
      expect(parseMinor('1500', 0), 1500);
      expect(parseMinor('12.345', 3), 12345);
    });
    test('rejects empty text, junk and too many decimals', () {
      for (final bad in ['', ' ', 'abc', '12.345', '-5', '1e3', '.5']) {
        expect(parseMinor(bad, 2), isNull, reason: bad);
      }
      expect(parseMinor('12.5', 0), isNull);
    });
  });
}
