# SplitTab app

Flutter app (iOS, Android, web) for splitting travel expenses. Works offline: everything is stored on the device and
all money maths comes from [`splittab_core`](../../packages/splittab_core/README.md).

## What is built
- **Trips:** create a trip with friends and a currency for totals. Trips list with your balance on each.
- **Add expense:** amount, currency (with exchange rate), category, who paid, who shares. Equal split by default,
  with **Customize** for exact amounts, percentages or shares. Shows each person's share before you save.
- **Bulk add:** type many expenses in one go, one payer and one group for all rows, Enter moves to the next row.
- **Explainable balances:** tap anyone to see every expense and payment behind their number.
- **End trip, then settle:** ending locks new expenses, then shows the fewest payments (or who owes whom) with
  "Mark as paid". Reopen any time.
- Light and dark themes, from the design tokens in `lib/design/`.

## Not built yet
Editing an expense (delete and add again for now), multiple payers in the UI, syncing between phones, voice,
reminders and payment prompts, guest links.

## Design system
`lib/design/` holds the tokens from the design skill: spacing scale, radii, flat dark palette, named text styles
(Heading, Title, Body, Button, Caption), the decelerating motion curve, and shared widgets with hover, pressed,
focus, loading, empty and error states. Typeface is Geist, icons are Phosphor. Copy is sentence case with no hyphens.

## Run and check
```bash
flutter pub get
flutter analyze
flutter test                                   # unit tests plus a full widget flow
flutter build web --release --no-web-resources-cdn   # bundles the rendering engine, so it works offline
SHOTS_DIR=/some/folder flutter test tool/screenshots_test.dart   # renders every screen to PNG
```
`--no-web-resources-cdn` matters: by default the web build downloads its rendering engine from Google's CDN.

## Notes
- Flutter 3.50 moved Material to `package:material_ui`. The `phosphor_flutter` package does not compile on it
  (`IconData` became final), so icons come from the Phosphor font directly: `lib/design/icons.dart`.
- Storage is a JSON list in `shared_preferences`. Only `lib/data/store.dart` changes when sync arrives.
