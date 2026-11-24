# Travel focus: smart expense capture

_Date: 2026-11-24. Decision: **SplitTab is for travel groups.** This doc works through the "capture it before you forget" features: day-end location reminders, payment-triggered prompts and voice to split, plus related ideas. It also covers what each one needs from the platform._

## The core idea
On a trip, the problem isn't splitting. It's **remembering to log** things while you're busy. Most "balances are wrong" complaints (see doc 02) start as **missed or duplicated entries**. So SplitTab should:

1. **Notice** when an expense probably happened (place visited, payment made).
2. **Nudge** at the right moment, without becoming spam.
3. Make logging take **one tap or one sentence**.

All of this applies only during an **active trip** (a group with start and end dates that you've recently opened), which matches the idea of prompting only if the user has used the app recently.

---

## Feature 1: Day-end recap reminder (location-aware)

**User story:** at 9:30 pm local time: _"You visited 5 places today and logged 2 expenses. Add the rest?"_ Tapping opens a **day timeline** showing the places visited, with gaps where nothing was logged, each one tap from an expense prefilled with the place name and time.

| Aspect | Design |
|---|---|
| Trigger | A scheduled local notification in the **device's current time zone** (follows you across zones), only on trip days. |
| Location signal | Low-power "visits", not GPS tracking. iOS: `CLVisit` / significant-location-change. Android: Fused Location at a low interval plus Activity Recognition. |
| Place names | Reverse geocoding on the device, so a suggestion reads "Café Mondegar, 1:40 pm". |
| Smartness | Count visits that lasted more than 10 min and don't already have an expense at that time. No notification if everything is logged. |
| Privacy | **The location trail never leaves the phone.** Only the expense you choose to save is synced. Clear opt-in screen; turn it off per trip. |

**Variant without location:** a plain day-end reminder plus a "what did you spend on today?" voice prompt. It's the fallback for anyone who says no to location.

---

## Feature 2: Payment-triggered "split this?" prompt

**User story:** you pay ₹2,400 at a restaurant, and within seconds you see: _"₹2,400 at Toit, split with **Goa Trip**?"_ with the actions **[Split equally] [Just me] [Customize]**.

What's possible differs a lot by platform:

| Platform | Mechanism | Feasibility |
|---|---|---|
| **Android: notification listener** | `NotificationListenerService` reads payment notifications from bank, card and payment apps, then we parse amount and merchant. | ✅ **Best option.** The user grants special access in Settings. Needs a prominent disclosure and a clear Play policy declaration. Parsing is done on the device. |
| Android: read SMS | `READ_SMS` for bank text alerts | ⚠️ **Avoid in v1.** It's a restricted permission. Google lists "SMS-based money management" as an exception, but grants it case by case, developers report rejections, and the July 2026 policy update may narrow it further.[^sms] |
| **iOS: Wallet automation** | A Shortcuts "Transaction" (Wallet) trigger passes merchant and amount to our App Intent "Add to SplitTab".[^ios] | ⚠️ **Opt-in power feature.** Apple Pay only, the user sets it up in Shortcuts, and developers report timeouts and empty fields. |
| iOS: read SMS or notifications | None | ❌ Not possible. |
| Both: share or paste | Share a bank SMS, or a screenshot of a payment screen, to SplitTab, which parses it. | ✅ Works everywhere and is easy to build. Good universal fallback. |

**Rules so this doesn't become annoying or wrong:**
- Only during an active trip window, and only for amounts above a small threshold.
- Batch prompts: if the phone was busy, show one notification ("3 payments today: review").
- **Duplicate guard:** if someone in the group already logged a similar amount at a similar time, ask "Is this the same as Rahul's 'Dinner ₹2,400'?"
- Foreign-currency payments: use the charged local amount and currency when the notification includes it.
- Never save automatically. It's always one tap to confirm.

---

## Feature 3: Voice to split

**User story:** hold the mic and say: _"Dinner 2,400, I paid, split between me, Rahul and Priya. Taxi 300 split with everyone."_ SplitTab shows **two draft expenses** for you to confirm.

**Pipeline**
1. **Speech to text:** on-device recognizers on iOS and Android for low latency and privacy, with a cloud speech-to-text model as a fallback for accents and mixed languages.
2. **Understanding:** a small, fast LLM turns the transcript into structured expenses: `{description, amount, currency, payer, participants, split type}`. It uses the **group's member names and the trip currency as context**, so "Priya" maps to the right member and "2.4k" becomes 2,400.
3. **Confirm card:** editable drafts with any uncertain fields highlighted ("Who paid the taxi?"). Nothing is saved without a tap.

**Why it's a strong fit**
- It **is bulk add**: several expenses in one sentence solves Pain #1 in a delightful way.
- Handles natural phrasing: "everyone except Ankit", "Priya and I paid half each", "same as yesterday".
- Works with mixed-language speech (e.g. Hinglish) because an LLM handles parsing.
- Also usable from a home-screen widget, the lock screen, Siri or Google Assistant ("Hey Siri, add to SplitTab"), or by typing the same sentence into the quick-add bar.

**Watch-outs:** a small per-use LLM cost (cheap with a small model), the need for network access (queue the audio or transcript offline and parse when back online), and the privacy note that the audio or transcript goes to a server.

---

## More features along the same line

| Idea | What it does | Effort |
|---|---|---|
| **Trip mode** | A group has dates, a home currency and members. It goes into "active" mode automatically, and settle-up reminders start after the end date. | Low |
| **Auto local currency** | Abroad, new expenses default to the local currency, detected from your location or SIM country. | Low |
| **Quick-add widget / lock-screen action** | Mic plus amount field without opening the app. | Medium |
| **Smart participants** | Defaults to the people from your last expense. Saved subgroups such as "Couple A", "Car 2", "Non-drinkers". | Low |
| **Gap detection** | "No stay logged for night 3", "Day 4 has no food expenses", based on trip days and categories. | Low |
| **Shared cash pool (kitty)** | One person holds the group's cash. Spending from the pool is tracked separately from personal payments. Very common on group trips. | Medium |
| **Receipt photo** | Snap a receipt and OCR prefills the total, with optional itemizing. Overlaps with voice; later. | Medium |
| **Daily trip pulse** | Optional group digest: "Day 3: ₹8,200 spent, you're +₹1,100." Keeps everyone engaged and catches mistakes early. | Low |
| **Offline queue** | Everything (manual, voice transcript, prompts) works offline and syncs later. Must-have for travel. | Medium |
| **End-of-trip wrap-up** | Settle-up plan, payment links (UPI, PayPal, Revolut and others by region), a shareable summary card and CSV. | Medium |
| **Photo-roll nudge** (later) | Spots receipt-like photos taken today on the device. Privacy-sensitive; maybe never. | High |

### Nudge budget (applies to all features)
- At most **1 day-end reminder + batched payment prompts** per day.
- Quiet hours, per-trip mute, and "stop asking about this merchant".
- Turns off by itself after the trip ends, apart from a single settle-up reminder.

---

## Feature 4: "End trip" button → settle up
_Suggested 2026-11-24._

The trip has a clear **End trip** button. Settling happens **after** the trip is ended, not during it, so nobody pays early and then has to pay again when late expenses arrive (a Splitwise pain point in doc 02).

**Flow**
1. **Tap "End trip"** (on the trip home; also suggested by a notification on the trip's end date, but **never automatic**).
2. **Pre-close checklist**: SplitTab shows what's still open before closing:
   - Unconfirmed drafts (voice, payment prompts) waiting for review
   - Offline entries from members' phones that haven't synced yet ("Priya has 2 unsynced expenses")
   - Refundable deposits still pending (bike or hotel deposit)
   - Leftover kitty cash, to be returned to contributors
   - Gap warnings ("No Stay logged for night 3")
3. **Grace period**: members get a notification, "Trip ending: add anything you missed in the next 24 h". The period length is configurable and can be skipped if everyone confirms.
4. **Trip closes**: new expenses are locked and balances freeze. The summary card shows totals, category breakdown and each person's share.
5. **Settle-up plan**: the fewest payments needed, with the direct "who owes whom" view alongside (explainable, per doc 02). Each payment has a **pay link** (UPI, PayPal, Revolut and others by region) and a **"Mark as paid"** button. The receiver confirms they got the money.
6. **Settled**: when every payment is confirmed, the trip moves to **Archived**, read-only and searchable, with a CSV export.

**Rules**
- **Who can end:** any member can start it. Everyone gets notified and can say "wait, I still have expenses" during the grace period.
- **Reopen:** a closed trip can be reopened (for a forgotten expense or a late refund). The settle-up plan is then recalculated, and payments already made count as credit.
- **Reminders:** after closing, at most one gentle reminder every few days for people with unpaid balances, and they stop once settled.
- **Optional mid-trip settling** stays possible for long trips, but it's not the default.

---

## Platform decision: this requires a native app
Background location, scheduled local notifications, notification listening, Wallet App Intents and home-screen widgets **are not available to a PWA**, especially on iOS, where PWAs get no background location or background sync.[^pwa] That overturns the earlier lean toward a PWA.

**Recommendation: React Native with Expo (dev builds), plus a small web view for guests.**
- One TypeScript codebase for iOS and Android. Expo covers location, background tasks, notifications, speech, widgets and offline storage (SQLite).
- A few native pieces are written as small custom modules: the Android `NotificationListenerService` and the iOS App Intent for Wallet automation.
- A **lightweight web page for an invite link** keeps the guest-first flow: friends without the app can view the trip and add an expense. The smart-capture features are the reason to install the app.
- Alternative: Flutter is equally capable. Choose based on the team's language preference (Dart vs TypeScript).

---

## Suggested phasing
| Phase | Scope |
|---|---|
| **v1 (core trip app)** | Trip mode, fast manual and bulk add, explainable balances, edit history and undo, offline queue, invite link + guest web view, per-expense currency, **day-end reminder (time-based)**, settle-up wrap-up. |
| **v1.5 (smart capture)** | **Voice to split** (including several expenses per sentence), **Android payment-notification prompts**, share/paste-to-parse on both platforms, duplicate guard. |
| **v2** | **Location-aware day timeline**, iOS Wallet automation, widgets and assistants, shared cash pool, receipt OCR, gap detection, daily pulse. |

Voice is placed in v1.5, not v2, because it's both the most distinctive feature and the one with the fewest platform risks.

## Open questions
1. **Region focus:** India first (UPI notifications, Hinglish voice, INR) or global? This changes which payment notifications we parse and which payment links we offer.
2. **LLM / speech provider and budget** for voice parsing.
3. **Expo vs Flutter:** any team preference?
4. How strict on privacy: is sending transcripts to a server OK, or must voice work fully on the device?

---
[^sms]: [Google Play: SMS and Call Log permissions](https://support.google.com/googleplay/android-developer/answer/10208820?hl=en) · [Google Play: permissions and sensitive APIs](https://support.google.com/googleplay/android-developer/answer/9888170) · [Developer report of a rejection (DEV Community)](https://dev.to/zeta_byte/ive-been-working-on-a-personal-finance-app-called-finvantage-and-i-recently-hit-a-roadblock-4mjh) · [Android: permissions used only in default handlers](https://developer.android.com/guide/topics/permissions/default-handlers)
[^ios]: [iDropNews: iOS 17 transaction shortcut](https://www.idropnews.com/ios-17/this-new-ios-17-shortcut-will-help-you-keep-track-of-your-spending/197589/) · [Apple forums: transaction trigger timeouts](https://developer.apple.com/forums/thread/765516) · [Apple forums: AppIntents transaction data](https://developer.apple.com/forums/thread/773797) · [Apple forums: Transaction shortcuts flaky](https://developer.apple.com/forums/thread/797233) · [WalletPal Apple Pay automation guide](https://walletpalapp.github.io/apple-pay-expense-tracker-shortcuts.html)
[^pwa]: [MagicBell: PWA iOS limitations](https://www.magicbell.com/blog/pwa-ios-limitations-safari-support-complete-guide) · [Mapp: geofencing limitations](https://docs.mapp.com/limitations) · [Apple forums: background geofencing reliability](https://developer.apple.com/forums/thread/848531) · [DEV: challenges with iOS PWA](https://dev.to/niscontractor/challenges-with-ios-pwa-13ho)
