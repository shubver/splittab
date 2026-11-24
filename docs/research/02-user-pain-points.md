# User pain points: reviews, forums and GitHub issues

_Date: 2026-11-24. Follow-up to [01-splitwise-feature-research.md](01-splitwise-feature-research.md)._

## How this was gathered (and its limits)
| Source | Read directly? | How it was covered |
|---|---|---|
| GitHub issues (Spliit, SplitPro) | ✅ Yes | Issue lists sorted by reactions were read in full. |
| Splitwise UserVoice (official feedback forum) | Partly | Through search results that quote individual threads. |
| App Store / Google Play | ❌ Not reachable from this environment | Quotes come from search snippets and review aggregators (justuseapp, mwm.ai, AppBrain). |
| Reddit | ❌ No threads surfaced | Only secondhand: an X post linking a Reddit thread, and review blogs that summarise Reddit. |
| Trustpilot | ❌ Not reachable | Aggregate ratings came from search results. |

**Caveat:** many "what users say" pages are competitor blogs, so they lean toward "switch away from Splitwise". The themes below are ones that showed up in **several independent sources**. To check them against real users, a manual read of r/Splitwise, r/personalfinance and the Play Store "most relevant" reviews would be worth 30 minutes.

---

## Ratings snapshot
| App | Rating | Note |
|---|---|---|
| Splitwise (Google Play) | ~3.9★ from ~195K reviews | Trustpilot 1.8–2.0★, mostly 1-star |
| Splid | Mostly positive | Complaints centre on calculation accuracy |
| Settle Up | Mostly positive | Complaints centre on ads and price |
| Tricount | Mixed | Data loss and bunq upsell complaints |

---

## Pain-point themes, ranked by how often they appear

### 1. Limits and paywalls on basic actions (Splitwise), by far the loudest
- The free tier allows **about 3 expenses a day**. Splitwise calls it an anti-spam "rate limit" and doesn't publish the number.
  - Splitwise's reply, quoted in a user's Reddit post: _"Splitwise includes rate-limits to prevent spam and bots from generating fake activity."_[^x]
  - Play Store users call it _"a poor business practice"_ and _"a bad look"_, especially long-time users who had the feature for free before.[^play]
- It hurts most **on trips**, where one day produces 10+ expenses.[^hippo]
- Features that used to be free (currency conversion, search, receipt scanning) moved to Pro quietly, and **Pro went from $3 to $5 a month**.[^play]
- Across the market, a commenter says: _"every app out there for splitting bills has in-app purchases, or you need to log in, or has access to your contacts."_[^alt]

**→ SplitTab:** no caps, no paywall on core actions. Say it plainly on the first screen.

### 2. Ads that interrupt entry
- Splitwise users mention timed or full-screen ads between actions.[^play] Settle Up users call its ads _"way too invasive"_ and the app _"way too expensive for what it's offering."_[^settleup]

**→ SplitTab:** no ads. If money is ever needed, use donations or a tiny optional tier for features that are expensive to run, like OCR.

### 3. "My balances are wrong": users don't trust the numbers
This shows up for **every** app, which makes it the most important trust issue.
- **Splitwise:** the dashboard total differs from group totals because of non-group expenses. "Simplify debts" makes payments no longer match the bills.[^sw-help] One user: the total owed _"didn't match their own addition of the individual expenses."_[^bugs]
- **Splid:** _"hundreds of dollars off for one group member"_; _"confusing settlement calculations."_[^splid]
- **Settle Up:** _"the debt settlement algorithm can get a bit weird at times."_[^settleup]
- Early settle-ups make it worse: _"if someone settles up early, they might just need to settle up again after all the expenses are added."_[^bugs]

**→ SplitTab:** make every number explainable. Tapping any balance shows the exact list of expenses and payments behind it. Show "fewest payments" only as a suggestion, side by side with the direct debts. Every expense belongs to a group, so totals always add up.

