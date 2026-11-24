# Splitwise feature research

_Date: 2026-11-24. Goal: map what Splitwise does, where it hurts, and what a plain, simple alternative (SplitTab) should and shouldn't copy._

> **Note on sources:** splitwise.com wasn't reachable from the research environment. The pricing and limit figures below come from third-party reviews and app-store listings, and they disagree with each other. Check them against the live Splitwise pricing page before quoting them publicly.

---

## 1. Splitwise feature inventory

### Core (free)
| Area | What it does |
|---|---|
| **Friends & groups** | Track balances 1:1 with a friend, or inside a group (trip, flat, couple). |
| **Add expense** | Description, amount, who paid, who's involved, date, group, notes, photo. |
| **Split types** | Equally · exact amounts · percentages · shares (e.g. "2 shares" for a couple) · adjustment (+/-). |
| **Multiple payers** | More than one person paid toward one bill. |
| **Balances** | Per-friend, per-group, and a total "you owe / you are owed" dashboard. |
| **Settle up** | Record a payment (cash, or via integrations like PayPal/Venmo in some regions). |
| **Simplify debts** | Optional group setting that reroutes payments to minimise transfers (A→B→C becomes A→C). |
| **Recurring expenses** | Repeat rent, bills, subscriptions weekly/monthly/yearly. |
| **Categories** | Auto/manual categories (food, rent, utilities…). |
| **Activity feed + comments** | Change log of every add/edit/delete, comments on expenses. |
| **Reminders** | Nudge a friend to pay. |
| **Multi-currency** | Expenses in different currencies (conversion is Pro). |
| **Itemize** | Split a receipt line by line. A newer free flow lets friends join via QR code without installing the app.[^dt] |
| **Export** | CSV export of a group. |

