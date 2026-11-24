class Currency {
  final String code;
  final String name;
  final String symbol;

  /// Decimal places of the minor unit (USD 2, JPY 0, KWD 3).
  final int exponent;
  const Currency(this.code, this.name, this.symbol, this.exponent);
}

const List<Currency> currencies = [
  Currency('USD', 'US dollar', r'$', 2),
  Currency('EUR', 'Euro', '€', 2),
  Currency('GBP', 'British pound', '£', 2),
  Currency('INR', 'Indian rupee', '₹', 2),
  Currency('JPY', 'Japanese yen', '¥', 0),
  Currency('AUD', 'Australian dollar', r'A$', 2),
  Currency('CAD', 'Canadian dollar', r'C$', 2),
  Currency('CHF', 'Swiss franc', 'CHF ', 2),
  Currency('SGD', 'Singapore dollar', r'S$', 2),
  Currency('THB', 'Thai baht', '฿', 2),
  Currency('AED', 'UAE dirham', 'AED ', 2),
  Currency('VND', 'Vietnamese dong', '₫', 0),
  Currency('KWD', 'Kuwaiti dinar', 'KWD ', 3),
];

Currency currencyOf(String code) => currencies.firstWhere(
  (c) => c.code == code,
  orElse: () => Currency(code, code, '$code ', 2),
);

/// Exponents for every supported currency, in the form the core package expects.
final Map<String, int> currencyExponents = {
  for (final c in currencies) c.code: c.exponent,
};

const String _minus = '−';

/// "1,234.50" style text for [minor] units. A negative amount uses a real minus sign.
String formatNumber(int minor, int exponent) {
  final negative = minor < 0;
  final digits = minor.abs().toString().padLeft(exponent + 1, '0');
  final whole = digits.substring(0, digits.length - exponent);
  final fraction = exponent == 0
      ? ''
      : '.${digits.substring(digits.length - exponent)}';
  final grouped = whole.replaceAllMapped(
    RegExp(r'\B(?=(\d{3})+(?!\d))'),
    (_) => ',',
  );
  return '${negative ? _minus : ''}$grouped$fraction';
}

/// "$90.00", "₹1,200.00", "¥1,500". With [showPlus], positive amounts get a leading plus.
String formatMoney(int minor, String code, {bool showPlus = false}) {
  final c = currencyOf(code);
  final body = formatNumber(minor.abs(), c.exponent);
  final sign = minor < 0 ? _minus : (showPlus && minor > 0 ? '+' : '');
  return '$sign${c.symbol}$body';
}

/// Reads what someone typed into an amount field. Returns null when it is empty, not a number,
/// or has more decimals than the currency allows. Commas and spaces are ignored.
int? parseMinor(String text, int exponent) {
  final cleaned = text.replaceAll(RegExp(r'[,\s]'), '');
  final m = RegExp(r'^(\d+)(?:\.(\d*))?$').firstMatch(cleaned);
  if (m == null) return null;
  final fraction = m.group(2) ?? '';
  if (fraction.length > exponent) return null;
  final padded = fraction.padRight(exponent, '0');
  final value = int.tryParse('${m.group(1)}$padded');
  return value;
}
