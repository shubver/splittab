import 'package:material_ui/material_ui.dart';

import '../design/icons.dart';

import 'package:splittab_core/splittab_core.dart';

import '../data/categories.dart';
import '../data/currencies.dart';
import '../data/errors.dart';
import '../data/models.dart';
import '../data/store.dart';
import '../design/text_styles.dart';
import '../design/tokens.dart';
import '../design/widgets.dart';

class _Row {
  final title = TextEditingController();
  final amount = TextEditingController();
  final titleFocus = FocusNode();
  final amountFocus = FocusNode();
  String category = 'food';
  String? error;

  bool get blank => title.text.trim().isEmpty && amount.text.trim().isEmpty;

  void dispose() {
    title.dispose();
    amount.dispose();
    titleFocus.dispose();
    amountFocus.dispose();
  }
}

/// Type many expenses in one go. One payer and one group of people for all rows.
class BulkAddScreen extends StatefulWidget {
  const BulkAddScreen({super.key, required this.tripId});

  final String tripId;

  @override
  State<BulkAddScreen> createState() => _BulkAddScreenState();
}

class _BulkAddScreenState extends State<BulkAddScreen> {
  late AppTrip _trip;
  bool _ready = false;
  late String _payer;
  late Set<String> _among;
  final _rows = <_Row>[_Row(), _Row(), _Row()];
  String? _error;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_ready) return;
    _ready = true;
    _trip = AppScope.of(context).trip(widget.tripId)!;
    _payer = _trip.members.any((m) => m.id == _trip.lastPayerId)
        ? _trip.lastPayerId!
        : _trip.meId;
    final last = _trip.lastAmong
        ?.where((id) => _trip.members.any((m) => m.id == id))
        .toSet();
    _among = (last == null || last.isEmpty)
        ? {for (final m in _trip.members) m.id}
        : last;
  }

  @override
  void dispose() {
    for (final r in _rows) {
      r.dispose();
    }
    super.dispose();
  }

  int get _count => _rows.where((r) => !r.blank).length;

  void _addRow({bool focus = true}) {
    final row = _Row();
    setState(() => _rows.add(row));
    if (focus) {
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => row.titleFocus.requestFocus(),
      );
    }
  }

  Future<void> _pickCategory(_Row row) async {
    final picked = await showAppSheet<String>(
      context,
      builder: (ctx) => SheetFrame(
        title: 'Category',
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(
            Space.s300,
            Space.s75,
            Space.s300,
            Space.s300,
          ),
          child: Wrap(
            spacing: Space.s75,
            runSpacing: Space.s75,
            children: [
              for (final c in categories)
                Pill(
                  label: c.label,
                  icon: c.icon,
                  selected: c.id == row.category,
                  onTap: () => Navigator.of(ctx).pop(c.id),
                ),
            ],
          ),
        ),
      ),
    );
    if (picked != null && mounted) setState(() => row.category = picked);
  }

  void _save() {
    final exponent = _trip.exponent;
    final records = <ExpenseRecord>[];
    var anyError = false;
    final among = [
      for (final m in _trip.members)
        if (_among.contains(m.id)) m.id,
    ];

    setState(() {
      _error = null;
      if (among.isEmpty) {
        _error = 'Choose at least one person to split with.';
        anyError = true;
      }
      for (final row in _rows) {
        row.error = null;
        if (row.blank) continue;
        final minor = parseMinor(row.amount.text, exponent);
        if (minor == null || minor <= 0) {
          row.error = row.amount.text.trim().isEmpty
              ? 'Enter an amount.'
              : 'Enter a valid amount, like 12.50.';
          anyError = true;
          continue;
        }
        final cat = categoryOf(row.category);
        final title = row.title.text.trim();
        records.add(
          ExpenseRecord(
            expense: Expense(
              id: newId(),
              amount: minor,
              paidBy: {_payer: minor},
              split: EqualSplit(among),
            ),
            title: title.isEmpty ? cat.label : title,
            category: row.category,
            date: DateTime.now(),
          ),
        );
      }
      if (!anyError && records.isEmpty) {
        _error = 'Fill in at least one row.';
        anyError = true;
      }
    });
    if (anyError) return;

    try {
      _trip.compute(extra: records);
    } on SplitError catch (e) {
      setState(() => _error = friendlyError(e));
      return;
    }
    final state = AppScope.of(context);
    final messenger = ScaffoldMessenger.of(context);
    _trip.expenses.addAll(records);
    _trip.lastPayerId = _payer;
    _trip.lastAmong = among;
    state.save();
    Navigator.of(context).pop();
    showNoticeOn(
      messenger,
      '${records.length} ${records.length == 1 ? 'expense' : 'expenses'} added',
    );
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final cur = currencyOf(_trip.homeCurrency);
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                Space.s75,
                Space.s100,
                Space.s75,
                Space.s0,
              ),
              child: Row(
                children: [
                  IconAction(
                    icon: Ph.x,
                    label: 'Close',
                    onTap: () => Navigator.of(context).pop(),
                  ),
                  Expanded(
                    child: Text(
                      'Bulk add',
                      textAlign: TextAlign.center,
                      style: AppText.title3.copyWith(color: p.text),
                    ),
                  ),
                  const SizedBox(width: Space.s600 - Space.s50),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(
                  Space.s200,
                  Space.s200,
                  Space.s200,
                  Space.s300,
                ),
                children: [
                  Text(
                    'Everything below is paid by the same person and split equally. Amounts are in ${cur.code}. Use Add expense for other currencies or custom splits.',
                    style: AppText.caption2.copyWith(color: p.textMuted),
                  ),
                  const SizedBox(height: Space.s200),
                  const SectionLabel('Paid by'),
                  const SizedBox(height: Space.s75),
                  Wrap(
                    spacing: Space.s75,
                    runSpacing: Space.s75,
                    children: [
                      for (final m in _trip.members)
                        Pill(
                          label: _trip.nameOf(m.id),
                          selected: m.id == _payer,
                          onTap: () => setState(() => _payer = m.id),
                        ),
                    ],
                  ),
                  const SizedBox(height: Space.s300),
                  SectionLabel(
                    'Split between',
                    trailing: AppButton(
                      label: _among.length == _trip.members.length
                          ? 'Clear'
                          : 'Everyone',
                      small: true,
                      kind: ButtonKind.quiet,
                      onPressed: () => setState(() {
                        _among = _among.length == _trip.members.length
                            ? {}
                            : {for (final m in _trip.members) m.id};
                      }),
                    ),
                  ),
                  const SizedBox(height: Space.s75),
                  Wrap(
                    spacing: Space.s75,
                    runSpacing: Space.s75,
                    children: [
                      for (final m in _trip.members)
                        Pill(
                          label: _trip.nameOf(m.id),
                          selected: _among.contains(m.id),
                          onTap: () => setState(() {
                            _error = null;
                            _among.contains(m.id)
                                ? _among.remove(m.id)
                                : _among.add(m.id);
                          }),
                        ),
                    ],
                  ),
                  const SizedBox(height: Space.s300),
                  const SectionLabel('Expenses'),
                  const SizedBox(height: Space.s100),
                  for (var i = 0; i < _rows.length; i++) _rowView(i, p),
                  AppButton(
                    label: 'Add row',
                    kind: ButtonKind.quiet,
                    small: true,
                    icon: Ph.plus,
                    onPressed: _addRow,
                  ),
                  if (_error != null) ...[
                    const SizedBox(height: Space.s100),
                    InlineMessage(_error!),
                  ],
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(Space.s200),
              child: AppButton(
                label: _count == 0
                    ? 'Add expenses'
                    : 'Add $_count ${_count == 1 ? 'expense' : 'expenses'}',
                expanded: true,
                onPressed: _save,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _rowView(int i, AppPalette p) {
    final row = _rows[i];
    final cat = categoryOf(row.category);
    return Padding(
      padding: const EdgeInsets.only(bottom: Space.s100),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Pressable(
                onTap: () => _pickCategory(row),
                color: p.surface,
                hoverColor: p.hover,
                borderColor: p.border,
                radius: Radii.xl,
                semanticLabel: 'Category ${cat.label}',
                child: SizedBox(
                  width: Space.s600,
                  height: Space.s600,
                  child: Center(child: Icon(cat.icon, size: 20, color: p.text)),
                ),
              ),
              const SizedBox(width: Space.s75),
              Expanded(
                child: AppField(
                  controller: row.title,
                  focusNode: row.titleFocus,
                  hint: 'Description',
                  textInputAction: TextInputAction.next,
                  onChanged: (_) => setState(() => row.error = null),
                  onSubmitted: (_) => row.amountFocus.requestFocus(),
                ),
              ),
              const SizedBox(width: Space.s75),
              SizedBox(
                width: 112,
                child: AppField(
                  controller: row.amount,
                  focusNode: row.amountFocus,
                  hint: formatNumber(0, _trip.exponent),
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  textAlign: TextAlign.end,
                  textInputAction: TextInputAction.next,
                  onChanged: (_) => setState(() => row.error = null),
                  onSubmitted: (_) {
                    if (i == _rows.length - 1) {
                      _addRow();
                    } else {
                      _rows[i + 1].titleFocus.requestFocus();
                    }
                  },
                ),
              ),
            ],
          ),
          if (row.error != null)
            Padding(
              padding: const EdgeInsets.only(
                top: Space.s75,
                left: Space.s600 + Space.s75,
              ),
              child: Text(
                row.error!,
                style: AppText.caption2.copyWith(color: p.negative),
              ),
            ),
        ],
      ),
    );
  }
}
