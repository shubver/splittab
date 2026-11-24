import 'errors.dart';
import 'model.dart';
import 'rational.dart';

/// A trip with its expenses and payments, as stored in the shared JSON fixtures
/// (`fixtures/cases/*.json`; format described in `fixtures/README.md`).
class TripInput {
  final Trip trip;
  final List<Expense> expenses;
  final List<Payment> payments;
  const TripInput(this.trip, this.expenses, this.payments);
}

Map<String, int> _intMap(Object? raw) => {
      for (final e in (raw as Map<String, Object?>).entries)
        e.key: e.value as int,
    };

Map<String, Rational> _decimalMap(Object? raw) => {
      for (final e in (raw as Map<String, Object?>).entries)
        e.key: Rational.parse(e.value as String),
    };

Split splitFromJson(Map<String, Object?> json) {
  switch (json['type']) {
    case 'equal':
      return EqualSplit(
          [for (final m in json['among'] as List<Object?>) m as String]);
    case 'exact':
      return ExactSplit(_intMap(json['amounts']));
    case 'percent':
      return PercentSplit(_decimalMap(json['percents']));
    case 'shares':
      return SharesSplit(_decimalMap(json['shares']));
    case 'nights':
      final stays = json['nights'] as Map<String, Object?>;
      return NightsSplit(
        totalNights: json['total_nights'] as int,
        nights: {
          for (final e in stays.entries)
            e.key: [for (final n in e.value as List<Object?>) n as int],
        },
      );
    default:
      throw SplitError('invalid_split_type', '${json['type']}');
  }
}

Expense expenseFromJson(Map<String, Object?> json) => Expense(
      id: json['id'] as String,
      amount: json['amount'] as int,
      currency: json['currency'] as String?,
      rate:
          json['rate'] == null ? null : Rational.parse(json['rate'] as String),
      paidBy: _intMap(json['paid_by']),
      split: splitFromJson(json['split'] as Map<String, Object?>),
    );

Payment paymentFromJson(Map<String, Object?> json) => Payment(
    from: json['from'] as String,
    to: json['to'] as String,
    amount: json['amount'] as int);

/// Reads a fixture case's input (`trip`, `currency_exponents`, `expenses`, `payments`).
TripInput tripInputFromJson(Map<String, Object?> json) {
  final trip = json['trip'] as Map<String, Object?>;
  return TripInput(
    Trip(
      homeCurrency: trip['home_currency'] as String,
      members: [for (final m in trip['members'] as List<Object?>) m as String],
      currencyExponents: json['currency_exponents'] == null
          ? const {}
          : _intMap(json['currency_exponents']),
    ),
    [
      for (final e in json['expenses'] as List<Object?>)
        expenseFromJson(e as Map<String, Object?>),
    ],
    [
      for (final p in (json['payments'] as List<Object?>?) ?? const <Object?>[])
        paymentFromJson(p as Map<String, Object?>),
    ],
  );
}

Map<String, Object?> splitToJson(Split split) => switch (split) {
      EqualSplit(:final among) => {'type': 'equal', 'among': among},
      ExactSplit(:final amounts) => {'type': 'exact', 'amounts': amounts},
      PercentSplit(:final percents) => {
          'type': 'percent',
          'percents': {
            for (final e in percents.entries) e.key: e.value.toDecimalString()
          },
        },
      SharesSplit(:final shares) => {
          'type': 'shares',
          'shares': {
            for (final e in shares.entries) e.key: e.value.toDecimalString()
          },
        },
      NightsSplit(:final totalNights, :final nights) => {
          'type': 'nights',
          'total_nights': totalNights,
          'nights': nights,
        },
    };

Map<String, Object?> expenseToJson(Expense e) => {
      'id': e.id,
      'amount': e.amount,
      if (e.currency != null) 'currency': e.currency,
      if (e.rate != null) 'rate': e.rate!.toDecimalString(),
      'paid_by': e.paidBy,
      'split': splitToJson(e.split),
    };

Map<String, Object?> paymentToJson(Payment p) =>
    {'from': p.from, 'to': p.to, 'amount': p.amount};

/// Inverse of [tripInputFromJson]: writes the same format the fixtures use.
Map<String, Object?> tripInputToJson(TripInput input) => {
      'trip': {
        'home_currency': input.trip.homeCurrency,
        'members': input.trip.members
      },
      'currency_exponents': input.trip.currencyExponents,
      'expenses': [for (final e in input.expenses) expenseToJson(e)],
      'payments': [for (final p in input.payments) paymentToJson(p)],
    };

Map<String, Object?> _transferJson(Transfer t) =>
    {'from': t.from, 'to': t.to, 'amount': t.amount};

/// Runs a fixture-format input and returns the result as plain JSON-able data:
/// `{balances, min_payments, plan, direct, expense_home_totals, expense_owed}`
/// or `{error: code}`. Used by the cross-implementation tests (Dart VM and Dart compiled to JS).
Map<String, Object?> computeCaseJson(
    Map<String, Object?> caseJson, TripResult Function(TripInput) run) {
  try {
    final r = run(tripInputFromJson(caseJson));
    return {
      'balances': r.balances,
      'min_payments': r.settle.minPayments,
      'plan': [for (final t in r.settle.plan) _transferJson(t)],
      'direct': [for (final t in r.direct) _transferJson(t)],
      'expense_home_totals': {
        for (final e in r.expenses.entries) e.key: e.value.totalHome
      },
      'expense_owed': {for (final e in r.expenses.entries) e.key: e.value.owed},
    };
  } on SplitError catch (e) {
    return {'error': e.code};
  }
}
