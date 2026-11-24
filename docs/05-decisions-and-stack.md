# Decisions and tech stack

_Date: 2026-11-24 (revised the same day: balance maths moved to Dart, Supabase + PowerSync for sync, infra stance added)._

## Decisions log
| # | Decision | Choice | Notes |
|---|---|---|---|
| D1 | Target user | **Travel groups** | See doc 03 |
| D2 | Region | **Global from day one** | See "What global means" below |
| D3 | Voice processing | **Server-side first**, on-device later as an optimization | Faster to build, better accuracy across languages |
| D4 | Mobile framework | **Flutter** | Developer has a Mac, so local iOS builds work |
| D5 | Balance & settle-up maths | **One Dart package, running on the device** | Works offline; one implementation means numbers never disagree |
| D6 | Data + sync | **Supabase (Postgres, auth, row-level security) + PowerSync (offline SQLite sync)** | No custom sync server to build; both can be self-hosted later |
| D7 | AI service | **Python (FastAPI)** | Voice parsing, notification parsing, categorization, exchange rates |
| D8 | Infrastructure | **Managed services first; Kubernetes/Helm later, when cost or scale justifies it** | See "Infrastructure and scaling" |
| D9 | Settling | **After "End trip"** | See doc 03, Feature 4 |

---

## What "global" means for v1
- **Multi-currency is core.** Each expense has its own currency; each trip has one home currency for totals and settle-up. Daily exchange rates, plus "rate you actually paid".
- **Formats follow the phone's locale** (₹1,00,000 vs $100,000 vs 100.000 €).
- **Translations:** English at launch, every string translatable from day one.
- **Voice in many and mixed languages:** a server-side speech model handles this better than on-device recognizers (D3).
- **Payment links by region:** UPI, PayPal, Revolut, Wise, Venmo/Cash App, PIX, plus bank details as a fallback.
- **Merchant keyword lists by region** for auto-categorization (doc 04). **Tolls** stay a sub-tag under Local transport.

---

## Why the money maths lives in Dart, on the phone
The app must work offline on a trip, so **balances must be computed on the device.** If the same maths also existed in Python on a server, two implementations could drift apart (rounding, edge cases) and show different numbers, which is the "my balances are wrong" complaint that hurts every competitor (doc 02).

So:
- `splittab_core`: a **pure Dart package** (no UI, no I/O) with money arithmetic in integer minor units, splits (equal, exact, %, shares, by nights, subgroups, per person), balances, and settle-up (fewest payments + direct view).
- **Language-neutral test fixtures** (`fixtures/*.json`: input trip → expected balances and settle-up) are the reference answers. They can be written or checked in Python notebooks; the Dart package must pass all of them.
- The server never recomputes balances; it only stores and syncs expenses.

---

## Architecture
```
┌──────────────────────────────────────┐
│ Flutter app (iOS + Android)          │
│  - UI                                │
│  - splittab_core (balances, settle)  │
│  - local SQLite via PowerSync SDK    │──── sync ────┐
│  - notifications, location visits,   │              │
│    Android notification listener     │              ▼
└───────────────┬──────────────────────┘    ┌──────────────────┐     ┌──────────────┐
                │                           │ PowerSync service│◄───►│ Supabase     │
                │ HTTPS (voice, parse)      └──────────────────┘     │ Postgres     │
                ▼                                                    │ Auth, RLS    │
┌──────────────────────────────────────┐                             │ Storage      │
│ Python AI service (FastAPI)          │◄────────────────────────────┤ (receipts,   │
│  - speech-to-text → LLM → drafts     │   reads members/categories  │  audio)      │
│  - payment-notification parsing      │                             └──────────────┘
│  - categorization (rules → model)    │
│  - exchange-rates daily job          │
└──────────────────────────────────────┘

Guest web page (invite link): a small Flutter web build that reuses splittab_core,
so guests see exactly the same numbers as the app.
```

---

## Infrastructure and scaling
**A realistic sense of load:** an expense-splitting app has tiny data and low traffic per user. Even **1 million users** adding ~5 expenses a day is around **60 writes/second on average**, which a single managed Postgres handles easily. **The database and sync won't be the scaling problem.**

**The one heavy workload is the AI service:** speech-to-text and LLM calls, which are bursty (evenings on trips) and cost real money per request. That's where your Ray and Kubernetes experience pays off.

### Phase 1: launch (managed, near-zero ops)
- Supabase cloud (Postgres, Auth, Storage) and PowerSync cloud.
- Python AI service as **one container** on a simple host (Fly.io, Render, Cloud Run), calling **hosted** speech and LLM APIs.
- Cost: free tiers to tens of dollars a month. Time goes into the product, not the cluster.

### Phase 2: growth (when AI API costs or latency hurt)
- Move the AI service to **Kubernetes, deployed with Helm**.
- **Self-host the speech model** (Whisper-class) on GPUs with **Ray Serve**: autoscaling replicas, batching requests, scaling to zero off-peak.
- Optionally a small open-weight LLM for parsing, falling back to a hosted LLM for hard cases.
- Batch jobs (retraining the categorizer on user corrections, evaluation runs) on Ray.

### Phase 3: full ownership (only if needed: cost, data residency, compliance)
- **Self-host Supabase and PowerSync** on the same cluster with Helm (both have self-hostable versions), with managed Postgres or a Postgres operator.

**Exit path built in:** every component is open source or self-hostable (Postgres, Supabase, PowerSync open edition, FastAPI, Ray), so moving from managed to self-hosted is a migration, not a rewrite.

### Ground rules from day one (cheap now, saves pain later)
- Everything ships as a container. A Dockerfile per service from the first commit.
- Configuration through environment variables; no hard-coded hosts.
- The AI service is **stateless**: drafts go back to the app, and only confirmed expenses are written to the database.
- Structured logs and basic metrics (latency, cost per voice request, parse accuracy).

---

## Build order
1. **Balance fixtures:** about 30 JSON test cases covering equal and uneven splits, by nights, subgroups, multiple currencies, rounding, settle-up. Drafted and checked in Python.
2. **`splittab_core` in Dart:** passes every fixture. A small, self-contained first Dart project.
3. **Supabase schema + PowerSync sync rules:** trips, members, expenses, splits, payments, with row-level security.
4. **Flutter app v1:** trip home, quick add, bulk add, balances, End trip, offline.
5. **Python AI service:** voice to split, then payment-notification parsing and categorization.
6. **Smart capture:** day-end reminders, Android payment prompts, location timeline.

## Still open
- Speech-to-text and LLM provider choice and budget
- Custom categories per trip vs per account (doc 04, question 3)
- Alcohol as its own category or a tag (leaning tag)
