import 'package:material_ui/material_ui.dart' hide Split;
import 'package:splittab_core/splittab_core.dart';

import '../data/currencies.dart';
import '../data/models.dart';
import '../design/text_styles.dart';
import '../design/tokens.dart';
import '../design/widgets.dart';

/// Lets someone split an expense by exact amounts, percentages or shares.
/// Returns null if they close it without applying.
Future<Split?> showCustomSplit(
  BuildContext context, {
  required AppTrip trip,
  required int? amountMinor,
  required int exponent,
  required String currency,
  required Set<String> selected,
}) {
  return showAppSheet<Split>(
    context,
    builder: (_) => _CustomSplitSheet(
      trip: trip,
      amountMinor: amountMinor,
      exponent: exponent,
      currency: currency,
      selected: selected,
    ),
  );
}

class _CustomSplitSheet extends StatefulWidget {
  const _CustomSplitSheet({
    required this.trip,
    required this.amountMinor,
    required this.exponent,
    required this.currency,
    required this.selected,
  });

  final AppTrip trip;
  final int? amountMinor;
  final int exponent;
  final String currency;
  final Set<String> selected;

  @override
  State<_CustomSplitSheet> createState() => _CustomSplitSheetState();
}

class _CustomSplitSheetState extends State<_CustomSplitSheet> {
  static const _modes = ['Amounts', 'Percent', 'Shares'];
  int _mode = 0;
  late final Map<String, TextEditingController> _exact = {
    for (final m in widget.trip.members) m.id: TextEditingController(),
  };
  late final Map<String, TextEditingController> _percent = {
    for (final m in widget.trip.members) m.id: TextEditingController(),
  };
  late final Map<String, TextEditingController> _shares = {
    for (final m in widget.trip.members)
      m.id: TextEditingController(
        text: widget.selected.contains(m.id) ? '1' : '',
      ),
  };
  String? _error;

  @override
  void dispose() {
    for (final c in [..._exact.values, ..._percent.values, ..._shares.values]) {
      c.dispose();
    }
    super.dispose();
  }

  Map<String, TextEditingController> get _current =>
      [_exact, _percent, _shares][_mode];

  /// Text parsed as a plain decimal, or null when empty or not a number.
  Rational? _decimal(String text) {
    try {
      return Rational.parse(text.trim().replaceAll(',', ''));
    } on FormatException {
      return null;
    }
  }

  int _exactSum() {
    var sum = 0;
    for (final c in _exact.values) {
      sum += parseMinor(c.text, widget.exponent) ?? 0;
    }
    return sum;
  }

  Rational _percentSum() => _percent.values.fold(
    Rational.zero,
    (a, c) => a + (_decimal(c.text) ?? Rational.zero),
  );

  String get _helper {
    final cur = widget.currency;
    switch (_mode) {
      case 0:
        final total = widget.amountMinor;
        if (total == null) {
          return 'Enter the expense amount first, then come back to split it.';
        }
        final left = total - _exactSum();
        return left == 0
            ? 'Everything is assigned.'
            : (left > 0
                  ? '${formatMoney(left, cur)} left to assign'
                  : '${formatMoney(-left, cur)} too much');
      case 1:
        final left = Rational.fromInt(100) - _percentSum();
        return left.isZero
            ? 'Adds up to 100 percent.'
            : '${left.toDecimalString()} percent ${left > Rational.zero ? 'left' : 'too much'}';
      default:
        return 'People with a share of 0 or a blank box are left out. A share of 2 pays double a share of 1.';
    }
  }

  void _apply() {
    final members = widget.trip.members;
    Split? split;
    String? error;

    switch (_mode) {
      case 0:
        final total = widget.amountMinor;
        if (total == null) {
          error = 'Enter the expense amount first, then come back to split it.';
          break;
        }
        final amounts = <String, int>{};
        for (final m in members) {
          final text = _exact[m.id]!.text;
          if (text.trim().isEmpty) continue;
          final v = parseMinor(text, widget.exponent);
          if (v == null) {
            error =
                'Use plain amounts like 12.50 for ${widget.trip.nameOf(m.id)}.';
            break;
          }
          if (v > 0) amounts[m.id] = v;
        }
        if (error == null && amounts.values.fold(0, (a, b) => a + b) != total) {
          error =
              'The amounts need to add up to ${formatMoney(total, widget.currency)}.';
        }
        if (error == null) split = ExactSplit(amounts);
      case 1:
        final pcts = <String, Rational>{};
        for (final m in members) {
          final text = _percent[m.id]!.text;
          if (text.trim().isEmpty) continue;
          final v = _decimal(text);
          if (v == null || v.isNegative) {
            error =
                'Use plain numbers like 33.5 for ${widget.trip.nameOf(m.id)}.';
            break;
          }
          if (!v.isZero) pcts[m.id] = v;
        }
        if (error == null &&
            pcts.values.fold(Rational.zero, (a, b) => a + b) !=
                Rational.fromInt(100)) {
          error = 'Percentages need to add up to 100.';
        }
        if (error == null) split = PercentSplit(pcts);
      default:
        final shares = <String, Rational>{};
        for (final m in members) {
          final text = _shares[m.id]!.text;
          if (text.trim().isEmpty) continue;
          final v = _decimal(text);
          if (v == null || v.isNegative) {
            error = 'Use plain numbers like 2 for ${widget.trip.nameOf(m.id)}.';
            break;
          }
          if (!v.isZero) shares[m.id] = v;
        }
        if (error == null && shares.isEmpty) {
          error = 'Give at least one person a share above zero.';
        }
        if (error == null) split = SharesSplit(shares);
    }

    if (error != null) {
      setState(() => _error = error);
      return;
    }
    Navigator.of(context).pop(split);
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return SheetFrame(
      title: 'Customize split',
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(
          Space.s300,
          Space.s75,
          Space.s300,
          Space.s300,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SegmentedTabs(
              labels: _modes,
              index: _mode,
              onChanged: (i) => setState(() {
                _mode = i;
                _error = null;
              }),
            ),
            const SizedBox(height: Space.s100),
            Text(_helper, style: AppText.caption2.copyWith(color: p.textMuted)),
            const SizedBox(height: Space.s200),
            for (final m in widget.trip.members)
              Padding(
                padding: const EdgeInsets.only(bottom: Space.s100),
                child: Row(
                  children: [
                    Avatar(m.name),
                    const SizedBox(width: Space.s100),
                    Expanded(
                      child: Text(
                        widget.trip.nameOf(m.id),
                        style: AppText.title3.copyWith(color: p.text),
                      ),
                    ),
                    SizedBox(
                      width: 128,
                      child: AppField(
                        controller: _current[m.id]!,
                        hint: _mode == 0
                            ? formatNumber(0, widget.exponent)
                            : (_mode == 1 ? '0' : '0'),
                        suffixText: _mode == 1 ? '%' : null,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        textAlign: TextAlign.end,
                        onChanged: (_) => setState(() => _error = null),
                      ),
                    ),
                  ],
                ),
              ),
            if (_error != null) ...[
              const SizedBox(height: Space.s75),
              InlineMessage(_error!),
            ],
            const SizedBox(height: Space.s200),
            AppButton(label: 'Apply split', expanded: true, onPressed: _apply),
          ],
        ),
      ),
    );
  }
}