### Pro (paid, about $3–5/month or $30–50/year depending on region and source)
- **No daily expense cap** (see §2; this is the user's main complaint)
- Receipt scanning with OCR itemization
- Currency conversion
- Search across expenses
- Charts and spending graphs
- Default split per group
- No ads
- Early access to new features

---

## 2. Pain points

### 2.1 The daily entry cap is the biggest frustration
- Free users can add only a few expenses per day. Reported numbers range from **2 to 5 a day**, sometimes with a cooldown between entries, and Splitwise doesn't publish the figure.[^limit]
- This breaks the most common real situation: **coming back from a trip with 20 receipts to log at once.** It's the exact case where people need the app most.
- Reviewers say Splitwise paywalled useful features instead of adding new ones.[^reviews]

### 2.2 Concepts that confuse people
| Concept | Why it confuses | Source |
|---|---|---|
| **Non-group expenses** | They count in your dashboard total but in no group's total, so a group can look settled while the dashboard still says you owe money. | Splitwise support[^nongroup] |
| **Simplify debts** | It changes who you're told to pay. You end up paying someone you never shared a bill with. It's off by default, buried in advanced settings, and Splitwise itself admits it "can sometimes cause serious confusion". | Splitwise support, UserVoice[^simplify] |
| **Dashboard vs group balances** | The two numbers often differ, which leads to "my balances are wrong" support tickets. | Splitwise support[^wrong] |
| **Too many split modes up front** | Five split types plus multiple payers on one form is heavy for the 90% case of "split equally". | Review consensus |
| **Itemize limits** | Users report items can only be split 50/50 or 100/0, not by custom percentage.[^itemize] | App Store review |

### 2.3 Other friction
- Everyone needs an account. Splid and Spliit show that a shared link or code with no sign-up works well.[^alts]
- Ads on the free tier.
- Search sits behind the paywall, which makes it hard to find "that dinner in March".

---

## 3. Competitor snapshot

| App | Positioning | Notable |
|---|---|---|
| **Tricount** (bunq) | Trip-focused, free | No entry cap, multi-currency, works in a browser |
| **Splid** | No-signup | Join a group with a code, no account needed |
| **Settle Up** | Long-running shared costs | Offline support, cheap premium (~$19/yr) |
| **Spliit** (open source) | Free, self-hostable | Link-based groups with no accounts; even/shares/%/amount splits; categories; optional AI receipt scan. Splitwise import is still a pending issue.[^spliit] |
| **SplitPro** (open source) | Splitwise clone | Has an "Import from Splitwise" feature |

**Takeaway:** the market already proves that "free, no cap, no signup" is wanted. Our edge has to be simplicity and fast bulk entry, not just being free.

---

## 4. Opportunities for SplitTab

### 4.1 Fix the main pain: fast multi-entry
- **No entry limits at all.** This is the whole reason for SplitTab.
- **Bulk add mode:** a spreadsheet-like table (rows of description, amount, payer, split) where you can tab through and add 20 expenses in a minute.
- **"Same as last" defaults:** remember the last payer and split per group, so most entries are just a description and an amount.
- **Paste / CSV import:** paste lines like `Dinner 84.50 Alex` or import a bank or Splitwise CSV export.
- **Quick-add sheet:** one input, natural-ish parsing ("taxi 30 paid by me split all").

### 4.2 Remove confusing concepts
- **Everything lives in a group.** A 1:1 split is just a two-person group, so "non-group expenses" go away and the dashboard always equals the sum of the groups.
- **Settle-up suggestions, not a hidden setting.** Always show the balance per person. When settling, show "fewest payments" as a clearly explained suggestion with both views visible, instead of a toggle buried in settings.
- **Progressive split options:** default to Equally among everyone. "Customize" expands to exact, %, or shares. Adjustments and multiple payers stay under an advanced option.

### 4.3 Keep free what Splitwise charges for (cheap for us to build)
- Search, charts by category, CSV export, default split per group, no ads.
- Currency conversion: can be free using a daily rates API, which is cheap.
- Receipt OCR: possibly later, since it costs real money per scan.

### 4.4 Low-friction sharing
- Invite with a link. Friends can view and add without an account, then optionally claim a profile later.

---

## 5. Proposed MVP scope (draft, to discuss)

**In**
1. Groups: create, invite by link, members (with or without accounts)
2. Add expense: amount, description, payer, date; split equally or customize (exact / % / shares)
3. **Bulk add** table + "same as last" defaults
4. Balances per group + overall (always consistent)
5. Settle up: record payment, with "fewest payments" suggestion shown transparently
6. Activity log (who added or edited what)
7. Search + CSV export

**Later**
- Recurring expenses
- Multi-currency with conversion
- Receipt scanning / itemize
- Comments, reminders, payment-app deep links
- Splitwise CSV import (a good migration hook)

**Explicitly not doing**
- Non-group expenses as a separate concept
- Entry caps, ads, or paywalls on core features

---

## 6. Open questions
1. **Platform:** web app first (PWA, installable on phones), or native mobile?
2. **Accounts:** link-only groups like Spliit, accounts like Splitwise, or both (guest first, claim later)?
3. **Offline:** must entry work offline, for example on a trip with no signal?
4. **Business model:** completely free, open source, or a donation or cheap pro tier for costly features like OCR?
5. **Target user first:** travel groups (bursty bulk entry) or roommates (recurring bills)? This decides whether bulk add or recurring comes first.

---

### Sources
[^limit]: [Splitwise Free vs Pro 2026](https://split-circle-landing.pages.dev/en/blog/splitwise-free-vs-pro) · [Splitwise Pricing 2026 (Finny)](https://getfinny.app/blog/splitwise-pricing-2026) · [Splitwise Pro vs Free 2026](https://app-partly.web.app/en/blog/splitwise-pro-vs-free-2026/) · [MoneyCrashers review](https://www.moneycrashers.com/splitwise-review/) · [App Store listing](https://apps.apple.com/us/app/splitwise/id458023433)
[^reviews]: [Trustpilot](https://au.trustpilot.com/review/splitwise.com) · [App Store listing](https://apps.apple.com/us/app/splitwise/id458023433)
[^dt]: [Digital Trends: Splitwise itemize](https://digitaltrends.com/phones/splitwise-now-lets-you-calculate-everyones-share-of-a-restaurant-bill-including-tax-and-tip/)
[^nongroup]: [Splitwise: dashboard balances differ from group](https://splitwise.uservoice.com/knowledgebase/articles/746853-my-dashboard-balances-are-different-than-my-group)
[^simplify]: [UserVoice: simplify debts toggle](https://splitwise.uservoice.com/forums/162446-general/suggestions/5702058-enable-a-toggle-between-simplify-debts-on-and-o) · [UserVoice: make simplify debts more accessible](https://splitwise.uservoice.com/forums/162446-general/suggestions/9376035-make-simplify-debts-more-accessible) · [UserVoice: transfer debt](https://splitwise.uservoice.com/forums/162446-general/suggestions/3443268-make-a-way-to-transfer-debt-between-two-people)
[^wrong]: [Splitwise: help, my balances are wrong](https://splitwise.uservoice.com/knowledgebase/articles/425486-help-my-balances-are-wrong)
[^itemize]: [App Store listing (reviews)](https://apps.apple.com/gb/app/id458023433)
[^alts]: [Best Splitwise alternatives 2026 (Finny)](https://getfinny.app/blog/best-splitwise-alternatives-2026) · [Lifehacker: five free alternatives](https://www.lifehacker.com.au/2024/02/the-five-best-free-alternatives-to-splitwise/) · [Tricount blog](https://tricount.com/blog/top-splitwise-alternatives-in-india-2025-which-app-should-you-switch-to) · [Tabb: Splitwise alternative](https://tabb-landing.pages.dev/blog/splitwise-alternative)
[^spliit]: [Spliit on GitHub](https://github.com/spliit-app/spliit) · [Spliit issue #22 (Splitwise import)](https://github.com/spliit-app/spliit/issues/22) · [SplitPro](https://github.com/oss-apps/split-pro) · [DeepWiki: Spliit](https://deepwiki.com/spliit-app/spliit)
