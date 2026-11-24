# Travel expense categories

_Date: 2026-11-24. Builds on [03-travel-smart-capture.md](03-travel-smart-capture.md)._

## Principles
1. **A short list that fits one screen.** 10 main categories plus "Other". Picking a category should be one tap, never a scrolling search.
2. **Categories do work, not just labels.** Each one can carry a **smart default**: which split applies, who's included, and what details to ask for. This is where we beat generic apps.
3. **Auto-detected first, picked second.** Voice, payment prompts and merchant names fill in the category; the user only corrects it.
4. **Sub-categories are optional tags** for travellers who want detail, never a required second step.
5. **Customizable per trip:** hide what you don't need (no "Flights" on a road trip) and add your own (e.g. "Scuba").

---

## The default list

| # | Category | Icon | Covers (sub-tags) | Smart default |
|---|---|---|---|---|
| 1 | **Stay** | 🏨 | Hotel, hostel, Airbnb/homestay, camping, resort | Asks for **number of nights** and suggests splitting by who stayed which nights (see "Split by nights"). |
| 2 | **Food & Drinks** | 🍽️ | Breakfast, lunch, dinner, snacks, café, groceries, **alcohol** | Splits among everyone present. The alcohol tag can exclude a saved "non-drinkers" subgroup. |
| 3 | **Fuel** | ⛽ | Petrol, diesel, EV charging | Defaults to the **vehicle subgroup** (e.g. "Car 2" riders), not the whole group. |
| 4 | **Vehicle rental** | 🚗 | Car rental, **bike/scooter rental**, self-drive, driver charges, deposit | Same vehicle subgroup. Marks a **refundable deposit** so it can be reversed later (see below). |
| 5 | **Local transport** | 🚕 | Taxi/cab, auto-rickshaw, ride-hailing, metro, bus, ferry, parking, **tolls** | Splits among the riders (defaults to the people in your last transport expense). |
| 6 | **Travel tickets** | ✈️ | Flights, trains, intercity buses, cruises | Usually paid by one person for the whole group. Asks **"one ticket each or shared?"** so per-person fares split exactly. |
| 7 | **Activities** | 🎟️ | Entry tickets, tours, guides, adventure sports, events, nightlife cover | Many activities aren't for everyone, so it **asks who joined**, prefilled from the last activity. |
| 8 | **Shopping** | 🛍️ | Souvenirs, gear, clothes, gifts | Defaults to **"Just me" / for one person** (shopping is usually personal); one tap to share. |
| 9 | **Essentials** | 🧴 | Medicine, toiletries, SIM/data, laundry, water | Splits equally. |
| 10 | **Fees & permits** | 🧾 | Visa, travel insurance, park/area permits, entry fees, ATM/FX fees, tips | Visa and insurance default to **per person**; tips split among those present. |
| — | **Other** | ⋯ | Anything else | Splits equally. |

**Separate from categories:**
- **Settlement / payment between members.** This isn't spending, so it never shows up in category totals.
- **Kitty top-up.** Money added to the shared cash pool also isn't spending (see doc 03).

### Order on screen
Show the **most used in this trip first**, starting from a sensible default: Food & Drinks, Stay, Local transport, Fuel, Activities, Vehicle rental, Travel tickets, Shopping, Essentials, Fees & permits, Other. After a few entries the order adapts per trip, so road trips float Fuel and Tolls up while backpacking trips float Local transport and Stay.

---

## Smart defaults in detail

### Split by nights (Stay)
"Hotel ₹18,000, 3 nights" → a small grid of who stayed each night:

```
            Night 1  Night 2  Night 3
Rahul         ✓        ✓        ✓
Priya         ✓        ✓        –      (left early)
Ankit         –        ✓        ✓      (joined late)
```
The split follows the nights stayed, covering people who join late or leave early, which is very common on group trips and painful to work out by hand elsewhere.

### Vehicle subgroups (Fuel, Vehicle rental, Tolls)
Road trips with two cars or several bikes are common. You create subgroups once ("Car 1", "Car 2", "Bikes") and Fuel, Rental and Tolls default to that vehicle's riders.

### Refundable deposits (Vehicle rental, Stay)
"Bike deposit ₹5,000 (refundable)" is tracked as **pending**. When it comes back, one tap marks it refunded and reverses it, minus any deduction. The deposit doesn't count toward the trip's total spending.

### Per-person vs shared (Travel tickets, Fees)
Flights, visas and insurance are usually **per person, not shared**. "Paid 4 flight tickets, ₹6,200 each" assigns exactly ₹6,200 to each traveller, so differing fares don't get averaged.

### Exclude-by-default subgroups
Saved groups like "Non-drinkers" or "Vegetarians" can be excluded automatically from matching tags (alcohol, a specific meal). It's always visible on the confirm card and editable.

---

## Auto-categorization
| Input | How the category is picked |
|---|---|
| **Voice** | The AI parser sees the category list: "petrol 2000" → Fuel; "Airbnb" → Stay; "scooty rent" → Vehicle rental. |
| **Payment notification / Wallet** | Merchant name keywords (`HPCL`, `Shell`, `Indian Oil` → Fuel; `OYO`, `Airbnb`, `Marriott` → Stay; `Uber`, `Ola`, `Rapido` → Local transport; `FASTag` → Tolls). iOS Wallet also provides a merchant category we can map. |
| **Manual** | The description is matched as you type ("dinner" → Food). The tap target stays the main input. |
| **Learning** | If a user corrects a merchant's category once, remember it for the rest of the trip. |

Keyword lists are kept **per region** (India, Europe, US, Southeast Asia) so fuel-station and transport brands match local names.

---

## Where categories show up
- **Trip summary:** a spending breakdown by category ("Stay 38%, Food 27%, Fuel 14%…"), per person and for the group.
- **Gap detection** (doc 03): "No Stay logged for night 3"; "Day 4 has no Food."
- **Daily pulse:** "Day 2: Food ₹3,100 · Fuel ₹2,000 · Activities ₹4,500."
- **Per-person view:** "Your share by category" so everyone sees where their money went.
- **Export:** a category column in the CSV.

## Data model notes (for implementation)
- `category` is a fixed **id** (`stay`, `food`, `fuel`, `vehicle_rental`, `local_transport`, `tickets`, `activities`, `shopping`, `essentials`, `fees`, `other`), with names translated in the app. Optional `tags[]` hold the sub-categories.
- Each category has a `default_split_rule`: `equal_all`, `equal_last_participants`, `vehicle_subgroup`, `per_person`, `by_nights`, `just_me` or `ask_participants`.
- A trip stores its `hidden_categories[]` and `custom_categories[]` (name, emoji, default rule).
- A deposit is a flag on the expense (`refundable: true`, `refund_status`), not a separate category.

## Open questions
1. **Region focus** (still open): it decides the default keyword lists and whether "Tolls" deserves a main slot (frequent on Indian or US road trips) or stays a sub-tag.
2. Should **Alcohol** be its own top-level category? It's often split differently, but it adds clutter. Current proposal: a tag under Food & Drinks with an exclusion rule.
3. Should hidden or added categories apply only to one trip, or to the user's account as a whole?
