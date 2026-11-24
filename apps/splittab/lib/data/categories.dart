import 'package:material_ui/material_ui.dart';

import '../design/icons.dart';

/// The travel categories (see docs/research/04-travel-categories.md).
class ExpenseCategory {
  final String id;
  final String label;
  final IconData icon;

  /// Shopping is usually for one person, so it starts as "just me".
  final bool justMe;
  const ExpenseCategory(this.id, this.label, this.icon, {this.justMe = false});
}

final List<ExpenseCategory> categories = [
  ExpenseCategory('food', 'Food and drinks', Ph.forkKnife),
  ExpenseCategory('stay', 'Stay', Ph.bed),
  ExpenseCategory('local_transport', 'Local transport', Ph.taxi),
  ExpenseCategory('fuel', 'Fuel', Ph.gasPump),
  ExpenseCategory('activities', 'Activities', Ph.ticket),
  ExpenseCategory('vehicle_rental', 'Vehicle rental', Ph.car),
  ExpenseCategory('tickets', 'Travel tickets', Ph.airplaneTilt),
  ExpenseCategory('shopping', 'Shopping', Ph.shoppingBag, justMe: true),
  ExpenseCategory('essentials', 'Essentials', Ph.firstAidKit),
  ExpenseCategory('fees', 'Fees and permits', Ph.receipt),
  ExpenseCategory('other', 'Other', Ph.dotsThree),
];

ExpenseCategory categoryOf(String id) =>
    categories.firstWhere((c) => c.id == id, orElse: () => categories.last);
