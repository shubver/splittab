"""Checks the JSON fixtures against the Python reference implementation.

Run from the repo root:   python3 -m pytest fixtures/reference -q

Two independent safety nets:
  1. Expected values in fixtures/cases/*.json were worked out BY HAND, then compared with the
     reference here. A mismatch means either the hand calculation or the reference is wrong.
  2. Property tests (invariants + a brute-force minimum-payments check + fuzzing) that do not
     depend on any hand-written number.
"""
from __future__ import annotations

import json
import random
from pathlib import Path

import pytest

from splittab_ref import (SplitError, compute, compute_balances, optimal_groups, plain_greedy_count,
                          settle_plan)

CASES_DIR = Path(__file__).resolve().parent.parent / "cases"
CASES = [json.loads(p.read_text()) for p in sorted(CASES_DIR.glob("*.json"))]
OK_CASES = [c for c in CASES if "error" not in c["expected"]]


def key(plan):
    return sorted((p["from"], p["to"], p["amount"]) for p in plan)


# --------------------------------------------------------------------------- hand-written expectations

def test_there_are_enough_cases():
    assert len(CASES) >= 45
    assert len({c["id"] for c in CASES}) == len(CASES)


@pytest.mark.parametrize("case", CASES, ids=lambda c: c["id"])
def test_case_matches_expected(case):
    exp, got = case["expected"], compute(case)
    if "error" in exp:
        assert got == {"error": exp["error"]}
        return
    assert "error" not in got, got
    assert got["balances"] == exp["balances"]
    assert got["settle"]["min_payments"] == exp["settle"]["min_payments"]
    if "plan" in exp["settle"]:
        assert key(got["settle"]["plan"]) == key(exp["settle"]["plan"])
    if "direct" in exp:
        assert [tuple(sorted(d.items())) for d in got["direct"]] == [tuple(sorted(d.items())) for d in exp["direct"]]
    if "expense_home_totals" in exp:
        for k, v in exp["expense_home_totals"].items():
            assert got["expense_home_totals"][k] == v, k
    if "expense_owed" in exp:
        for k, v in exp["expense_owed"].items():
            assert got["expense_owed"][k] == v, k


# --------------------------------------------------------------------------- invariants on every valid case

def apply_plan(balances, plan):
    b = dict(balances)
    for p in plan:
        b[p["from"]] += p["amount"]
        b[p["to"]] -= p["amount"]
    return b


@pytest.mark.parametrize("case", OK_CASES, ids=lambda c: c["id"])
def test_invariants(case):
    got = compute(case)
    bal = got["balances"]
    assert sum(bal.values()) == 0, "balances must sum to zero"
    for e in case["expenses"]:
        owed = got["expense_owed"][e["id"]]
        assert sum(owed.values()) == got["expense_home_totals"][e["id"]], "owed shares must add up to the total"
    plan = got["settle"]["plan"]
    assert all(v == 0 for v in apply_plan(bal, plan).values()), "plan must clear every balance"
    assert all(p["amount"] > 0 and p["from"] != p["to"] for p in plan)
    # the 'direct' view is just an explanation of the same balances
    direct_applied = {m: 0 for m in bal}
    for d in got["direct"]:
        direct_applied[d["from"]] += d["amount"]
        direct_applied[d["to"]] -= d["amount"]
    # a debtor appears as 'from' (+amount), so the totals equal the negated balances
    assert direct_applied == {m: -v for m, v in bal.items()}, "direct view must reconcile with balances"


# --------------------------------------------------------------------------- brute-force optimality

def set_partitions(items):
    if not items:
        yield []
        return
    first, rest = items[0], items[1:]
    for part in set_partitions(rest):
        yield [[first]] + part
        for i in range(len(part)):
            yield part[:i] + [[first] + part[i]] + part[i + 1:]


def brute_force_groups(balances):
    """Max number of zero-sum groups, found by trying EVERY partition (slow, obviously correct)."""
    nz = [m for m, v in balances.items() if v != 0]
    best, count = 0, 0
    for part in set_partitions(nz):
        if all(sum(balances[m] for m in g) == 0 for g in part):
            if len(part) > best:
                best, count = len(part), 1
            elif len(part) == best:
                count += 1
    return len(nz), best, count


