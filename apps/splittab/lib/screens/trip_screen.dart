import 'package:material_ui/material_ui.dart';

import '../design/icons.dart';

import 'package:splittab_core/splittab_core.dart';

import '../data/categories.dart';
import '../data/currencies.dart';
import '../data/format.dart';
import '../data/models.dart';
import '../data/store.dart';
import '../design/text_styles.dart';
import '../design/tokens.dart';
import '../design/widgets.dart';
import 'add_expense_screen.dart';
import 'bulk_add_screen.dart';
import 'sheets.dart';

class TripScreen extends StatefulWidget {
  const TripScreen({super.key, required this.tripId});

  final String tripId;

  @override
  State<TripScreen> createState() => _TripScreenState();
}

class _TripScreenState extends State<TripScreen> {
  int? _tab;
  bool _direct = false;

  void _open(Widget screen) =>
      Navigator.of(context)
          .push(MaterialPageRoute<void>(builder: (_) => screen));

  Future<void> _options(AppTrip trip) async {
    final action = await showAppSheet<String>(
      context,
      builder: (_) => SheetFrame(
        title: 'Trip options',
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            Space.s200,
            Space.s75,
            Space.s200,
            Space.s300,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (trip.status == TripStatus.active)
                _OptionRow(
                  icon: Ph.flagCheckered,
                  label: 'End trip and settle up',
                  value: 'end',
                )
              else
                _OptionRow(
                  icon: Ph.arrowCounterClockwise,
                  label: 'Reopen trip',
                  value: 'reopen',
                ),
              _OptionRow(
                icon: Ph.trash,
                label: 'Delete trip',
                value: 'delete',
                destructive: true,
              ),
            ],
          ),
        ),
      ),
    );
    if (!mounted || action == null) return;
    switch (action) {
      case 'end':
        await _endTrip(trip);
      case 'reopen':
        trip.status = TripStatus.active;
        await AppScope.of(context).save();
        setState(() => _tab = 0);
      case 'delete':
        final ok = await confirmSheet(
          context,
          title: 'Delete this trip?',
          body: 'All of its expenses are removed from this device. This cannot be undone.',
          confirmLabel: 'Delete trip',
          destructive: true,
        );
        if (ok && mounted) {
          final state = AppScope.of(context);
          Navigator.of(context).pop();
          state.deleteTrip(trip.id);
        }
    }
  }

  Future<void> _endTrip(AppTrip trip) async {
    final n = trip.expenses.length;
    final ok = await confirmSheet(
      context,
      title: 'End this trip?',
      body:
          'You have $n ${n == 1 ? 'expense' : 'expenses'} logged. New expenses are locked after you end the trip, '
          'so nobody pays early and then has to pay again. You can reopen it later.',
      confirmLabel: 'End trip',
    );
    if (!ok || !mounted) return;
    final empty = trip.compute().settle.plan.isEmpty;
    trip.status = empty ? TripStatus.settled : TripStatus.ended;
    await AppScope.of(context).save();
    setState(() => _tab = 1);
  }

  Future<void> _markPaid(AppTrip trip, Transfer t) async {
    trip.payments.add(Payment(from: t.from, to: t.to, amount: t.amount));
    if (trip.compute().settle.plan.isEmpty) trip.status = TripStatus.settled;
    await AppScope.of(context).save();
    if (mounted) {
      showNotice(
        context,
        '${trip.nameOf(t.from)} paid ${trip.asObject(t.to)} ${formatMoney(t.amount, trip.homeCurrency)}',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final trip = state.trip(widget.tripId);
    final p = context.palette;
    if (trip == null) return const Scaffold(body: SizedBox.shrink());

    TripResult? result;
    try {
      result = trip.compute();
    } on SplitError {
      result = null;
    }

    final active = trip.status == TripStatus.active;
    final tab = _tab ?? (active ? 0 : 1);
    final status = switch (trip.status) {
      TripStatus.active => 'Active',
      TripStatus.ended => 'Ended, ready to settle',
      TripStatus.settled => 'Settled',
    };

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
                    icon: Ph.arrowLeft,
                    label: 'Back',
                    onTap: () => Navigator.of(context).pop(),
                  ),
                  Expanded(
                    child: Column(
                      children: [
                        Text(
                          trip.name,
                          style: AppText.title3.copyWith(color: p.text),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          '${trip.members.length} people, $status',
                          style: AppText.caption4.copyWith(color: p.textMuted),
                        ),
                      ],
                    ),
                  ),
                  IconAction(
                    icon: Ph.dotsThree,
                    label: 'Trip options',
                    onTap: () => _options(trip),
                  ),
                ],
              ),
            ),
            Expanded(
              child: result == null
                  ? const Padding(
                      padding: EdgeInsets.all(Space.s200),
                      child: InlineMessage(
                        'This trip has an entry the app cannot calculate. Open the expense list and delete the last entry.',
                      ),
                    )
                  : ListView(
                      padding: const EdgeInsets.fromLTRB(
                        Space.s200,
                        Space.s200,
                        Space.s200,
                        Space.s300,
                      ),
                      children: [
                        _Summary(trip: trip, result: result),
                        const SizedBox(height: Space.s200),
                        SegmentedTabs(
                          labels: const ['Expenses', 'Balances'],
                          index: tab,
                          onChanged: (i) => setState(() => _tab = i),
                        ),
                        const SizedBox(height: Space.s200),
                        if (tab == 0)
                          _ExpensesTab(
                            trip: trip,
                            result: result,
                            onAdd: () =>
                                _open(AddExpenseScreen(tripId: trip.id)),
                            onBulk: () => _open(BulkAddScreen(tripId: trip.id)),
                          )
                        else
                          _BalancesTab(
                            trip: trip,
                            result: result,
                            direct: _direct,
                            onToggleDirect: (v) => setState(() => _direct = v),
                            onEnd: () => _endTrip(trip),
                            onMarkPaid: (t) => _markPaid(trip, t),
                          ),
                      ],
                    ),
            ),
            if (active && result != null)
              Padding(
                padding: const EdgeInsets.all(Space.s200),
                child: Row(
                  children: [
                    AppButton(
                      label: 'Bulk add',
                      kind: ButtonKind.secondary,
                      icon: Ph.listPlus,
                      onPressed: () => _open(BulkAddScreen(tripId: trip.id)),
                    ),
                    const SizedBox(width: Space.s100),
                    Expanded(
                      child: AppButton(
                        label: 'Add expense',
                        icon: Ph.plus,
                        expanded: true,
                        onPressed: () =>
                            _open(AddExpenseScreen(tripId: trip.id)),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _OptionRow extends StatelessWidget {
  const _OptionRow({
    required this.icon,
    required this.label,
    required this.value,
    this.destructive = false,
  });

  final IconData icon;
  final String label;
  final String value;
  final bool destructive;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final color = destructive ? p.negative : p.text;
    return Pressable(
      onTap: () => Navigator.of(context).pop(value),
      hoverColor: p.raised,
      radius: Radii.xl,
      minHeight: Space.s600,
      padding: const EdgeInsets.symmetric(
        horizontal: Space.s100,
        vertical: Space.s75,
      ),
      semanticLabel: label,
      child: Row(
        children: [
          Icon(icon, size: 24, color: color),
          const SizedBox(width: Space.s200),
          Text(label, style: AppText.body2.copyWith(color: color)),
        ],
      ),
    );
  }
}

class _Summary extends StatelessWidget {
  const _Summary({required this.trip, required this.result});

  final AppTrip trip;
  final TripResult result;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final mine = result.balances[trip.meId] ?? 0;
    final total = result.expenses.values.fold<int>(
      0,
      (a, e) => a + (e.totalHome > 0 ? e.totalHome : 0),
    );
    final label = mine > 0
        ? 'You are owed'
        : (mine < 0 ? 'You owe' : 'You are even');
    final n = trip.expenses.length;
    return AppCard(
      padding: const EdgeInsets.all(Space.s300),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: AppText.caption1.copyWith(color: p.textMuted)),
          const SizedBox(height: Space.s50),
          Text(
            formatMoney(mine.abs(), trip.homeCurrency),
            style: AppText.numeric(AppText.heading3).copyWith(
              color: mine > 0 ? p.positive : (mine < 0 ? p.negative : p.text),
            ),
          ),
          const SizedBox(height: Space.s100),
          Text(
            'Group spent ${formatMoney(total, trip.homeCurrency)} on $n ${n == 1 ? 'expense' : 'expenses'}',
            style: AppText.caption2.copyWith(color: p.textMuted),
          ),
        ],
      ),
    );
  }
}

