import 'model.dart';

/// Attributes one expense's nets to who-pays-whom: two-pointer match in member order.
List<Transfer> expenseTransfers(Map<String, int> net, List<String> order) {
  final debtors = [
    for (final m in order)
      if (net[m]! < 0) _Slot(m, -net[m]!),
  ];
  final creditors = [
    for (final m in order)
      if (net[m]! > 0) _Slot(m, net[m]!),
  ];
  final out = <Transfer>[];
  var i = 0, j = 0;
  while (i < debtors.length && j < creditors.length) {
    final d = debtors[i], c = creditors[j];
    final amount = d.amount < c.amount ? d.amount : c.amount;
    out.add(Transfer(d.member, c.member, amount));
    d.amount -= amount;
    c.amount -= amount;
    if (d.amount == 0) i++;
    if (c.amount == 0) j++;
  }
  return out;
}

class _Slot {
  final String member;
  int amount;
  _Slot(this.member, this.amount);
}

/// The explainable "who owes whom" view: per-expense attribution, reduced by payments, netted per
/// pair of members, sorted by (from, to) member order. Always reconciles with the balances.
List<Transfer> directView(
  Trip trip,
  List<Expense> expenses,
  Map<String, ExpenseResult> results,
  List<Payment> payments,
) {
  final order = trip.members;
  final idx = {for (var i = 0; i < order.length; i++) order[i]: i};
  // Key = (lower index, higher index); value > 0 means the lower-index member owes the higher one.
  final flow = <(int, int), int>{};

  void add(String a, String b, int amount) {
    final ia = idx[a]!, ib = idx[b]!;
    final key = ia < ib ? (ia, ib) : (ib, ia);
    flow[key] = (flow[key] ?? 0) + (ia < ib ? amount : -amount);
  }

  for (final e in expenses) {
    for (final t in expenseTransfers(results[e.id]!.net, order)) {
      add(t.from, t.to, t.amount);
    }
  }
  for (final p in payments) {
    // Paying someone REDUCES what you owe them, so it counts against the debt direction.
    add(p.to, p.from, p.amount);
  }

  final out = <Transfer>[];
  for (final e in flow.entries) {
    final (a, b) = e.key;
    if (e.value > 0) out.add(Transfer(order[a], order[b], e.value));
    if (e.value < 0) out.add(Transfer(order[b], order[a], -e.value));
  }
  out.sort((x, y) {
    final c = idx[x.from]!.compareTo(idx[y.from]!);
    return c != 0 ? c : idx[x.to]!.compareTo(idx[y.to]!);
  });
  return out;
}
