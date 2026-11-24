import 'package:material_ui/material_ui.dart';

import '../design/icons.dart';

import '../data/currencies.dart';
import '../data/models.dart';
import '../data/store.dart';
import '../design/text_styles.dart';
import '../design/tokens.dart';
import '../design/widgets.dart';
import 'new_trip_sheet.dart';
import 'trip_screen.dart';

class TripsScreen extends StatelessWidget {
  const TripsScreen({super.key});

  Future<void> _newTrip(BuildContext context) async {
    final created = await showAppSheet<AppTrip>(
      context,
      builder: (_) => const NewTripSheet(),
    );
    if (created != null && context.mounted) {
      Navigator.of(context).push(
        MaterialPageRoute<void>(builder: (_) => TripScreen(tripId: created.id)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final p = context.palette;
    final hasTrips = state.trips.isNotEmpty;

    Widget body;
    if (state.loading) {
      body = ListView(
        padding: const EdgeInsets.all(Space.s200),
        children: const [
          _TripSkeleton(),
          SizedBox(height: Space.s100),
          _TripSkeleton(),
          SizedBox(height: Space.s100),
          _TripSkeleton(),
        ],
      );
    } else if (!hasTrips) {
      body = EmptyState(
        icon: Ph.airplaneTilt,
        title: 'No trips yet',
        body: 'Create a trip, add your friends, and log expenses as you go. Settling up happens when the trip ends.',
        action: AppButton(
          label: 'Create a trip',
          icon: Ph.plus,
          onPressed: () => _newTrip(context),
        ),
      );
    } else {
      body = ListView.separated(
        padding: const EdgeInsets.fromLTRB(
          Space.s200,
          Space.s0,
          Space.s200,
          Space.s200,
        ),
        itemCount: state.trips.length,
        separatorBuilder: (_, _) => const SizedBox(height: Space.s100),
        itemBuilder: (context, i) => Reveal(
          index: i,
          child: _TripCard(trip: state.trips[i]),
        ),
      );
    }

    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                Space.s200,
                Space.s300,
                Space.s200,
                Space.s200,
              ),
              child: Text(
                'Trips',
                style: AppText.heading4.copyWith(color: p.text),
              ),
            ),
            Expanded(child: body),
            if (hasTrips)
              Padding(
                padding: const EdgeInsets.all(Space.s200),
                child: AppButton(
                  label: 'New trip',
                  icon: Ph.plus,
                  expanded: true,
                  onPressed: () => _newTrip(context),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _TripCard extends StatelessWidget {
  const _TripCard({required this.trip});

  final AppTrip trip;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final result = trip.compute();
    final mine = result.balances[trip.meId] ?? 0;
    final total = result.expenses.values.fold<int>(
      0,
      (a, e) => a + (e.totalHome > 0 ? e.totalHome : 0),
    );
    final count = trip.expenses.length;
    final status = switch (trip.status) {
      TripStatus.active => 'Active',
      TripStatus.ended => 'Ended',
      TripStatus.settled => 'Settled',
    };
    final balanceText = mine == 0
        ? 'You are even'
        : (mine > 0
              ? 'You are owed ${formatMoney(mine, trip.homeCurrency)}'
              : 'You owe ${formatMoney(-mine, trip.homeCurrency)}');
    return AppCard(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute<void>(builder: (_) => TripScreen(tripId: trip.id)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: Space.s600,
                height: Space.s600,
                decoration: BoxDecoration(
                  color: p.raised,
                  borderRadius: BorderRadius.circular(
                    Radii.nested(Radii.xxl, Space.s100),
                  ),
                ),
                child: Center(
                  child: Icon(Ph.mapTrifold, size: 24, color: p.text),
                ),
              ),
              const SizedBox(width: Space.s200),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      trip.name,
                      style: AppText.title2.copyWith(color: p.text),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: Space.s25),
                    Text(
                      '${trip.members.length} people, $count ${count == 1 ? 'expense' : 'expenses'}, $status',
                      style: AppText.caption2.copyWith(color: p.textMuted),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Icon(Ph.caretRight, size: 16, color: p.textMuted),
            ],
          ),
          const SizedBox(height: Space.s200),
          Row(
            children: [
              Expanded(
                child: Text(
                  'Spent ${formatMoney(total, trip.homeCurrency)}',
                  style: AppText.numeric(AppText.caption2)
                      .copyWith(color: p.textMuted),
                ),
              ),
              Text(
                balanceText,
                style: AppText.numeric(AppText.body5).copyWith(
                  color: mine > 0
                      ? p.positive
                      : (mine < 0 ? p.negative : p.textMuted),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _TripSkeleton extends StatelessWidget {
  const _TripSkeleton();

  @override
  Widget build(BuildContext context) {
    return const AppCard(
      child: Row(
        children: [
          SkeletonBlock(
            width: Space.s600,
            height: Space.s600,
            radius: Radii.lg,
          ),
          SizedBox(width: Space.s200),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SkeletonBlock(width: 140, height: Space.s300),
                SizedBox(height: Space.s75),
                SkeletonBlock(width: 200, height: Space.s200),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
