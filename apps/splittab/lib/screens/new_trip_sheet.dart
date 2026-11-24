import 'package:material_ui/material_ui.dart';

import '../design/icons.dart';

import '../data/currencies.dart';
import '../data/models.dart';
import '../data/store.dart';
import '../design/text_styles.dart';
import '../design/tokens.dart';
import '../design/widgets.dart';

/// Create a trip: name, your name, currency, and the people going.
class NewTripSheet extends StatefulWidget {
  const NewTripSheet({super.key});

  @override
  State<NewTripSheet> createState() => _NewTripSheetState();
}

class _NewTripSheetState extends State<NewTripSheet> {
  final _name = TextEditingController();
  final _me = TextEditingController();
  final _friend = TextEditingController();
  final _friends = <String>[];
  String _currency = 'USD';
  String? _nameError, _meError, _friendError, _peopleError;

  @override
  void dispose() {
    _name.dispose();
    _me.dispose();
    _friend.dispose();
    super.dispose();
  }

  bool _taken(String name) =>
      name.toLowerCase() == _me.text.trim().toLowerCase() ||
      _friends.any((f) => f.toLowerCase() == name.toLowerCase());

  void _addFriend() {
    final name = _friend.text.trim();
    if (name.isEmpty) return;
    if (_taken(name)) {
      setState(
        () => _friendError = 'Someone with that name is already on the trip. Add a last initial to tell them apart.',
      );
      return;
    }
    setState(() {
      _friends.add(name);
      _friend.clear();
      _friendError = null;
      _peopleError = null;
    });
  }

  void _create() {
    if (_friend.text.trim().isNotEmpty) _addFriend();
    setState(() {
      _nameError = _name.text.trim().isEmpty ? 'Give the trip a name.' : null;
      _meError = _me.text.trim().isEmpty ? 'Enter your name.' : null;
      _peopleError = _friends.isEmpty
          ? 'Add at least one friend to split with.'
          : null;
    });
    if (_nameError != null ||
        _meError != null ||
        _peopleError != null ||
        _friendError != null) {
      return;
    }

    final meId = newId();
    final trip = AppTrip(
      id: newId(),
      name: _name.text.trim(),
      homeCurrency: _currency,
      createdAt: DateTime.now(),
      meId: meId,
      members: [
        Member(meId, _me.text.trim()),
        for (final f in _friends) Member(newId(), f),
      ],
    );
    AppScope.of(context).addTrip(trip);
    Navigator.of(context).pop(trip);
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return SheetFrame(
      title: 'New trip',
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(
          Space.s300,
          Space.s100,
          Space.s300,
          Space.s300,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AppField(
              label: 'Trip name',
              hint: 'Goa with the gang',
              controller: _name,
              error: _nameError,
              textInputAction: TextInputAction.next,
              onChanged: (_) => setState(() => _nameError = null),
            ),
            const SizedBox(height: Space.s200),
            AppField(
              label: 'Your name',
              controller: _me,
              error: _meError,
              textInputAction: TextInputAction.next,
              onChanged: (_) => setState(() => _meError = null),
            ),
            const SizedBox(height: Space.s200),
            Text(
              'Currency for totals',
              style: AppText.caption1.copyWith(color: p.textMuted),
            ),
            const SizedBox(height: Space.s75),
            Wrap(
              spacing: Space.s75,
              runSpacing: Space.s75,
              children: [
                for (final c in currencies)
                  Pill(
                    label: c.code,
                    selected: c.code == _currency,
                    onTap: () => setState(() => _currency = c.code),
                  ),
              ],
            ),
            const SizedBox(height: Space.s75),
            Text(
              currencyOf(_currency).name,
              style: AppText.caption2.copyWith(color: p.textMuted),
            ),
            const SizedBox(height: Space.s300),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: AppField(
                    label: 'Friends on this trip',
                    hint: 'Add a name',
                    controller: _friend,
                    error: _friendError,
                    textInputAction: TextInputAction.done,
                    onChanged: (_) => setState(() => _friendError = null),
                    onSubmitted: (_) => _addFriend(),
                  ),
                ),
                const SizedBox(width: Space.s100),
                Padding(
                  padding: EdgeInsets.only(
                    bottom: _friendError == null ? 0 : Space.s600 - Space.s100,
                  ),
                  child: AppButton(
                    label: 'Add',
                    kind: ButtonKind.secondary,
                    onPressed: _addFriend,
                  ),
                ),
              ],
            ),
            if (_friends.isNotEmpty) ...[
              const SizedBox(height: Space.s100),
              Wrap(
                spacing: Space.s75,
                runSpacing: Space.s75,
                children: [
                  for (final f in _friends)
                    Pill(
                      label: f,
                      selected: false,
                      icon: Ph.x,
                      onTap: () => setState(() => _friends.remove(f)),
                    ),
                ],
              ),
            ],
            if (_peopleError != null) ...[
              const SizedBox(height: Space.s75),
              Text(
                _peopleError!,
                style: AppText.caption2.copyWith(color: p.negative),
              ),
            ],
            const SizedBox(height: Space.s400),
            AppButton(label: 'Create trip', expanded: true, onPressed: _create),
          ],
        ),
      ),
    );
  }
}
