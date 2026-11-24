import 'dart:ui' show Size;

import 'package:flutter/services.dart' show FontLoader, rootBundle;
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart' show TextField;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:splittab/data/models.dart';
import 'package:splittab/data/store.dart';
import 'package:splittab/main.dart';
import 'package:splittab_core/splittab_core.dart';

void _phone(WidgetTester tester) {
  tester.view.physicalSize = const Size(390 * 3, 844 * 3);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
}

/// Lets a confirmation message disappear on its own, the way a person would wait for it.
Future<void> _waitForNotice(WidgetTester tester) async {
  await tester.pump(const Duration(seconds: 5));
  await tester.pumpAndSettle();
}

Future<void> _type(WidgetTester tester, int fieldIndex, String text) async {
  await tester.enterText(find.byType(TextField).at(fieldIndex), text);
  await tester.pump();
}

/// Tests normally draw every letter as a wide square. Loading the real fonts makes layout
/// (and overflow) behave like the real app.
Future<void> _loadFonts() async {
  for (final (family, asset) in [
    ('Geist', 'assets/fonts/Geist-Variable.ttf'),
    ('Phosphor', 'assets/fonts/Phosphor.ttf'),
  ]) {
    final loader = FontLoader(family)..addFont(rootBundle.load(asset));
    await loader.load();
  }
}

void main() {
  setUpAll(_loadFonts);
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('create a trip, add expenses, end it and settle up', (
    tester,
  ) async {
    _phone(tester);
    final state = AppState();
    await tester.pumpWidget(SplitTabApp(state: state));
    await tester.pumpAndSettle();

    // Empty state first
    expect(find.text('No trips yet'), findsOneWidget);
    await tester.tap(find.text('Create a trip'));
    await tester.pumpAndSettle();

    // Validation is inline
    await tester.tap(find.text('Create trip'));
    await tester.pumpAndSettle();
    expect(find.text('Give the trip a name.'), findsOneWidget);
    expect(find.text('Enter your name.'), findsOneWidget);
    expect(find.text('Add at least one friend to split with.'), findsOneWidget);

    await _type(tester, 0, 'Goa trip');
    await _type(tester, 1, 'Asha');
    await _type(tester, 2, 'Ben');
    await tester.tap(find.text('Add'));
    await tester.pumpAndSettle();
    await _type(tester, 2, 'Chitra');
    await tester.tap(find.text('Create trip'));
    await tester.pumpAndSettle();

    // On the trip screen
    expect(find.text('Goa trip'), findsOneWidget);
    expect(find.text('You are even'), findsOneWidget);
    expect(find.text('No expenses yet'), findsOneWidget);

    // Add one expense: 90.00 paid by you, split three ways
    await tester.tap(find.text('Add expense').last);
    await tester.pumpAndSettle();
    await _type(tester, 0, '90');
    await _type(tester, 1, 'Beach shack dinner');
    await tester.tap(find.text('Save expense'));
    await tester.pumpAndSettle();

    expect(find.text('Beach shack dinner'), findsOneWidget);
    expect(find.text('You are owed'), findsOneWidget);
    expect(find.text(r'$60.00'), findsOneWidget); // 90 minus your own 30
    expect(state.trips.single.expenses, hasLength(1));

    // Bulk add two rows
    await tester.tap(find.text('Bulk add').last);
    await tester.pumpAndSettle();
    await _type(tester, 0, 'Taxi');
    await _type(tester, 1, '30');
    await _type(tester, 2, 'Fuel');
    await _type(tester, 3, '45.50');
    expect(find.text('Add 2 expenses'), findsOneWidget);
    await tester.tap(find.text('Add 2 expenses'));
    await tester.pumpAndSettle();
    expect(state.trips.single.expenses, hasLength(3));
    await _waitForNotice(tester);

    // Balances: tap Ben to see how his number adds up
    await tester.tap(find.text('Balances'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Ben'));
    await tester.pumpAndSettle();
    expect(find.text("How Ben's balance adds up"), findsOneWidget);
    await tester.tapAt(const Offset(10, 10)); // dismiss the sheet
    await tester.pumpAndSettle();

    // End the trip, then settle
    await tester.tap(find.text('End trip').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('End trip').last);
    await tester.pumpAndSettle();
    expect(state.trips.single.status, TripStatus.ended);
    expect(find.text('Settle up'), findsOneWidget);
    expect(find.text('Mark as paid'), findsNWidgets(2));
    expect(find.text('Add expense'), findsNothing); // locked after ending

    await tester.tap(find.text('Mark as paid').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Mark as paid').first);
    await tester.pumpAndSettle();
    expect(find.text('Everyone is settled.'), findsOneWidget);
    expect(state.trips.single.status, TripStatus.settled);
  });

  testWidgets('foreign currency expenses need a rate and are converted', (
    tester,
  ) async {
    _phone(tester);
    final me = newId(), friend = newId();
    final trip = AppTrip(
      id: newId(),
      name: 'Europe',
      homeCurrency: 'USD',
      createdAt: DateTime(2026, 11, 1),
      meId: me,
      members: [Member(me, 'Asha'), Member(friend, 'Ben')],
    );
    final state = AppState()..loading = false;
    state.trips.add(trip);
    await tester.pumpWidget(SplitTabApp(state: state));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Europe'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Add expense').last);
    await tester.pumpAndSettle();

    await tester.tap(find.text('USD'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('EUR'));
    await tester.pumpAndSettle();

    await _type(tester, 0, '100');
    await tester.tap(find.text('Save expense'));
    await tester.pumpAndSettle();
    expect(find.text('Enter the exchange rate, like 83.2.'), findsOneWidget);

    await _type(tester, 1, '1.10');
    await tester.tap(find.text('Save expense'));
    await tester.pumpAndSettle();

    expect(trip.expenses.single.expense.currency, 'EUR');
    expect(trip.compute().expenses.values.single.totalHome, 11000);
    expect(find.text(r'$110.00'), findsWidgets);
  });

  testWidgets('trips survive a restart', (tester) async {
    final me = newId(), friend = newId();
    final trip = AppTrip(
      id: newId(),
      name: 'Hills',
      homeCurrency: 'INR',
      createdAt: DateTime(2026, 11, 1),
      meId: me,
      members: [Member(me, 'Asha'), Member(friend, 'Ben')],
    );
    trip.expenses.add(
      ExpenseRecord(
        expense: Expense(
          id: newId(),
          amount: 120000,
          paidBy: {me: 120000},
          split: EqualSplit([me, friend]),
        ),
        title: 'Cottage',
        category: 'stay',
        date: DateTime(2026, 11, 2),
      ),
    );
    final first = AppState()..loading = false;
    first.trips.add(trip);
    await first.save();

    final second = AppState();
    await second.load();
    expect(second.trips.single.name, 'Hills');
    expect(second.trips.single.compute().balances[me], 60000);
    expect(second.loading, isFalse);
  });
}
