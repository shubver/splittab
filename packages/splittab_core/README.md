# splittab_core

Exact money maths for SplitTab: splits, balances and settle-up. **Pure Dart, no I/O, no floating point.**
The app (Flutter) and the guest web page both use it, so every screen shows the same numbers, offline.

The rules are specified by the shared fixtures in [`../../fixtures`](../../fixtures/README.md).

```dart
import 'package:splittab_core/splittab_core.dart';

final trip = Trip(homeCurrency: 'USD', members: ['alice', 'bob', 'carol']);
final dinner = Expense(
  id: 'e1',
  amount: 9000,                       // minor units: $90.00
  paidBy: {'alice': 9000},
  split: EqualSplit(['alice', 'bob', 'carol']),
);

final r = computeTrip(trip, [dinner]);
r.balances;       // {alice: 6000, bob: -3000, carol: -3000}   positive = is owed money
r.direct;         // who owes whom, explainable per expense
r.settle.plan;    // fewest payments that clear everything
```
Invalid input throws `SplitError` with a stable `code` (`split_sum_mismatch`, `missing_rate`, ...).

## Rules worth knowing
- Amounts are integers in minor units. Rates and percentages are exact decimal strings (`Rational.parse`).
- Intermediate maths uses `BigInt`/`Rational`, so nothing overflows or loses precision, including on Flutter web.
- Amounts above `maxAmount` (9 trillion minor units) are rejected, which keeps plain-`int` sums exact on web.
- Leftover cents go to the first member in `trip.members` order.

## Checks (run from this folder)
```bash
dart pub get
dart analyze
dart test                                   # 49 shared fixtures + 400 random cases + unit tests
dart compile js -O1 -o build/core.js tool/web_entry.dart && node tool/web_check.js
                                            # same cases under JavaScript numbers (Flutter web)
```
The Python reference lives in `../../fixtures/reference` (`python3 -m pytest fixtures/reference -q` from the repo root).