@pytest.mark.parametrize("case", OK_CASES, ids=lambda c: c["id"])
def test_min_payments_matches_brute_force(case):
    bal = compute(case)["balances"]
    n_nonzero, groups, unique_count = brute_force_groups(bal)
    expected_payments = n_nonzero - groups if n_nonzero else 0
    assert settle_plan(bal, case["trip"]["members"])["min_payments"] == expected_payments
    # a fixture may only pin an exact plan when the optimal grouping is unique
    if "plan" in case["expected"]["settle"] and n_nonzero:
        assert unique_count == 1, "plan is asserted but several optimal groupings exist"


def test_naive_greedy_really_is_worse_in_the_optimality_case():
    case = next(c for c in CASES if "naive-greedy" in c["id"])
    bal = compute(case)["balances"]
    assert plain_greedy_count(bal, case["trip"]["members"]) == 4
    assert settle_plan(bal, case["trip"]["members"])["min_payments"] == 3


# --------------------------------------------------------------------------- fuzzing

def random_case(rng):
    members = ["m%d" % i for i in range(rng.randint(2, 6))]
    exps = {"USD": 2, "EUR": 2, "JPY": 0, "KWD": 3}
    expenses = []
    for i in range(rng.randint(1, 8)):
        amount = rng.randint(0, 200000) * rng.choice([1, 1, -1])
        payers = rng.sample(members, rng.randint(1, min(3, len(members))))
        cuts = sorted(rng.randint(0, abs(amount)) for _ in range(len(payers) - 1))
        parts = [b - a for a, b in zip([0] + cuts, cuts + [abs(amount)])]
        paid_by = {m: p * (1 if amount >= 0 else -1) for m, p in zip(payers, parts)}
        among = rng.sample(members, rng.randint(1, len(members)))
        kind = rng.choice(["equal", "shares", "percent"])
        if kind == "equal":
            split = {"type": "equal", "among": among}
        elif kind == "shares":
            split = {"type": "shares", "shares": {m: str(rng.randint(1, 5)) for m in among}}
        else:
            raw = [rng.randint(1, 9) for _ in among]
            pcts = [f"{100 * r / sum(raw):.0f}" for r in raw]
            pcts[-1] = str(100 - sum(int(p) for p in pcts[:-1]))
            if int(pcts[-1]) < 0:
                pcts = ["100"] + ["0"] * (len(among) - 1)
            split = {"type": "percent", "percents": dict(zip(among, pcts))}
        e = {"id": f"e{i}", "amount": amount, "paid_by": paid_by, "split": split}
        if rng.random() < 0.4:
            e["currency"] = rng.choice(["EUR", "JPY", "KWD"])
            e["rate"] = f"{rng.uniform(0.001, 200):.6f}"
        expenses.append(e)
    return {"trip": {"home_currency": "USD", "members": members}, "currency_exponents": exps, "expenses": expenses}


@pytest.mark.parametrize("seed", range(150))
def test_fuzz_invariants_and_order_independence(seed):
    rng = random.Random(seed)
    case = random_case(rng)
    got = compute(case)
    assert "error" not in got, got
    bal = got["balances"]
    assert sum(bal.values()) == 0
    for e in case["expenses"]:
        assert sum(got["expense_owed"][e["id"]].values()) == got["expense_home_totals"][e["id"]]
    plan = got["settle"]["plan"]
    assert all(v == 0 for v in apply_plan(bal, plan).values())
    n_nonzero, groups, _ = brute_force_groups(bal) if sum(v != 0 for v in bal.values()) <= 7 else (None, None, None)
    if n_nonzero is not None:
        assert len(plan) == (n_nonzero - groups if n_nonzero else 0)
    # expense order must not matter
    shuffled = dict(case, expenses=rng.sample(case["expenses"], len(case["expenses"])))
    assert compute_balances(shuffled)[0] == bal


def test_largest_group_still_exact():
    """A 12-person trip: the bitmask search stays fast and the plan clears everything."""
    rng = random.Random(7)
    members = [f"p{i}" for i in range(12)]
    vals = [rng.randint(-5000, 5000) for _ in range(11)]
    vals.append(-sum(vals))
    bal = dict(zip(members, vals))
    plan = settle_plan(bal, members)["plan"]
    assert all(v == 0 for v in apply_plan(bal, plan).values())
    assert len(plan) <= sum(v != 0 for v in vals) - 1
