import 'errors.dart';
import 'model.dart';
import 'money.dart';
import 'rational.dart';
import 'splits.dart';

/// Converts one expense to home currency, then works out who paid and who owes what.
ExpenseResult processExpense(Trip trip, Expense e) {
  final order = trip.members;
  final members = order.toSet();
  final tie = {for (var i = 0; i < order.length; i++) order[i]: i};
  final currency = e.currency ?? trip.homeCurrency;

  checkAmount(e.amount);
  for (final v in e.paidBy.values) {
    checkAmount(v);
  }
  for (final m in e.paidBy.keys) {
    if (!members.contains(m)) throw SplitError('unknown_member', m);
  }
  if (e.paidBy.values.fold(0, (a, b) => a + b) != e.amount) {
    throw const SplitError('payer_sum_mismatch');
  }

  final totalHome = toHomeMinor(
      e.amount, currency, e.rate, trip.homeCurrency, trip.currencyExponents);
  final weights = splitWeights(e.split, e.amount, members);

  final paid = {for (final m in order) m: 0};
  final owed = {for (final m in order) m: 0};
  if (e.amount != 0) {
    final payers = [
      for (final m in order)
        if (e.paidBy.containsKey(m)) m
    ];
    final paidShares = allocate(
      totalHome,
      [
        for (final m in payers)
          Rational(BigInt.from(e.paidBy[m]!), BigInt.from(e.amount))
      ],
      [for (final m in payers) tie[m]!],
    );
    for (var i = 0; i < payers.length; i++) {
      paid[payers[i]] = paidShares[i];
    }

    final owers = [
      for (final m in order)
        if (weights.containsKey(m)) m
    ];
    final owedShares = allocate(totalHome, [for (final m in owers) weights[m]!],
        [for (final m in owers) tie[m]!]);
    for (var i = 0; i < owers.length; i++) {
      owed[owers[i]] = owedShares[i];
    }
  }
  return ExpenseResult(
    totalHome: totalHome,
    paid: paid,
    owed: owed,
    net: {for (final m in order) m: paid[m]! - owed[m]!},
  );
}

/// Per-member balances (positive = is owed money) and per-expense detail.
({Map<String, int> balances, Map<String, ExpenseResult> expenses})
    computeBalances(
  Trip trip,
  List<Expense> expenses,
  List<Payment> payments,
) {
  final balances = {for (final m in trip.members) m: 0};
  final results = <String, ExpenseResult>{};
  for (final e in expenses) {
    final r = processExpense(trip, e);
    results[e.id] = r;
    for (final m in trip.members) {
      balances[m] = balances[m]! + r.net[m]!;
    }
  }
  final known = trip.members.toSet();
  for (final p in payments) {
    for (final m in [p.from, p.to]) {
      if (!known.contains(m)) throw SplitError('unknown_member', m);
    }
    checkAmount(p.amount);
    balances[p.from] = balances[p.from]! + p.amount;
    balances[p.to] = balances[p.to]! - p.amount;
  }
  return (balances: balances, expenses: results);
}
