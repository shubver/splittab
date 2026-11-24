# Decisions and tech stack

_Date: 2026-11-24._

## Decisions log
| # | Decision | Choice | Notes |
|---|---|---|---|
| D1 | Target user | **Travel groups** | See doc 03 |
| D2 | Region | **Global from day one** | See "What global means" below |
| D3 | Voice processing | **Server-side first**, on-device later as an optimization | Faster to build, better accuracy across languages. Move to on-device once usage and costs are known. |
| D4 | Mobile framework | **Flutter** | Reasoning below |
| D5 | Backend | **Python (FastAPI)** | Plays to the team's strengths |
| D6 | Settling | **After "End trip"** | See doc 03, Feature 4 |

---

## What "global" means for v1
- **Multi-currency is core, not an add-on.** Every expense has its own currency, and every trip has one home currency for totals and settle-up. Daily exchange rates from a rates API, plus "rate you actually paid" (see ideas backlog).
- **Number, date and currency formats** follow the phone's locale (₹1,00,000 vs $100,000 vs 100.000 €).
- **Translations:** English at launch, with every string kept translatable from day one. Strong next languages for travel groups: Spanish, Portuguese, German, French, Hindi.
- **Voice in many languages and mixed languages:** a server-side speech model handles this better than on-device recognizers, which is one more reason for D3.
- **Payment links by region:** UPI (India), PayPal, Revolut, Wise, Venmo/Cash App (US), PIX (Brazil), bank-transfer details as a fallback. Shown based on members' regions.
- **Merchant keyword lists by region** for auto-categorization (doc 04). Start with India, US and Europe, and let corrections improve them.
- **Tolls** stay a sub-tag under Local transport (doc 04, question 1 resolved).

---

## Why Flutter (for a Python data scientist)
Neither option is Python, so the real question is which is **easier to learn and less fragile** for someone who isn't a mobile developer.

| | **Flutter (Dart)** | Expo (React Native, TypeScript) |
|---|---|---|
| Language for a Python developer | Dart is clean, typed and class-based, a short step from typed Python | TypeScript plus the React model plus the JS ecosystem: more concepts at once |
| Number of moving parts | **One toolkit**: UI, navigation and state all from one framework with excellent docs | Many libraries to choose and keep compatible |
| Clean, custom UI | **Draws every pixel itself**, so the design looks the same on iOS and Android | Uses native components; small differences per platform |
| Packages we need | Notifications, location, speech, home widgets, SQLite and Android notification listener all have mature packages | Also covered; some need custom native modules |
| iOS builds without a Mac | Needs a Mac **or** a cloud build service (Codemagic, GitHub Actions macOS) | Expo's cloud build (EAS) does it out of the box |
| Web version | Flutter web is heavy for a small link page | Can share code with the web |

**Verdict: your instinct is right, Flutter is the better fit.** Its two weak spots are easy to work around:
- **iOS builds:** use Codemagic (it has a free tier) or a GitHub Actions macOS runner. You don't need to own a Mac to start; develop and test on Android first.
- **Guest web page** (friends without the app open the invite link): build it as a **small server-rendered page from the Python backend** (FastAPI + simple HTML). It only needs to show the trip and offer a quick "add expense" form, so it doesn't need Flutter.

---

## Architecture overview
```
┌───────────────────────────────┐        ┌──────────────────────────────────────┐
│  Flutter app (iOS + Android)  │        │  Python backend (FastAPI)            │
│  - UI, offline SQLite (drift) │◄──────►│  - REST/JSON API + sync              │
│  - local notifications        │  HTTPS │  - balances & settle-up engine       │
│  - location visits (on-device)│        │  - voice: speech-to-text → LLM parse │
│  - Android notif. listener    │        │  - categorization (keywords + model) │
│  - mic recording              │        │  - exchange rates (daily job)        │
└───────────────────────────────┘        │  - guest web page for invite links   │
                                         └───────────────┬──────────────────────┘
                                                         │
                                                 ┌───────▼────────┐
                                                 │  PostgreSQL     │
                                                 └────────────────┘
```

**Where your Python expertise matters most** (it's the heart of the product):
- **Balance and settle-up engine**: exact decimal maths, split by nights, vehicle subgroups, minimizing the number of payments. Pure Python with heavy unit tests.
- **Voice pipeline**: audio → transcript → structured expenses with an LLM, matched against members and categories, plus evaluation sets to measure accuracy. This is data science work.
- **Categorization**: start with keyword rules, then learn from user corrections.
- **Payment-notification parsing**: amount, currency and merchant from bank notification text in many formats and languages. Can start on the server for fast iteration, then move parsing onto the device for privacy.

**Suggested components**
| Layer | Choice |
|---|---|
| Mobile | Flutter, Riverpod (state), drift (offline SQLite), go_router |
| Backend | FastAPI, SQLAlchemy + Alembic, Pydantic, pytest |
| Database | PostgreSQL |
| Voice | A hosted speech-to-text API + a small, fast LLM for parsing (provider to be chosen) |
| Hosting | One small container host (e.g. Fly.io, Render or Railway) + managed Postgres |
| Builds | Codemagic or GitHub Actions for iOS/Android |

---

## Suggested build order
1. **Backend core (Python, start here):** data model (trips, members, expenses, splits, payments) + balance/settle-up engine with tests. No app needed yet; your strongest area first.
2. **API + guest web page:** create a trip, add expenses, see balances in a browser. This already makes a usable product to test with friends.
3. **Flutter app v1:** trip home, quick add, bulk add, balances, end trip, offline.
4. **Voice to split:** server pipeline + mic button.
5. **Smart capture:** day-end reminders, Android payment prompts, location timeline.

## Still open
- Voice speech-to-text and LLM provider choice and budget
- Custom categories per trip vs per account (doc 04, question 3)
- Alcohol as its own category or a tag (leaning tag)
