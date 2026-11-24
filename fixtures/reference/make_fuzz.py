"""Generates fixtures/fuzz/random-cases.json: random trips with expected results from the Python
reference. Other implementations (Dart VM, Dart compiled to JavaScript) must match them exactly.

Includes invalid inputs on purpose, so error codes are compared too.

    python3 fixtures/reference/make_fuzz.py          # rewrites the file (deterministic, seed below)
"""
from __future__ import annotations

import json
import random
from pathlib import Path

from splittab_ref import compute

SEED = 2026
COUNT = 400
OUT = Path(__file__).resolve().parent.parent / "fuzz" / "random-cases.json"
EXPONENTS = {"USD": 2, "EUR": 2, "JPY": 0, "KWD": 3, "VND": 0}


def parts(rng: random.Random, total: int, k: int) -> list[int]:
    cuts = sorted(rng.randint(0, total) for _ in range(k - 1))
    return [b - a for a, b in zip([0] + cuts, cuts + [total])]


def decimal(units: int, scale: int) -> str:
    """Integer `units` of 10^-scale as an exact decimal string."""
    whole, frac = divmod(units, 10 ** scale)
    return f"{whole}.{frac:0{scale}d}"


def gen_split(rng, members, amount):
    among = rng.sample(members, rng.randint(1, len(members)))
    kind = rng.choice(["equal", "equal", "exact", "percent", "shares", "nights"])
    sign = -1 if amount < 0 else 1
    if kind == "equal":
        return {"type": "equal", "among": among}
    if kind == "exact":
        amounts = {m: p * sign for m, p in zip(among, parts(rng, abs(amount), len(among)))}
        if rng.random() < 0.01:  # corrupt a few on purpose -> split_sum_mismatch
            amounts[among[0]] += 1
        return {"type": "exact", "amounts": amounts}
    if kind == "percent":
        units = parts(rng, 10000, len(among))  # hundredths of a percent
        pcts = {m: decimal(u, 2) for m, u in zip(among, units)}
        if rng.random() < 0.01:
            pcts[among[0]] = decimal(units[0] + 1, 2)  # -> percent_sum_invalid
        return {"type": "percent", "percents": pcts}
    if kind == "shares":
        return {"type": "shares", "shares": {m: decimal(rng.randint(0, 50), 1) for m in among}}
    total_nights = rng.randint(1, 5)
    nights = {m: sorted(rng.sample(range(1, total_nights + 1), rng.randint(0, total_nights))) for m in among}
    if rng.random() < 0.97:  # usually make sure every night has someone; sometimes not -> night_uncovered
        for night in range(1, total_nights + 1):
            if not any(night in ns for ns in nights.values()):
                m = rng.choice(among)
                nights[m] = sorted(nights[m] + [night])
    return {"type": "nights", "total_nights": total_nights, "nights": nights}


def gen_case(rng: random.Random, i: int) -> dict:
    members = [f"m{j}" for j in range(rng.randint(2, 7))]
    expenses = []
    for k in range(rng.randint(1, 9)):
        size = rng.choice([1000, 100_000, 100_000, 100_000, 5_000_000_000] + [8_000_000_000_000] * (rng.random() < 0.03))
        amount = rng.randint(0, size) * rng.choice([1, 1, 1, -1])
        payers = rng.sample(members, rng.randint(1, min(3, len(members))))
        sign = -1 if amount < 0 else 1
        paid_by = {m: p * sign for m, p in zip(payers, parts(rng, abs(amount), len(payers)))}
        if rng.random() < 0.005:
            paid_by[payers[0]] += 1  # -> payer_sum_mismatch
        e = {"id": f"e{k}", "amount": amount, "paid_by": paid_by, "split": gen_split(rng, members, amount)}
        if size <= 100_000 and rng.random() < 0.4:
            e["currency"] = rng.choice(["EUR", "JPY", "KWD", "VND"])
            if rng.random() > 0.01:  # sometimes omit the rate -> missing_rate
                e["rate"] = decimal(rng.randint(1, 300_000_000), rng.choice([2, 4, 6, 8]))
        expenses.append(e)
    case = {
        "id": f"fuzz-{i:03d}",
        "trip": {"home_currency": "USD", "members": members},
        "currency_exponents": EXPONENTS,
        "expenses": expenses,
    }
    if rng.random() < 0.4:
        a, b = rng.sample(members, 2)
        case["payments"] = [{"from": a, "to": b, "amount": rng.randint(1, 50_000)}]
    return case


def main() -> None:
    rng = random.Random(SEED)
    cases = []
    for i in range(COUNT):
        case = gen_case(rng, i)
        got = compute(case)
        if "error" in got:
            expected = {"error": got["error"]}
        else:
            expected = {
                "balances": got["balances"],
                "min_payments": got["settle"]["min_payments"],
                "direct": got["direct"],
                "expense_home_totals": got["expense_home_totals"],
                "expense_owed": got["expense_owed"],
            }
        case["expected"] = expected
        cases.append(case)
    OUT.parent.mkdir(exist_ok=True)
    OUT.write_text(json.dumps(cases, separators=(",", ":")) + "\n")
    errors = sum("error" in c["expected"] for c in cases)
    print(f"wrote {len(cases)} cases ({errors} invalid) to {OUT.relative_to(OUT.parent.parent.parent)}")


if __name__ == "__main__":
    main()