class _ExpensesTab extends StatelessWidget {
  const _ExpensesTab({
    required this.trip,
    required this.result,
    required this.onAdd,
    required this.onBulk,
  });

  final AppTrip trip;
  final TripResult result;
  final VoidCallback onAdd;
  final VoidCallback onBulk;

  @override
  Widget build(BuildContext context) {
    if (trip.expenses.isEmpty) {
      final active = trip.status == TripStatus.active;
      return Padding(
        padding: const EdgeInsets.only(top: Space.s300),
        child: EmptyState(
          icon: Ph.receipt,
          title: 'No expenses yet',
          body: active
              ? 'Add the first one. If you have a pile of receipts, use Bulk add to enter them in one go.'
              : 'This trip ended without any expenses.',
          action: active
              ? SizedBox(
                  width: double.infinity,
                  child: Row(
                    children: [
                      Expanded(
                        child: AppButton(
                          label: 'Bulk add',
                          kind: ButtonKind.secondary,
                          expanded: true,
                          onPressed: onBulk,
                        ),
                      ),
                      const SizedBox(width: Space.s100),
                      Expanded(
                        child: AppButton(
                          label: 'Add expense',
                          expanded: true,
                          onPressed: onAdd,
                        ),
                      ),
                    ],
                  ),
                )
              : null,
        ),
      );
    }
    final rows = trip.expenses.reversed.toList();
    return Column(
      children: [
        for (var i = 0; i < rows.length; i++)
          Reveal(
            index: i,
            child: _ExpenseRow(trip: trip, record: rows[i], result: result),
          ),
      ],
    );
  }
}

