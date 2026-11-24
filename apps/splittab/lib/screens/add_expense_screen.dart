import 'package:material_ui/material_ui.dart' hide Split;

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
import 'custom_split_sheet.dart';

const _amountKeyboard = TextInputType.numberWithOptions(decimal: true);

class AddExpenseScreen extends StatefulWidget {
  const AddExpenseScreen({super.key, required this.tripId});

  final String tripId;

  @override
  State<AddExpenseScreen> createState() => _AddExpenseScreenState();
}

class _AddExpenseScreenState extends State<AddExpenseScreen> {
  final _amount = TextEditingController();
  final _title = TextEditingController();
  final _rate = TextEditingController();

  late AppTrip _trip;
  bool _ready = false;
  String _category = 'food';
  late String _currency;
  late String _payer;
  late Set<String> _among;
  Split? _custom;
  bool _splitTouched = false;
  String? _amountError, _rateError, _generalError;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_ready) return;
    _ready = true;
    _trip = AppScope.of(context).trip(widget.tripId)!;
    _currency = _trip.homeCurrency;
    _payer = _trip.members.any((m) => m.id == _trip.lastPayerId)
        ? _trip.lastPayerId!
        : _trip.meId;
    _among = _defaultAmong();
  }

  @override
  void dispose() {
    _amount.dispose();
    _title.dispose();
    _rate.dispose();
    super.dispose();
  }

  bool get _foreign => _currency != _trip.homeCurrency;
  int get _exponent => currencyOf(_currency).exponent;

  Set<String> _defaultAmong() {
    if (categoryOf(_category).justMe) return {_payer};
    final last = _trip.lastAmong
        ?.where((id) => _trip.members.any((m) => m.id == id))
        .toSet();
    return (last == null || last.isEmpty)
        ? {for (final m in _trip.members) m.id}
        : last;
  }

  void _resetDefaultsIfUntouched() {
    if (!_splitTouched) _among = _defaultAmong();
  }

  Rational? _parseRate() {
    try {
      final r = Rational.parse(_rate.text.trim().replaceAll(',', ''));
      return r > Rational.zero ? r : null;
    } on FormatException {
      return null;
    }
  }

  List<String> get _amongOrdered => [
    for (final m in _trip.members)
      if (_among.contains(m.id)) m.id,
  ];

  Split get _split => _custom ?? EqualSplit(_amongOrdered);

  /// The expense as currently typed, or null if it is not complete yet.
  ExpenseRecord? _draft() {
    final minor = parseMinor(_amount.text, _exponent);
    if (minor == null || minor <= 0) return null;
    final rate = _foreign ? _parseRate() : null;
    if (_foreign && rate == null) return null;
    if (_custom == null && _among.isEmpty) return null;
    final cat = categoryOf(_category);
    final title = _title.text.trim();
    return ExpenseRecord(
      expense: Expense(
        id: newId(),
        amount: minor,
        currency: _foreign ? _currency : null,
        rate: rate,
        paidBy: {_payer: minor},
        split: _split,
      ),
      title: title.isEmpty ? cat.label : title,
      category: _category,
      date: DateTime.now(),
    );
  }

  Map<String, int>? _preview() {
    final d = _draft();
    if (d == null) return null;
    try {
      return processExpense(_trip.coreTrip, d.expense).owed;
    } on SplitError {
      return null;
    }
  }

  Future<void> _pickCurrency() async {
    final picked = await showAppSheet<String>(
      context,
      builder: (ctx) => SheetFrame(
        title: 'Currency of this expense',
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
              for (final c in currencies)
                Pill(
                  label: c.code,
                  selected: c.code == _currency,
                  onTap: () => Navigator.of(ctx).pop(c.code),
                ),
            ],
          ),
        ),
      ),
    );
    if (picked == null || !mounted) return;
    setState(() {
      _currency = picked;
      _amountError = null;
      _generalError = null;
      if (_foreign) _rate.text = _trip.rates[picked] ?? '';
    });
  }

  Future<void> _customize() async {
    final minor = parseMinor(_amount.text, _exponent);
    final split = await showCustomSplit(
      context,
      trip: _trip,
      amountMinor: minor,
      exponent: _exponent,
      currency: _currency,
      selected: _among,
    );
    if (split == null || !mounted) return;
    setState(() {
      _custom = split;
      _splitTouched = true;
      _generalError = null;
    });
  }

  void _save() {
    final minor = parseMinor(_amount.text, _exponent);
    String? amountError, rateError, general;
    if (minor == null || minor <= 0) {
      amountError = _amount.text.trim().isEmpty
          ? 'Enter the amount.'
          : 'Enter a valid amount, like 12.50.';
    }
    Rational? rate;
    if (_foreign) {
      rate = _parseRate();
      if (rate == null) rateError = 'Enter the exchange rate, like 83.2.';
    }
    if (_custom == null && _among.isEmpty) {
      general = 'Choose at least one person to split with.';
    }
    if (amountError != null || rateError != null || general != null) {
      setState(() {
        _amountError = amountError;
        _rateError = rateError;
        _generalError = general;
      });
      return;
    }

    final record = _draft()!;
    try {
      _trip.compute(extra: [record]);
    } on SplitError catch (e) {
      setState(() => _generalError = friendlyError(e));
      return;
    }
    final state = AppScope.of(context);
    final messenger = ScaffoldMessenger.of(context);
    _trip.expenses.add(record);
    _trip.lastPayerId = _payer;
    if (_custom == null) _trip.lastAmong = _amongOrdered;
    if (_foreign && rate != null) {
      _trip.rates[_currency] = rate.toDecimalString();
    }
    state.save();
    Navigator.of(context).pop();
    showNoticeOn(messenger, '${record.title} added');
  }

  String _customSummary() => switch (_custom) {
    ExactSplit() => 'Custom amounts',
    PercentSplit() => 'Custom percentages',
    SharesSplit() => 'Custom shares',
    _ => 'Custom split',
  };

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final owed = _preview();
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
                      'Add expense',
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
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: AppField(
                          controller: _amount,
                          hint: formatNumber(0, _exponent),
                          large: true,
                          autofocus: true,
                          error: _amountError,
                          keyboardType: _amountKeyboard,
                          onChanged: (_) => setState(() => _amountError = null),
                        ),
                      ),
                      const SizedBox(width: Space.s100),
                      Padding(
                        padding: const EdgeInsets.only(top: Space.s75),
                        child: Pill(
                          label: _currency,
                          selected: false,
                          icon: Ph.caretDown,
                          onTap: _pickCurrency,
                        ),
                      ),
                    ],
                  ),
                  if (_foreign) ...[
                    const SizedBox(height: Space.s200),
                    AppField(
                      label: '1 $_currency is worth',
                      controller: _rate,
                      hint: '0.00',
                      suffixText: _trip.homeCurrency,
                      error: _rateError,
                      keyboardType: _amountKeyboard,
                      onChanged: (_) => setState(() => _rateError = null),
                    ),
                  ],
                  const SizedBox(height: Space.s200),
                  AppField(
                    label: 'What was it for?',
                    hint: 'Dinner at the beach shack',
                    controller: _title,
                    textInputAction: TextInputAction.done,
                  ),
                  const SizedBox(height: Space.s300),
                  const SectionLabel('Category'),
                  const SizedBox(height: Space.s75),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        for (final c in categories) ...[
                          Pill(
                            label: c.label,
                            icon: c.icon,
                            selected: c.id == _category,
                            onTap: () => setState(() {
                              _category = c.id;
                              _resetDefaultsIfUntouched();
                            }),
                          ),
                          const SizedBox(width: Space.s75),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: Space.s300),
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
                          onTap: () => setState(() {
                            _payer = m.id;
                            _resetDefaultsIfUntouched();
                          }),
                        ),
                    ],
                  ),
                  const SizedBox(height: Space.s300),
                  SectionLabel(
                    'Split between',
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (_custom == null)
                          AppButton(
                            label: _among.length == _trip.members.length
                                ? 'Clear'
                                : 'Everyone',
                            small: true,
                            kind: ButtonKind.quiet,
                            onPressed: () => setState(() {
                              _splitTouched = true;
                              _among = _among.length == _trip.members.length
                                  ? {}
                                  : {for (final m in _trip.members) m.id};
                            }),
                          ),
                        AppButton(
                          label: _custom == null ? 'Customize' : 'Edit',
                          small: true,
                          kind: ButtonKind.quiet,
                          icon: Ph.slidersHorizontal,
                          onPressed: _customize,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: Space.s75),
                  if (_custom == null)
                    Wrap(
                      spacing: Space.s75,
                      runSpacing: Space.s75,
                      children: [
                        for (final m in _trip.members)
                          Pill(
                            label: _trip.nameOf(m.id),
                            selected: _among.contains(m.id),
                            onTap: () => setState(() {
                              _splitTouched = true;
                              _generalError = null;
                              _among.contains(m.id)
                                  ? _among.remove(m.id)
                                  : _among.add(m.id);
                            }),
                          ),
                      ],
                    )
                  else
                    AppCard(
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              _customSummary(),
                              style: AppText.title3.copyWith(color: p.text),
                            ),
                          ),
                          AppButton(
                            label: 'Back to equal',
                            small: true,
                            kind: ButtonKind.quiet,
                            onPressed: () => setState(() => _custom = null),
                          ),
                        ],
                      ),
                    ),
                  if (owed != null) ...[
                    const SizedBox(height: Space.s200),
                    AppCard(
                      padding: const EdgeInsets.all(Space.s100),
                      child: Column(
                        children: [
                          for (final m in _trip.members)
                            if ((owed[m.id] ?? 0) != 0)
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: Space.s75,
                                  vertical: Space.s50,
                                ),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        _trip.nameOf(m.id),
                                        style: AppText.body5.copyWith(
                                          color: p.textMuted,
                                        ),
                                      ),
                                    ),
                                    Text(
                                      formatMoney(owed[m.id]!, _currency),
                                      style: AppText.numeric(AppText.body5)
                                          .copyWith(color: p.text),
                                    ),
                                  ],
                                ),
                              ),
                        ],
                      ),
                    ),
                  ],
                  if (_generalError != null) ...[
                    const SizedBox(height: Space.s100),
                    InlineMessage(_generalError!),
                  ],
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(Space.s200),
              child: AppButton(
                label: 'Save expense',
                expanded: true,
                onPressed: _save,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
