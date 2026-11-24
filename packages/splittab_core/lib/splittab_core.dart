/// Exact money maths for SplitTab: splits, balances and settle-up.
///
/// Pure Dart, no I/O. The rules are specified by the shared fixtures in `fixtures/`.
library;

import 'src/balances.dart';
import 'src/direct.dart';
import 'src/model.dart';
import 'src/settle.dart';

export 'src/balances.dart' show computeBalances, processExpense;
export 'src/direct.dart' show directView;
export 'src/errors.dart';
export 'src/json.dart';
export 'src/model.dart';
export 'src/money.dart' show allocate, maxAmount, roundHalfAway, toHomeMinor;
export 'src/rational.dart';
export 'src/settle.dart' show greedyGroupPlan, optimalGroups, settleUp;
export 'src/splits.dart' show splitWeights;

/// Everything for a trip in one call: balances, the who-owes-whom view and the fewest-payments plan.
///
/// Throws [SplitError] (with a stable `code`) when the input is invalid.
TripResult computeTrip(Trip trip, List<Expense> expenses,
    [List<Payment> payments = const []]) {
  final r = computeBalances(trip, expenses, payments);
  return TripResult(
    balances: r.balances,
    expenses: r.expenses,
    direct: directView(trip, expenses, r.expenses, payments),
    settle: settleUp(r.balances, trip.members),
  );
}