class _ExpenseRow extends StatelessWidget {
  const _ExpenseRow({
    required this.trip,
    required this.record,
    required this.result,
  });

  final AppTrip trip;
  final ExpenseRecord record;
  final TripResult result;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final cat = categoryOf(record.category);
    final e = record.expense;
    final home = result.expenses[e.id]?.totalHome ?? 0;
    final foreign = e.currency != null && e.currency != trip.homeCurrency;
    final payers = e.paidBy.keys.map(trip.nameOf).join(' and ');
    return Pressable(
      onTap: () => showExpenseDetail(context, trip, record),
      hoverColor: p.surface,
      radius: Radii.xl,
      padding: const EdgeInsets.symmetric(
        horizontal: Space.s75,
        vertical: Space.s100,
      ),
      semanticLabel: '${record.title}, ${formatMoney(home, trip.homeCurrency)}',
      child: Row(
        children: [
          Container(
            width: Space.s500,
            height: Space.s500,
            decoration: BoxDecoration(
              color: p.surface,
              shape: BoxShape.circle,
              border: Border.all(color: p.border),
            ),
            child: Center(child: Icon(cat.icon, size: 20, color: p.text)),
          ),
          const SizedBox(width: Space.s100),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  record.title,
                  style: AppText.title3.copyWith(color: p.text),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  '$payers paid, ${shortDate(record.date)}',
                  style: AppText.caption2.copyWith(color: p.textMuted),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: Space.s100),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                formatMoney(home, trip.homeCurrency),
                style: AppText.numeric(AppText.body4).copyWith(color: p.text),
              ),
              if (foreign)
                Text(
                  formatMoney(e.amount, e.currency!),
                  style: AppText.numeric(AppText.caption5)
                      .copyWith(color: p.textMuted),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _BalancesTab extends StatelessWidget {
  const _BalancesTab({
    required this.trip,
    required this.result,
    required this.direct,
    required this.onToggleDirect,
    required this.onEnd,
    required this.onMarkPaid,
  });

  final AppTrip trip;
  final TripResult result;
  final bool direct;
  final ValueChanged<bool> onToggleDirect;
  final VoidCallback onEnd;
  final ValueChanged<Transfer> onMarkPaid;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final active = trip.status == TripStatus.active;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (!active) ...[
          _SettleSection(
            trip: trip,
            result: result,
            direct: direct,
            onToggleDirect: onToggleDirect,
            onMarkPaid: onMarkPaid,
          ),
          const SizedBox(height: Space.s300),
        ],
        if (!active) ...[
          const SectionLabel('Balances'),
          const SizedBox(height: Space.s50),
        ],
        Text(
          'Tap a person to see how their balance adds up.',
          style: AppText.caption2.copyWith(color: p.textMuted),
        ),
        const SizedBox(height: Space.s100),
        for (var i = 0; i < trip.members.length; i++)
          Reveal(
            index: i,
            child: Pressable(
              onTap: () =>
                  showExplainSheet(context, trip, result, trip.members[i].id),
              hoverColor: p.surface,
              radius: Radii.xl,
              padding: const EdgeInsets.symmetric(
                horizontal: Space.s75,
                vertical: Space.s100,
              ),
              semanticLabel: 'Balance for ${trip.nameOf(trip.members[i].id)}',
              child: Row(
                children: [
                  Avatar(trip.members[i].name),
                  const SizedBox(width: Space.s100),
                  Expanded(
                    child: Text(
                      trip.nameOf(trip.members[i].id),
                      style: AppText.title3.copyWith(color: p.text),
                    ),
                  ),
                  AmountText(
                    result.balances[trip.members[i].id] ?? 0,
                    trip.homeCurrency,
                    style: AppText.body2,
                  ),
                  const SizedBox(width: Space.s75),
                  Icon(Ph.caretRight, size: 16, color: p.textMuted),
                ],
              ),
            ),
          ),
        if (active) ...[
          const SizedBox(height: Space.s300),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Settle up after the trip',
                  style: AppText.title3.copyWith(color: p.text),
                ),
                const SizedBox(height: Space.s75),
                Text(
                  'Payments are worked out once you end the trip. That way nobody pays early and then has to pay again when a late expense turns up.',
                  style: AppText.body6.copyWith(color: p.textMuted),
                ),
                const SizedBox(height: Space.s200),
                AppButton(
                  label: 'End trip',
                  kind: ButtonKind.secondary,
                  icon: Ph.flagCheckered,
                  onPressed: onEnd,
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

class _SettleSection extends StatelessWidget {
  const _SettleSection({
    required this.trip,
    required this.result,
    required this.direct,
    required this.onToggleDirect,
    required this.onMarkPaid,
  });

  final AppTrip trip;
  final TripResult result;
  final bool direct;
  final ValueChanged<bool> onToggleDirect;
  final ValueChanged<Transfer> onMarkPaid;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final plan = result.settle.plan;
    final list = direct ? result.direct : plan;
    final settled = plan.isEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SectionLabel('Settle up'),
        const SizedBox(height: Space.s100),
        SegmentedTabs(
          labels: const ['Fewest payments', 'Who owes whom'],
          index: direct ? 1 : 0,
          onChanged: (i) => onToggleDirect(i == 1),
        ),
        const SizedBox(height: Space.s100),
        Text(
          settled
              ? 'Nothing left to pay.'
              : direct
              ? 'Each line comes straight from who paid for whom. It can take more payments.'
              : '${plan.length} ${plan.length == 1 ? 'payment settles' : 'payments settle'} everyone.',
          style: AppText.caption2.copyWith(color: p.textMuted),
        ),
        const SizedBox(height: Space.s100),
        if (settled)
          AppCard(
            child: Row(
              children: [
                Icon(Ph.checkCircle, size: 24, color: p.positive),
                const SizedBox(width: Space.s100),
                Expanded(
                  child: Text(
                    'Everyone is settled.',
                    style: AppText.title3.copyWith(color: p.text),
                  ),
                ),
              ],
            ),
          )
        else
          AppCard(
            padding: const EdgeInsets.all(Space.s75),
            child: Column(
              children: [
                for (final t in list)
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: Space.s75,
                      vertical: Space.s75,
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                direct
                                    ? '${trip.nameOf(t.from)} ${t.from == trip.meId ? 'owe' : 'owes'} ${trip.asObject(t.to)}'
                                    : '${trip.nameOf(t.from)} ${t.from == trip.meId ? 'pay' : 'pays'} ${trip.asObject(t.to)}',
                                style: AppText.body2.copyWith(color: p.text),
                              ),
                              Text(
                                formatMoney(t.amount, trip.homeCurrency),
                                style: AppText.numeric(AppText.body4)
                                    .copyWith(color: p.textMuted),
                              ),
                            ],
                          ),
                        ),
                        if (!direct) ...[
                          const SizedBox(width: Space.s100),
                          AppButton(
                            label: 'Mark as paid',
                            small: true,
                            kind: ButtonKind.secondary,
                            onPressed: () => onMarkPaid(t),
                          ),
                        ],
                      ],
                    ),
                  ),
              ],
            ),
          ),
      ],
    );
  }
}