### 4. Editing, deleting and sync bugs
- **Splitwise:** support admits _"a number of bugs with editing and deleting expenses that involve multiple friends"_. Edits sometimes don't appear for others, and one user had to redo an expense 4 times.[^bugs]
- **Tricount:** a forced update _"wiped a week's worth of trip data mid-trip"_, and support was hard to reach.[^tricount]
- **Settle Up:** payments missing when syncing between iPhone and Android. A bug changed the payer to the first member of the group.[^settleup]
- **Splid:** can't edit or delete past expenses; no date sorting.[^splid]
- **SplitPro:** "Ability to edit an expense" was requested twice (#59, #74).[^gh-sp]

**→ SplitTab:** treat data safety as a feature. Every expense is editable with full history and undo, deleted items go to a recoverable bin, and sync behaves the same on every platform.

### 5. Multi-currency handling
- Splitwise: the app sometimes switches an expense to a different currency than the one entered. Mixed-currency totals per friend are confusing, and conversion is Pro-only.[^bugs]
- Spliit #53, "different currency for each transaction", was its #2 most-discussed issue.[^gh-spliit] There's also a Splitwise UserVoice thread asking to "Allow two (or more) currencies".[^uv]

**→ SplitTab:** each expense has its own currency, the group has one base currency, and conversion is free using a daily-rates API.

### 6. Recurring expenses
- Spliit #5 was the **#1** most-discussed issue. SplitPro #160 was requested repeatedly (plus duplicate #57). Splitwise users ask for an **end date** on recurring bills.[^gh-spliit][^gh-sp][^uv] Splid users miss it too.[^splid]

**→ SplitTab:** must-have for the roommate case. Include an end date or number of repeats from day one.

### 7. Migrating from Splitwise
- Spliit #22 "Import from Splitwise" and SplitPro #307 "Splitwise import 2.0" (still open, heavily discussed), plus #207 and #189.[^gh-spliit][^gh-sp]

**→ SplitTab:** Splitwise CSV import is our best acquisition channel. Users are leaving, but they don't want to lose their history.

### 8. Offline and local-first
- SplitPro #162 "Support for local storage" was its **most-discussed issue**, and #105 asks for an offline mode. Spliit #79 asks to "Improve PWA support".[^gh-sp][^gh-spliit]
- Trips often happen exactly where signal is bad.

**→ SplitTab:** let people add expenses offline and sync later. This argues for a local-first PWA.

### 9. Accounts and onboarding friction (both directions)
- People don't want to force friends to sign up. Splid and Spliit are praised for sharing a code or link. SplitPro #67 asks to add members without email.[^gh-sp]
- But link-only apps get the **opposite** requests: optional authentication (Spliit #257, #336), user accounts (#76), encryption at rest (#34), and deleting your own account (SplitPro #206).[^gh-spliit][^gh-sp]
- Tricount users complain about pushy **bunq bank upsells**, and a linked bunq account can't be unlinked.[^tricount-bunq]

**→ SplitTab:** guest first, account optional. Anyone with the link can view and add; claim your name later to sync across devices. No upsells to third-party products.

### 10. Smaller but recurring
| Request | Evidence |
|---|---|
| Default split method per group | SplitPro #373 (13 comments). It's Pro-only in Splitwise. |
| Multiple payers on one bill | Spliit #14. Missing in Tricount according to reviews. |
| Itemized receipts with custom splits | Spliit #395. Splitwise items limited to 50/50 or 100/0. |
| Tax and tip handling | Splid: _"zero option for taxes"_ |
| Category stats | Spliit #281 |
| Export / overview | Tricount reviewer: lack of export _"becoming a dealbreaker"_ |
| Bank or card transaction import | Splitwise UserVoice thread[^uv] |
| Dated or cluttered UI | Settle Up _"looks a little dated"_ |
| Translations | Spliit #75, SplitPro #83 |

---

## What this changes in our plan

The research confirms the main idea (no caps, fast bulk entry). It adds two things we under-weighted in doc 01:

1. **Trust in the numbers is the real product.** Every app gets "balances are wrong" complaints. Bulk entry gets users in; explainable balances keep them.
2. **Data safety and offline use** matter more than we listed: edit history, undo, a recoverable bin, and offline entry.

### Revised MVP priority
| Priority | Feature | Why |
|---|---|---|
| P0 | Unlimited entry + **bulk add** + "same as last" defaults | Pain #1 |
| P0 | **Explainable balances** (tap to see why) + transparent settle-up suggestion | Pain #3 |
| P0 | Edit, delete with undo, activity history | Pain #4 |
| P0 | Link invite, guest-first, optional account | Pain #9 |
| P1 | Per-expense currency with free conversion | Pain #5 |
| P1 | Recurring expenses with an end date | Pain #6 |
| P1 | Splitwise CSV import | Pain #7 |
| P1 | Offline entry (local-first PWA) | Pain #8 |
| P2 | Multiple payers, itemize with tax and tip, category charts, search, export | #10 |
| Never | Entry caps, ads, third-party upsells | #1, #2, #9 |

### Still-open decisions
1. Platform: local-first **PWA** (fits offline + link sharing + one codebase) vs native.
2. First target: **travel groups** (bulk add, currency, offline) vs **roommates** (recurring, long-running balances).

---

### Sources
[^x]: [X post quoting Splitwise's reply in a Reddit thread](https://x.com/ArtemR/status/1740150704268849568?lang=en) · [Split Circle: Splitwise daily limit](https://split-circle.com/en/blog/splitwise-daily-limit)
[^play]: [Google Play listing](https://play.google.com/store/apps/details?id=com.Splitwise.SplitwiseMobile) · [AppBrain](https://www.appbrain.com/app/splitwise/com.Splitwise.SplitwiseMobile) · [Trustpilot](https://www.trustpilot.com/review/splitwise.com) · [Product Hunt reviews](https://www.producthunt.com/products/splitwise/reviews) · [App Store reviews](https://apps.apple.com/us/app/splitwise/id458023433?see-all=reviews)
[^hippo]: [HippoSplit: Splitwise review 2026, what Reddit says](https://hipposplit.com/blog/splitwise-review/)
[^alt]: [AlternativeTo: Splitwise alternatives](https://alternativeto.net/software/splitwise/?p=2)
[^settleup]: [Settle Up on Google Play](https://play.google.com/store/apps/details?id=cz.destil.settleup&hl=en) · [justuseapp: Settle Up reviews](https://justuseapp.com/en/app/737534985/settle-up-group-expenses/reviews) · [mwm.ai: Settle Up](https://mwm.ai/apps/settle-up-group-expenses/737534985) · [Slashdot: Settle Up](https://slashdot.org/software/p/Settle-Up/)
[^sw-help]: [Splitwise: dashboard vs group balances](https://splitwise.uservoice.com/knowledgebase/articles/746853-my-dashboard-balances-are-different-than-my-group) · [Splitwise: balances wrong](https://splitwise.uservoice.com/knowledgebase/articles/425486-help-my-balances-are-wrong)
[^bugs]: [Splitwise feedback: bug thread](https://feedback.splitwise.com/forums/162446-general/suggestions/3111539-bug-in-split-wise) · [ComplaintsBoard: Splitwise](https://www.complaintsboard.com/splitwise-b149630) · [justuseapp: Splitwise reviews](https://justuseapp.com/en/app/458023433/splitwise/reviews) · [mwm.ai: Splitwise](https://mwm.ai/apps/splitwise/458023433)
[^splid]: [justuseapp: Splid reviews](https://justuseapp.com/en/app/991473495/splid-split-group-bills/reviews) · [mwm.ai: Splid](https://mwm.ai/apps/splid-split-group-bills/991473495) · [App Store: Splid reviews](https://apps.apple.com/us/app/splid-split-group-bills/id991473495?see-all=reviews&platform=iphone) · [Gerald: Splid review](https://joingerald.com/learn/financial-wellness/splid-app-review-split-group-expenses)
[^tricount]: [App Store: Tricount reviews](https://apps.apple.com/us/app/tricount-split-settle-bills/id349866256?see-all=reviews&platform=watch)
[^tricount-bunq]: [Monzo community: Tricount from bunq](https://community.monzo.com/t/new-tool-for-bill-splitting-tricount-from-bunq/194497) · [Tricount FAQ](https://help.tricount.com/articles/tricount-faqs) · [TechCrunch: bunq acquires Tricount](https://techcrunch.com/2022/05/03/bunq-to-acquire-group-expenses-app-tricount)
[^uv]: [UserVoice: recurring end date](https://splitwise.uservoice.com/forums/162446-general/suggestions/11372592-allow-an-end-date-for-recurring-payments-or-build) · [UserVoice: two or more currencies](https://splitwise.uservoice.com/forums/162446-general/suggestions/8532622-allow-two-or-more-currencies) · [UserVoice: bank/card import](https://splitwise.uservoice.com/forums/162446-general/suggestions/11318904-ability-to-select-transactions-from-bank-or-card-h) · [UserVoice: simplify debts](https://splitwise.uservoice.com/forums/162446-general/suggestions/9376035-make-simplify-debts-more-accessible)
[^gh-spliit]: [Spliit issues by reactions](https://github.com/spliit-app/spliit/issues?q=is%3Aissue+sort%3Areactions-%2B1-desc). Note: the counts are most likely comment counts, not reactions.
[^gh-sp]: [SplitPro issues by reactions](https://github.com/oss-apps/split-pro/issues?q=is%3Aissue+sort%3Areactions-%2B1-desc)
