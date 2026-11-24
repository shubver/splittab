import 'dart:convert';

import 'package:material_ui/material_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'models.dart';

/// All trips, kept on the device. Everything works offline.
///
/// Storage is a simple JSON list for now. The shape (core fixture format plus labels) is what
/// will sync later; only this class changes when the sync layer arrives.
class AppState extends ChangeNotifier {
  static const _key = 'splittab.trips.v1';

  bool loading = true;
  final List<AppTrip> trips = [];

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    trips.clear();
    if (raw != null) {
      for (final t in jsonDecode(raw) as List<Object?>) {
        trips.add(AppTrip.fromJson(t as Map<String, Object?>));
      }
    }
    loading = false;
    notifyListeners();
  }

  AppTrip? trip(String id) {
    for (final t in trips) {
      if (t.id == id) return t;
    }
    return null;
  }

  void addTrip(AppTrip trip) {
    trips.insert(0, trip);
    save();
  }

  void deleteTrip(String id) {
    trips.removeWhere((t) => t.id == id);
    save();
  }

  /// Call after changing a trip in place: saves to the device and refreshes the screens.
  Future<void> save() async {
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _key,
      jsonEncode([for (final t in trips) t.toJson()]),
    );
  }
}

class AppScope extends InheritedNotifier<AppState> {
  const AppScope({super.key, required AppState state, required super.child})
    : super(notifier: state);

  static AppState of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<AppScope>();
    assert(scope != null, 'AppScope missing above this widget');
    return scope!.notifier!;
  }
}
