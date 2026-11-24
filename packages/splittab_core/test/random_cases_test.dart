// Cross-implementation check: 400 random trips whose expected results come from the Python
// reference (fixtures/reference/make_fuzz.py). Dart must match exactly, errors included.
import 'dart:convert';
import 'dart:io';

import 'package:splittab_core/splittab_core.dart';
import 'package:test/test.dart';

void main() {
  final file = [
    '../../fixtures/fuzz/random-cases.json',
    'fixtures/fuzz/random-cases.json'
  ].map(File.new).firstWhere((f) => f.existsSync());
  final cases = (jsonDecode(file.readAsStringSync()) as List<Object?>)
      .cast<Map<String, Object?>>();

  test('random cases are present', () => expect(cases.length, 400));

  test('Dart matches the Python reference on every random case', () {
    var valid = 0;
    for (final c in cases) {
      final expected = c['expected'] as Map<String, Object?>;
      final got = computeCaseJson(
          c, (i) => computeTrip(i.trip, i.expenses, i.payments));
      final id = c['id'];
      if (expected.containsKey('error')) {
        expect(got, {'error': expected['error']}, reason: '$id');
        continue;
      }
      valid++;
      expect(got['balances'], expected['balances'], reason: '$id balances');
      expect(got['min_payments'], expected['min_payments'],
          reason: '$id min payments');
      expect(got['direct'], expected['direct'], reason: '$id direct');
      expect(got['expense_home_totals'], expected['expense_home_totals'],
          reason: '$id totals');
      expect(got['expense_owed'], expected['expense_owed'], reason: '$id owed');
      // the plan itself may differ between equally good groupings; it must still clear all balances
      final cleared =
          Map<String, int>.of((got['balances'] as Map<String, int>));
      for (final t in got['plan'] as List<Map<String, Object?>>) {
        cleared[t['from'] as String] =
            cleared[t['from']]! + (t['amount'] as int);
        cleared[t['to'] as String] = cleared[t['to']]! - (t['amount'] as int);
      }
      expect(cleared.values.every((v) => v == 0), isTrue,
          reason: '$id plan clears balances');
    }
    expect(valid, greaterThan(300));
  });
}
