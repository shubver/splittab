// ignore_for_file: invalid_use_of_visible_for_testing_member
// Renders the real screens (real fonts, phone size) to PNG files so the design can be checked by eye.
//
//   SHOTS_DIR=/some/folder flutter test tool/screenshots_test.dart
//
// Not part of the normal test run (it lives in tool/, not test/).
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart' show FontLoader, rootBundle;
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart' hide Split;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:splittab/data/models.dart';
import 'package:splittab/data/store.dart';
import 'package:splittab/main.dart';
import 'package:splittab_core/splittab_core.dart';

final _key = GlobalKey();
late String _dir;

Future<void> _snap(WidgetTester tester, String name) async {
  await tester.pumpAndSettle();
  await tester.runAsync(() async {
    final boundary =
        _key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
    final image = await boundary.toImage(pixelRatio: 2);
    final bytes = (await image.toByteData(format: ui.ImageByteFormat.png))!;
    await File('$_dir/$name.png').writeAsBytes(bytes.buffer.asUint8List());
  });
}

Future<void> _pump(
  WidgetTester tester,
  AppState state, {
  bool dark = false,
}) async {
  tester.view.physicalSize = const Size(390 * 2, 844 * 2);
  tester.view.devicePixelRatio = 2;
  tester.platformDispatcher.platformBrightnessTestValue = dark
      ? Brightness.dark
      : Brightness.light;
  addTearDown(tester.view.reset);
  addTearDown(tester.platformDispatcher.clearAllTestValues);
  await tester.pumpWidget(
    RepaintBoundary(
      key: _key,
      child: SplitTabApp(state: state),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> _type(WidgetTester tester, int i, String text) async {
  await tester.enterText(find.byType(TextField).at(i), text);
  await tester.pump();
}

AppState _seed({bool ended = false}) {
  final asha = 'asha', ben = 'ben', chitra = 'chitra', dev = 'dev';
  ExpenseRecord rec(
    String id,
    String title,
    String cat,
    int amount,
    String payer,
    List<String> among,
    int day, {
    String? currency,
    String? rate,
    Split? split,
  }) {
    return ExpenseRecord(
      expense: Expense(
        id: id,
        amount: amount,
        currency: currency,
        rate: rate == null ? null : Rational.parse(rate),
        paidBy: {payer: amount},
        split: split ?? EqualSplit(among),
      ),
      title: title,
      category: cat,
      date: DateTime(2026, 11, day),
    );
  }

  final all = [asha, ben, chitra, dev];
  final trip = AppTrip(
    id: 'goa',
    name: 'Goa with the gang',
    homeCurrency: 'INR',
    createdAt: DateTime(2026, 11, 8),
    meId: asha,
    members: [
      Member(asha, 'Asha'),
      Member(ben, 'Ben'),
      Member(chitra, 'Chitra'),
      Member(dev, 'Dev'),
    ],
    status: ended ? TripStatus.ended : TripStatus.active,
    expenses: [
      rec('e1', 'Hotel in Anjuna, 3 nights', 'stay', 2400000, asha, all, 8),
      rec('e2', 'Scooter rental', 'vehicle_rental', 360000, ben, [
        ben,
        chitra,
      ], 9),
      rec('e3', 'Petrol', 'fuel', 120000, ben, [ben, chitra], 9),
      rec('e4', 'Beach shack dinner', 'food', 480000, asha, all, 9),
      rec(
        'e5',
        'Spice farm tour',
        'activities',
        6000,
        dev,
        [asha, ben, dev],
        10,
        currency: 'USD',
        rate: '83.20',
      ),
      rec('e6', 'Souvenirs', 'shopping', 90000, chitra, [chitra], 10),
      rec('e7', 'Taxi to the airport', 'local_transport', 145000, dev, all, 11),
    ],
  );
  final state = AppState()..loading = false;
  state.trips.add(trip);
  state.trips.add(
    AppTrip(
      id: 'hills',
      name: 'Weekend in Coorg',
      homeCurrency: 'INR',
      createdAt: DateTime(2026, 9, 2),
      meId: 'm1',
      status: TripStatus.settled,
      members: [const Member('m1', 'Asha'), const Member('m2', 'Ben')],
    ),
  );
  return state;
}

void main() {
  setUpAll(() async {
    _dir =
        Platform.environment['SHOTS_DIR'] ??
        '${Directory.systemTemp.path}/splittab_shots';
    Directory(_dir).createSync(recursive: true);
    for (final (family, asset) in [
      ('Geist', 'assets/fonts/Geist-Variable.ttf'),
      ('Phosphor', 'assets/fonts/Phosphor.ttf'),
    ]) {
      final loader = FontLoader(family)..addFont(rootBundle.load(asset));
      await loader.load();
    }
  });
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('first run and new trip', (tester) async {
    await _pump(tester, AppState());
    await _snap(tester, '01_empty');
    await tester.tap(find.text('Create a trip'));
    await tester.pumpAndSettle();
    await _type(tester, 0, 'Goa with the gang');
    await _type(tester, 1, 'Asha');
    await _type(tester, 2, 'Ben');
    await tester.tap(find.text('Add'));
    await tester.pumpAndSettle();
    await _snap(tester, '02_new_trip');
  });

  testWidgets('trip, active', (tester) async {
    await _pump(tester, _seed());
    await _snap(tester, '03_trips_list');
    await tester.tap(find.text('Goa with the gang'));
    await _snap(tester, '04_trip_expenses');
    await tester.tap(find.text('Balances'));
    await _snap(tester, '05_trip_balances');
    await tester.tap(find.text('Ben'));
    await _snap(tester, '06_explain_sheet');
  });

  testWidgets('add expense and bulk add', (tester) async {
    await _pump(tester, _seed());
    await tester.tap(find.text('Goa with the gang'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Add expense').last);
    await tester.pumpAndSettle();
    await _type(tester, 0, '2400');
    await _type(tester, 1, 'Sunset cruise');
    await _snap(tester, '07_add_expense');
    await tester.tap(find.text('Customize'));
    await tester.pumpAndSettle();
    await _snap(tester, '08_custom_split');
    await tester.tapAt(const Offset(10, 10));
    await tester.pumpAndSettle();
  });

  testWidgets('bulk add screen', (tester) async {
    await _pump(tester, _seed());
    await tester.tap(find.text('Goa with the gang'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Bulk add').last);
    await tester.pumpAndSettle();
    await _type(tester, 0, 'Breakfast');
    await _type(tester, 1, '640');
    await _type(tester, 2, 'Parking');
    await _type(tester, 3, '120');
    await _type(tester, 4, 'Cold drinks');
    await _snap(tester, '09_bulk_add');
    await _type(tester, 5, 'abc');
    await tester.tap(find.textContaining('Add 3'));
    await _snap(tester, '10_bulk_add_error');
  });

  testWidgets('settle up', (tester) async {
    await _pump(tester, _seed(ended: true));
    await tester.tap(find.text('Goa with the gang'));
    await _snap(tester, '11_settle');
    await tester.tap(find.text('Who owes whom'));
    await _snap(tester, '12_settle_direct');
  });

  testWidgets('dark mode', (tester) async {
    await _pump(tester, _seed(), dark: true);
    await _snap(tester, '13_dark_trips');
    await tester.tap(find.text('Goa with the gang'));
    await _snap(tester, '14_dark_trip');
  });
}
