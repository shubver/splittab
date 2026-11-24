import 'package:splittab_core/splittab_core.dart';

import 'currencies.dart';

int _idCounter = 0;

/// A short unique id that is safe to create offline.
String newId() =>
    '${DateTime.now().microsecondsSinceEpoch.toRadixString(36)}${(_idCounter++).toRadixString(36)}';

class Member {
  final String id;
  final String name;
  const Member(this.id, this.name);

  Map<String, Object?> toJson() => {'id': id, 'name': name};
  factory Member.fromJson(Map<String, Object?> j) =>
      Member(j['id'] as String, j['name'] as String);
}

enum TripStatus { active, ended, settled }

/// An expense as the app stores it: the core expense plus the labels people see.
class ExpenseRecord {
  final Expense expense;
  final String title;
  final String category;
  final DateTime date;
  const ExpenseRecord({
    required this.expense,
    required this.title,
    required this.category,
    required this.date,
  });

  String get id => expense.id;

  Map<String, Object?> toJson() => {
    ...expenseToJson(expense),
    'title': title,
    'category': category,
    'date': date.toIso8601String(),
  };

  factory ExpenseRecord.fromJson(Map<String, Object?> j) => ExpenseRecord(
    expense: expenseFromJson(j),
    title: j['title'] as String,
    category: j['category'] as String,
    date: DateTime.parse(j['date'] as String),
  );
}

class AppTrip {
  final String id;
  String name;
  final String homeCurrency;
  final DateTime createdAt;
  TripStatus status;
  final String meId;
  final List<Member> members;
  final List<ExpenseRecord> expenses;
  final List<Payment> payments;

  /// "Same as last" defaults for the next expense.
  String? lastPayerId;
  List<String>? lastAmong;

  /// Last exchange rate used per foreign currency (home units per 1 unit), as decimal text.
  final Map<String, String> rates;

  AppTrip({
    required this.id,
    required this.name,
    required this.homeCurrency,
    required this.createdAt,
    required this.meId,
    required this.members,
    this.status = TripStatus.active,
    List<ExpenseRecord>? expenses,
    List<Payment>? payments,
    this.lastPayerId,
    this.lastAmong,
    Map<String, String>? rates,
  }) : expenses = expenses ?? [],
       payments = payments ?? [],
       rates = rates ?? {};

  Member member(String id) => members.firstWhere((m) => m.id == id);
  String nameOf(String id) => id == meId ? 'You' : member(id).name;

  /// How a person reads in a sentence: "pay you" versus "pays Maya".
  String asObject(String id) => id == meId ? 'you' : member(id).name;
  int get exponent => currencyOf(homeCurrency).exponent;

  Trip get coreTrip => Trip(
    homeCurrency: homeCurrency,
    members: [for (final m in members) m.id],
    currencyExponents: currencyExponents,
  );

  /// Runs the shared money maths. Throws [SplitError] if stored data is invalid.
  TripResult compute({List<ExpenseRecord> extra = const []}) =>
      computeTrip(coreTrip, [
        for (final e in [...expenses, ...extra]) e.expense,
      ], payments);

  Map<String, Object?> toJson() => {
    'id': id,
    'name': name,
    'home_currency': homeCurrency,
    'created_at': createdAt.toIso8601String(),
    'status': status.name,
    'me_id': meId,
    'members': [for (final m in members) m.toJson()],
    'expenses': [for (final e in expenses) e.toJson()],
    'payments': [for (final p in payments) paymentToJson(p)],
    if (lastPayerId != null) 'last_payer': lastPayerId,
    if (lastAmong != null) 'last_among': lastAmong,
    'rates': rates,
  };

  factory AppTrip.fromJson(Map<String, Object?> j) => AppTrip(
    id: j['id'] as String,
    name: j['name'] as String,
    homeCurrency: j['home_currency'] as String,
    createdAt: DateTime.parse(j['created_at'] as String),
    status: TripStatus.values.byName(j['status'] as String),
    meId: j['me_id'] as String,
    members: [
      for (final m in j['members'] as List<Object?>)
        Member.fromJson(m as Map<String, Object?>),
    ],
    expenses: [
      for (final e in j['expenses'] as List<Object?>)
        ExpenseRecord.fromJson(e as Map<String, Object?>),
    ],
    payments: [
      for (final p in j['payments'] as List<Object?>)
        paymentFromJson(p as Map<String, Object?>),
    ],
    lastPayerId: j['last_payer'] as String?,
    lastAmong: (j['last_among'] as List<Object?>?)?.cast<String>(),
    rates: (j['rates'] as Map<String, Object?>?)?.cast<String, String>(),
  );
}
