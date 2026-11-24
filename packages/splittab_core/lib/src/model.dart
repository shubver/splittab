import 'rational.dart';

/// A trip: who is in it, which currency totals are shown in, and each currency's minor units.
///
/// The ORDER of [members] matters: it breaks ties when a leftover minor unit has to be handed out.
class Trip {
  final String homeCurrency;
  final List<String> members;

  /// Number of minor-unit decimals per currency (USD 2, JPY 0, KWD 3...).
  /// Needed for every currency that is converted, including the home currency.
  final Map<String, int> currencyExponents;

  const Trip({
    required this.homeCurrency,
    required this.members,
    this.currencyExponents = const {},
  });
}

/// How an expense is divided. See `fixtures/README.md` for the exact rules.
sealed class Split {
  const Split();
}

class EqualSplit extends Split {
  final List<String> among;
  const EqualSplit(this.among);
}

class ExactSplit extends Split {
  /// Minor units of the expense currency; must sum to the expense amount.
  final Map<String, int> amounts;
  const ExactSplit(this.amounts);
}

class PercentSplit extends Split {
  /// Must be >= 0 and sum to exactly 100.
  final Map<String, Rational> percents;
  const PercentSplit(this.percents);
}

class SharesSplit extends Split {
  /// Relative weights, >= 0, with a positive sum.
  final Map<String, Rational> shares;
  const SharesSplit(this.shares);
}

class NightsSplit extends Split {
  final int totalNights;

  /// Member -> the nights (1..totalNights) they stayed.
  final Map<String, List<int>> nights;
  const NightsSplit({required this.totalNights, required this.nights});
}

class Expense {
  final String id;

  /// Minor units of [currency]. Negative = refund.
  final int amount;

  /// Defaults to the trip's home currency.
  final String? currency;

  /// Home-currency MAJOR units per 1 MAJOR unit of [currency]. Required when [currency] is foreign.
  final Rational? rate;

  /// Minor units of [currency]; must sum to [amount].
  final Map<String, int> paidBy;
  final Split split;

  const Expense({
    required this.id,
    required this.amount,
    required this.paidBy,
    required this.split,
    this.currency,
    this.rate,
  });
}

/// A real-world payment between two members, in home-currency minor units.
class Payment {
  final String from;
  final String to;
  final int amount;
  const Payment({required this.from, required this.to, required this.amount});
}

/// "[from] pays [to] [amount]" (home-currency minor units).
class Transfer {
  final String from;
  final String to;
  final int amount;
  const Transfer(this.from, this.to, this.amount);

  @override
  bool operator ==(Object other) =>
      other is Transfer &&
      from == other.from &&
      to == other.to &&
      amount == other.amount;

  @override
  int get hashCode => Object.hash(from, to, amount);

  @override
  String toString() => '$from -> $to $amount';
}

/// The fewest-payments plan that settles every balance.
class SettlePlan {
  final int minPayments;
  final List<Transfer> plan;
  const SettlePlan(this.minPayments, this.plan);
}

/// One expense after conversion and splitting, all in home-currency minor units.
class ExpenseResult {
  final int totalHome;
  final Map<String, int> paid;
  final Map<String, int> owed;

  /// paid - owed per member; sums to zero.
  final Map<String, int> net;
  const ExpenseResult(
      {required this.totalHome,
      required this.paid,
      required this.owed,
      required this.net});
}

class TripResult {
  /// Positive = is owed money. Sums to zero.
  final Map<String, int> balances;
  final Map<String, ExpenseResult> expenses;

  /// Who-owes-whom explanation of the balances (see `fixtures/README.md`).
  final List<Transfer> direct;
  final SettlePlan settle;
  const TripResult({
    required this.balances,
    required this.expenses,
    required this.direct,
    required this.settle,
  });
}
