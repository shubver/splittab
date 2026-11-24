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

/// Asks before doing something that is hard to undo. Returns true if confirmed.
Future<bool> confirmSheet(
  BuildContext context, {
  required String title,
  required String body,
  required String confirmLabel,
  bool destructive = false,
}) async {
  final p = context.palette;
  final ok = await showAppSheet<bool>(
    context,
    builder: (ctx) => SheetFrame(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          Space.s300,
          Space.s200,
          Space.s300,
          Space.s300,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(title, style: AppText.heading6.copyWith(color: p.text)),
            const SizedBox(height: Space.s100),
            Text(body, style: AppText.body6.copyWith(color: p.textMuted)),
            const SizedBox(height: Space.s300),
            AppButton(
              label: confirmLabel,
              expanded: true,
              onPressed: () => Navigator.of(ctx).pop(true),
              kind: destructive ? ButtonKind.secondary : ButtonKind.primary,
              destructive: destructive,
            ),
            const SizedBox(height: Space.s75),
            AppButton(
              label: 'Cancel',
              kind: ButtonKind.quiet,
              expanded: true,
              onPressed: () => Navigator.of(ctx).pop(false),
            ),
          ],
        ),
      ),
    ),
  );
  return ok ?? false;
}

/// "How Maya's balance adds up": every expense and payment behind one number.
Future<void> showExplainSheet(
  BuildContext context,
  AppTrip trip,
  TripResult result,
  String memberId,
) {
  final p = context.palette;
  final cur = trip.homeCurrency;
  final lines = <Widget>[];

  for (final r in trip.expenses) {
    final er = result.expenses[r.id];
    if (er == null) continue;
    final paid = er.paid[memberId] ?? 0;
    final owed = er.owed[memberId] ?? 0;
    if (paid == 0 && owed == 0) continue;
    lines.add(
      Padding(
        padding: const EdgeInsets.symmetric(vertical: Space.s75),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(r.title, style: AppText.title3.copyWith(color: p.text)),
                  Text(
                    'Paid ${formatMoney(paid, cur)}, share ${formatMoney(owed, cur)}',
                    style: AppText.caption4.copyWith(color: p.textMuted),
                  ),
                ],
              ),
            ),
            AmountText(paid - owed, cur),
          ],
        ),
      ),
    );
  }
  for (final pay in trip.payments) {
    if (pay.from != memberId && pay.to != memberId) continue;
    final sent = pay.from == memberId;
    lines.add(
      Padding(
        padding: const EdgeInsets.symmetric(vertical: Space.s75),
        child: Row(
          children: [
            Expanded(
              child: Text(
                sent
                    ? 'Paid ${trip.asObject(pay.to)}'
                    : 'Received from ${trip.asObject(pay.from)}',
                style: AppText.title3.copyWith(color: p.text),
              ),
            ),
            AmountText(sent ? pay.amount : -pay.amount, cur),
          ],
        ),
      ),
    );
  }

  final balance = result.balances[memberId] ?? 0;
  final name = trip.nameOf(memberId);
  return showAppSheet<void>(
    context,
    builder: (_) => SheetFrame(
      title: memberId == trip.meId
          ? 'How your balance adds up'
          : 'How $name\'s balance adds up',
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
            Text(
              'Each line is what was paid minus what the person owes for it. A positive number is money owed to them.',
              style: AppText.caption2.copyWith(color: p.textMuted),
            ),
            const SizedBox(height: Space.s100),
            if (lines.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: Space.s200),
                child: Text(
                  'No expenses involve this person yet.',
                  style: AppText.body6.copyWith(color: p.textMuted),
                ),
              )
            else
              ...lines,
            const SizedBox(height: Space.s100),
            Container(
              padding: const EdgeInsets.all(Space.s200),
              decoration: BoxDecoration(
                color: p.raised,
                borderRadius: BorderRadius.circular(Radii.xl),
                border: Border.all(color: p.border),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Balance',
                      style: AppText.title3.copyWith(color: p.text),
                    ),
                  ),
                  AmountText(balance, cur, style: AppText.body1),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

/// One expense in full, with delete (and undo).
Future<void> showExpenseDetail(
  BuildContext context,
  AppTrip trip,
  ExpenseRecord record,
) {
  final p = context.palette;
  final cur = trip.homeCurrency;
  final result = trip.compute();
  final er = result.expenses[record.id]!;
  final e = record.expense;
  final cat = categoryOf(record.category);
  final foreign = e.currency != null && e.currency != cur;
  final state = AppScope.of(context);
  final messenger = ScaffoldMessenger.of(context);
  final active = trip.status == TripStatus.active;

  return showAppSheet<void>(
    context,
    builder: (ctx) => SheetFrame(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(
          Space.s300,
          Space.s200,
          Space.s300,
          Space.s300,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(cat.icon, size: 24, color: p.text),
                const SizedBox(width: Space.s100),
                Expanded(
                  child: Text(
                    record.title,
                    style: AppText.heading6.copyWith(color: p.text),
                  ),
                ),
              ],
            ),
            const SizedBox(height: Space.s100),
            Text(
              formatMoney(er.totalHome, cur),
              style: AppText.numeric(AppText.heading4).copyWith(color: p.text),
            ),
            if (foreign)
              Text(
                '${formatMoney(e.amount, e.currency!)} at a rate of ${e.rate!.toDecimalString()} $cur',
                style: AppText.caption2.copyWith(color: p.textMuted),
              ),
            const SizedBox(height: Space.s100),
            Text(
              '${cat.label}, ${shortDate(record.date)}. Paid by ${e.paidBy.keys.map(trip.nameOf).join(' and ')}.',
              style: AppText.body6.copyWith(color: p.textMuted),
            ),
            const SizedBox(height: Space.s300),
            const SectionLabel('Who owes what'),
            const SizedBox(height: Space.s75),
            for (final m in trip.members)
              if ((er.owed[m.id] ?? 0) != 0)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: Space.s50),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          trip.nameOf(m.id),
                          style: AppText.body2.copyWith(color: p.text),
                        ),
                      ),
                      Text(
                        formatMoney(er.owed[m.id]!, cur),
                        style: AppText.numeric(AppText.body4)
                            .copyWith(color: p.text),
                      ),
                    ],
                  ),
                ),
            if (active) ...[
              const SizedBox(height: Space.s300),
              AppButton(
                label: 'Delete expense',
                kind: ButtonKind.secondary,
                destructive: true,
                icon: Ph.trash,
                expanded: true,
                onPressed: () {
                  final index = trip.expenses.indexWhere(
                    (x) => x.id == record.id,
                  );
                  trip.expenses.removeAt(index);
                  state.save();
                  Navigator.of(ctx).pop();
                  showNoticeOn(
                    messenger,
                    '${record.title} deleted',
                    actionLabel: 'Undo',
                    onAction: () {
                      trip.expenses.insert(
                        index.clamp(0, trip.expenses.length),
                        record,
                      );
                      state.save();
                    },
                  );
                },
              ),
            ],
          ],
        ),
      ),
    ),
  );
}
