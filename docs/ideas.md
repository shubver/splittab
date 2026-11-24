# Ideas backlog

A running list of ideas for SplitTab. Add new ideas at the top of **Inbox** with a date. When an idea is discussed, move it to **Accepted** (with a link to its doc) or **Parked** (with a reason).

**Format:** `- [YYYY-MM-DD] **Idea name**: one-line description. _(source / who)_`

---

## Inbox (not yet discussed)
- [2026-11-24] **Trip budget**: set a total or per-day budget per trip; the daily pulse shows "₹2,000 under budget today". _(Claude)_
- [2026-11-24] **Pre-trip planning mode**: log advance bookings (flights, stays) before the trip starts, then the trip goes "active" on its start date. _(Claude)_
- [2026-11-24] **Who owes the most right now**: a single glance card on the trip home showing who should pay next, to even out balances during the trip instead of settling at the end. _(Claude)_
- [2026-11-24] **Split a single item quickly**: "I'll take the bill, you pay the next one" pairing to reduce the number of entries. _(Claude)_
- [2026-11-24] **Trip templates**: reuse members, subgroups and categories from a past trip ("Goa gang 2027"). _(Claude)_
- [2026-11-24] **Trip memories export**: an end-of-trip summary card with stats (km of fuel, nights, most expensive day) to share on social media, which doubles as marketing. _(Claude)_
- [2026-11-24] **Map view**: expenses pinned on a map of the trip (uses on-device location from the day timeline). _(Claude)_
- [2026-11-24] **Currency rate lock**: use the rate you actually paid (from a card notification or forex purchase) instead of the daily market rate. _(Claude)_
- [2026-11-24] **Multiple payers via voice**: "Rahul paid 1,000 and I paid 1,400" parsed into one expense with two payers. _(Claude)_
- [2026-11-24] **Guest reminders by WhatsApp or SMS share link**: nudge members who haven't installed the app. _(Claude)_

## Accepted (documented)
| Idea | Doc |
|---|---|
| No entry caps, no ads, fast bulk add | [01](research/01-splitwise-feature-research.md), [02](research/02-user-pain-points.md) |
| Explainable balances, edit history and undo, offline entry | [02](research/02-user-pain-points.md) |
| Travel-group focus, trip mode | [03](research/03-travel-smart-capture.md) |
| Day-end reminder, location-aware day timeline | [03](research/03-travel-smart-capture.md) |
| Payment-triggered "split this?" prompt | [03](research/03-travel-smart-capture.md) |
| Voice to split (several expenses per sentence) | [03](research/03-travel-smart-capture.md) |
| Cash kitty, gap detection, daily pulse, widgets, end-of-trip wrap-up | [03](research/03-travel-smart-capture.md) |
| "End trip" button: checklist → grace period → freeze → settle-up plan → archive _(suggested 2026-11-24)_ | [03](research/03-travel-smart-capture.md#feature-4-end-trip-button--settle-up) |
| Travel categories with smart default splits (by nights, vehicle subgroups, deposits, per person) | [04](research/04-travel-categories.md) |

## Parked
| Idea | Reason |
|---|---|
| Reading bank SMS on Android | Restricted Play permission, often rejected; notification listener + share/paste instead. See [03](research/03-travel-smart-capture.md). |
| Photo-roll receipt nudge | Too privacy-sensitive for now. |

---

## Decisions
Full log and reasoning: [05-decisions-and-stack.md](05-decisions-and-stack.md).

| Decision | Choice | Status |
|---|---|---|
| Region focus | **Global** | Decided |
| Mobile framework | **Flutter** | Decided |
| Balance maths | **Dart package on the device** (one implementation) | Decided |
| Data + sync | **Supabase + PowerSync** | Decided |
| AI service | **Python (FastAPI)** | Decided |
| Infrastructure | **Managed first; Kubernetes/Helm + Ray Serve for AI later** | Decided |
| Voice | **Server-side first**, on-device later | Decided |
| Alcohol | Own category vs tag under Food & Drinks | Open (leaning tag) |
| Custom categories | Per trip vs per account | Open |
| Speech/LLM provider | To be chosen | Open |
