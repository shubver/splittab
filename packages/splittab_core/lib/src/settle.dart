import 'model.dart';

/// Above this many members with a non-zero balance the exact search is skipped
/// (2^n memory) and one group with a greedy plan is used instead.
const int maxExactSettleMembers = 20;

/// Partitions the members with non-zero balances into the MAXIMUM number of zero-sum groups.
///
/// A group of k members needs k-1 payments, so payments = non-zero members - groups.
/// Bitmask DP: dp[mask] = best over the choice of last member of dp[rest] + (sum(mask) == 0).
List<List<String>> optimalGroups(
    Map<String, int> balances, List<String> order) {
  final nz = [
    for (final m in order)
      if (balances[m] != 0) m,
  ];
  final n = nz.length;
  if (n == 0) return [];
  if (n > maxExactSettleMembers) return [nz];

  final size = 1 << n;
  final sums = List<int>.filled(size, 0);
  for (var mask = 1; mask < size; mask++) {
    final low = _bitIndex(mask & -mask);
    sums[mask] = sums[mask & (mask - 1)] + balances[nz[low]]!;
  }
  final dp = List<int>.filled(size, 0);
  final choice = List<int>.filled(size, 0);
  for (var mask = 1; mask < size; mask++) {
    var best = -1, bestBit = 0;
    var rest = mask;
    while (rest != 0) {
      final bit = rest & -rest;
      final v = dp[mask ^ bit];
      if (v > best) {
        best = v;
        bestBit = bit;
      }
      rest ^= bit;
    }
    dp[mask] = best + (sums[mask] == 0 ? 1 : 0);
    choice[mask] = bestBit;
  }

  // Walk back through the nested prefixes; zero-sum prefixes mark group boundaries.
  final zeroMasks = <int>[];
  var mask = size - 1;
  while (mask != 0) {
    if (sums[mask] == 0) zeroMasks.add(mask);
    mask ^= choice[mask];
  }
  zeroMasks.add(0);
  final groups = <List<String>>[];
  for (var k = 0; k < zeroMasks.length - 1; k++) {
    final g = zeroMasks[k] & ~zeroMasks[k + 1];
    groups.add([
      for (var i = 0; i < n; i++)
        if ((g >> i) & 1 == 1) nz[i],
    ]);
  }
  return groups;
}

int _bitIndex(int singleBit) => singleBit.bitLength - 1;

/// Inside one group: repeatedly pay the largest remaining debt to the largest remaining credit
/// (ties: lower member index).
List<Transfer> greedyGroupPlan(
    List<String> group, Map<String, int> balances, List<String> order) {
  final idx = {for (var i = 0; i < order.length; i++) order[i]: i};
  final credits = <_Slot>[
    for (final m in group)
      if (balances[m]! > 0) _Slot(m, balances[m]!),
  ];
  final debts = <_Slot>[
    for (final m in group)
      if (balances[m]! < 0) _Slot(m, -balances[m]!),
  ];

  _Slot largest(List<_Slot> slots) {
    var best = slots.first;
    for (final s in slots.skip(1)) {
      if (s.amount > best.amount ||
          (s.amount == best.amount && idx[s.member]! < idx[best.member]!)) {
        best = s;
      }
    }
    return best;
  }

  final plan = <Transfer>[];
  while (debts.isNotEmpty && credits.isNotEmpty) {
    final d = largest(debts), c = largest(credits);
    final amount = d.amount < c.amount ? d.amount : c.amount;
    plan.add(Transfer(d.member, c.member, amount));
    d.amount -= amount;
    c.amount -= amount;
    if (d.amount == 0) debts.remove(d);
    if (c.amount == 0) credits.remove(c);
  }
  return plan;
}

class _Slot {
  final String member;
  int amount;
  _Slot(this.member, this.amount);
}

/// The fewest payments that clear every balance.
SettlePlan settleUp(Map<String, int> balances, List<String> order) {
  final plan = [
    for (final group in optimalGroups(balances, order))
      ...greedyGroupPlan(group, balances, order),
  ];
  return SettlePlan(plan.length, plan);
}
