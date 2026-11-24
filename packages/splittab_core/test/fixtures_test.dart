// Runs every shared fixture (fixtures/cases/*.json) through the Dart implementation.
// The fixtures' expected values were worked out by hand; the Python reference agrees with them.
import 'dart:convert';
import 'dart:io';

import 'package:splittab_core/splittab_core.dart';
import 'package:test/test.dart';

Directory _fixturesDir() {
  // `dart test` runs from the package root: packages/splittab_core
  for (final path in ['../../fixtures/cases', 'fixtures/cases']) {
    final d = Directory(path);
    if (d.existsSync()) return d;
  }
  throw StateError('fixtures/cases not found from ${Directory.current.path}');
}

List<(String, String, int)> _key(Iterable<Transfer> ts) =>
    ([for (final t in ts) (t.from, t.to, t.amount)]..sort((a, b) {
        final c = a.$1.compareTo(b.$1);
        if (c != 0) return c;
        final d = a.$2.compareTo(b.$2);
        return d != 0 ? d : a.$3.compareTo(b.$3);
      }));

List<(String, String, int)> _expectedKey(Object? plan) => _key([
      for (final p in plan as List<Object?>)
        Transfer((p as Map<String, Object?>)['from'] as String,
            p['to'] as String, p['amount'] as int),
    ]);

void main() {
  final files = _fixturesDir()
      .listSync()
      .whereType<File>()
      .where((f) => f.path.endsWith('.json'))
      .toList()
    ..sort((a, b) => a.path.compareTo(b.path));

  test('fixtures are present',
      () => expect(files.length, greaterThanOrEqualTo(45)));

  for (final file in files) {
    final json = jsonDecode(file.readAsStringSync()) as Map<String, Object?>;
    final expected = json['expected'] as Map<String, Object?>;

    test(json['id'] as String, () {
      final input = tripInputFromJson(json);

      if (expected.containsKey('error')) {
        expect(
          () => computeTrip(input.trip, input.expenses, input.payments),
          throwsA(isA<SplitError>()
              .having((e) => e.code, 'code', expected['error'])),
        );
        return;
      }

      final r = computeTrip(input.trip, input.expenses, input.payments);
      expect(r.balances,
          (expected['balances'] as Map<String, Object?>).cast<String, int>());

      final settle = expected['settle'] as Map<String, Object?>;
      expect(r.settle.minPayments, settle['min_payments']);
      if (settle.containsKey('plan')) {
        expect(_key(r.settle.plan), _expectedKey(settle['plan']));
      }
      if (expected.containsKey('direct')) {
        expect(_key(r.direct), _expectedKey(expected['direct']));
      }

      final totals = expected['expense_home_totals'] as Map<String, Object?>?;
      totals?.forEach((id, v) =>
          expect(r.expenses[id]!.totalHome, v, reason: 'home total of $id'));
      final owed = expected['expense_owed'] as Map<String, Object?>?;
      owed?.forEach((id, v) {
        expect(r.expenses[id]!.owed,
            (v as Map<String, Object?>).cast<String, int>(),
            reason: 'owed shares of $id');
      });

      // Properties that must hold for every valid trip.
      expect(r.balances.values.fold(0, (a, b) => a + b), 0,
          reason: 'balances sum to zero');
      final cleared = Map<String, int>.of(r.balances);
      for (final t in r.settle.plan) {
        cleared[t.from] = cleared[t.from]! + t.amount;
        cleared[t.to] = cleared[t.to]! - t.amount;
      }
      expect(cleared.values.every((v) => v == 0), isTrue,
          reason: 'plan clears every balance');
      final direct = {for (final m in r.balances.keys) m: 0};
      for (final t in r.direct) {
        direct[t.from] = direct[t.from]! + t.amount;
        direct[t.to] = direct[t.to]! - t.amount;
      }
      expect(direct, {for (final e in r.balances.entries) e.key: -e.value},
          reason: 'direct reconciles');
    });
  }
}
