"""Reference implementation of the SplitTab balance rules.

The specification lives in fixtures/README.md. This file exists to (a) check that the
JSON fixtures are internally consistent and (b) serve as an executable spec for the Dart
package `splittab_core`, which must reproduce this behaviour exactly.

Pure Python, exact arithmetic (fractions.Fraction): no floats anywhere.
"""
from __future__ import annotations

from fractions import Fraction
from math import floor
from typing import Any

# Above this many members with a non-zero balance, the exact (bitmask DP) minimum is
# skipped and a greedy plan is used instead. Trip groups are almost always < 20.
MAX_EXACT_SETTLE_MEMBERS = 20


class SplitError(Exception):
    """Invalid input. `code` is one of the error codes listed in fixtures/README.md."""

    def __init__(self, code: str, detail: str = "") -> None:
        super().__init__(f"{code}: {detail}" if detail else code)
        self.code = code


# --------------------------------------------------------------------------- money maths

def round_half_away(x: Fraction) -> int:
    """Round to the nearest integer; exact ties go away from zero."""
    n = floor(abs(x) + Fraction(1, 2))
    return -n if x < 0 else n


def to_home_minor(amount: int, currency: str, rate: str | None, home: str,
                  exponents: dict[str, int]) -> int:
    """Convert `amount` (minor units of `currency`) to minor units of the home currency.

    rate = home-currency MAJOR units per 1 MAJOR unit of `currency` (decimal string).
    """
    if currency == home:
        return amount
    if rate is None:
        raise SplitError("missing_rate", currency)
    r = Fraction(rate)
    if r <= 0:
        raise SplitError("invalid_rate", rate)
    factor = Fraction(10) ** (exponents[home] - exponents[currency])
    return round_half_away(Fraction(amount) * r * factor)


def allocate(total: int, weights: list[Fraction], tie_index: list[int]) -> list[int]:
    """Largest-remainder allocation of an integer `total` by `weights` (sum to 1).

    Every share is floor(|total| * w); the leftover minor units go one each to the
    largest fractional remainders. Ties go to the lowest `tie_index`. The sign of
    `total` is applied at the end, so refunds mirror the original expense exactly.
    """
    sign = -1 if total < 0 else 1
    t = abs(total)
    exact = [t * w for w in weights]
    base = [floor(x) for x in exact]
    left = t - sum(base)
    order = sorted(range(len(weights)), key=lambda i: (-(exact[i] - base[i]), tie_index[i]))
    for i in order[:left]:
        base[i] += 1
    return [sign * b for b in base]


# --------------------------------------------------------------------------- one expense

def _split_weights(split: dict[str, Any], amount: int, members: set[str]) -> dict[str, Fraction]:
    kind = split.get("type")
    w: dict[str, Fraction] = {}
    if kind == "equal":
        among = split["among"]
        if not among:
            raise SplitError("empty_split")
        _known(among, members)
        for m in among:
            w[m] = w.get(m, Fraction(0)) + Fraction(1, len(among))
    elif kind == "exact":
        amounts = split["amounts"]
        _known(amounts, members)
        if sum(amounts.values()) != amount:
            raise SplitError("split_sum_mismatch")
        for m, a in amounts.items():
            w[m] = Fraction(a, amount)
    elif kind == "percent":
        pcts = {m: Fraction(p) for m, p in split["percents"].items()}
        _known(pcts, members)
        if any(p < 0 for p in pcts.values()) or sum(pcts.values()) != 100:
            raise SplitError("percent_sum_invalid")
        for m, p in pcts.items():
            w[m] = p / 100
    elif kind == "shares":
        shares = {m: Fraction(s) for m, s in split["shares"].items()}
        _known(shares, members)
        total = sum(shares.values())
        if any(s < 0 for s in shares.values()) or total == 0:
            raise SplitError("invalid_shares")
        for m, s in shares.items():
            w[m] = s / total
    elif kind == "nights":
        n = split["total_nights"]
        stays = split["nights"]
        _known(stays, members)
        if n < 1 or any(not 1 <= night <= n for ns in stays.values() for night in ns):
            raise SplitError("invalid_nights")
        for night in range(1, n + 1):
            present = [m for m, ns in stays.items() if night in ns]
            if not present:
                raise SplitError("night_uncovered", str(night))
            for m in present:
                w[m] = w.get(m, Fraction(0)) + Fraction(1, n) / len(present)
    else:
        raise SplitError("invalid_split_type", str(kind))
    return w


def _known(names, members: set[str]) -> None:
    for m in names:
        if m not in members:
            raise SplitError("unknown_member", m)


def process_expense(case: dict[str, Any], e: dict[str, Any]) -> dict[str, Any]:
    trip = case["trip"]
    order: list[str] = trip["members"]
    members = set(order)
    tie = {m: i for i, m in enumerate(order)}
    home = trip["home_currency"]
    exps = case.get("currency_exponents", {})

    amount = e["amount"]
    currency = e.get("currency", home)
    if currency != home and (currency not in exps or home not in exps):
        raise SplitError("unknown_currency", currency)

    paid_by = e["paid_by"]
    _known(paid_by, members)
    if sum(paid_by.values()) != amount:
        raise SplitError("payer_sum_mismatch")

    total_home = to_home_minor(amount, currency, e.get("rate"), home, exps)
    split_w = _split_weights(e["split"], amount, members)

    paid = {m: 0 for m in order}
    owed = {m: 0 for m in order}
    if amount != 0:
        payers = [m for m in order if m in paid_by]
        for m, v in zip(payers, allocate(total_home, [Fraction(paid_by[m], amount) for m in payers],
                                         [tie[m] for m in payers])):
            paid[m] = v
        owers = [m for m in order if m in split_w]
        for m, v in zip(owers, allocate(total_home, [split_w[m] for m in owers],
                                        [tie[m] for m in owers])):
            owed[m] = v
    net = {m: paid[m] - owed[m] for m in order}
    return {"total_home": total_home, "paid": paid, "owed": owed, "net": net}


# --------------------------------------------------------------------------- balances

def compute_balances(case: dict[str, Any]) -> tuple[dict[str, int], dict[str, dict[str, Any]]]:
    order: list[str] = case["trip"]["members"]
    balances = {m: 0 for m in order}
    per_expense: dict[str, dict[str, Any]] = {}
    for e in case.get("expenses", []):
        r = process_expense(case, e)
        per_expense[e["id"]] = r
        for m in order:
            balances[m] += r["net"][m]
    for p in case.get("payments", []):
        _known([p["from"], p["to"]], set(order))
        balances[p["from"]] += p["amount"]
        balances[p["to"]] -= p["amount"]
    return balances, per_expense


# --------------------------------------------------------------------------- direct view

def expense_transfers(net: dict[str, int], order: list[str]) -> list[tuple[str, str, int]]:
    """Attribute one expense's nets to who-pays-whom: two-pointer match in member order."""
    debtors = [[m, -net[m]] for m in order if net[m] < 0]
    creditors = [[m, net[m]] for m in order if net[m] > 0]
    i = j = 0
    out = []
    while i < len(debtors) and j < len(creditors):
        amt = min(debtors[i][1], creditors[j][1])
        out.append((debtors[i][0], creditors[j][0], amt))
        debtors[i][1] -= amt
        creditors[j][1] -= amt
        if debtors[i][1] == 0:
            i += 1
        if creditors[j][1] == 0:
            j += 1
    return out


def direct_view(case: dict[str, Any], per_expense: dict[str, dict[str, Any]]) -> list[dict[str, Any]]:
    order = case["trip"]["members"]
    idx = {m: i for i, m in enumerate(order)}
    flow: dict[tuple[str, str], int] = {}

    def add(a: str, b: str, amt: int) -> None:
        key = (a, b) if idx[a] < idx[b] else (b, a)
        flow[key] = flow.get(key, 0) + (amt if key == (a, b) else -amt)

    for e in case.get("expenses", []):
        for a, b, amt in expense_transfers(per_expense[e["id"]]["net"], order):
            add(a, b, amt)
    for p in case.get("payments", []):
        # paying someone REDUCES what you owe them, so it counts against the debt direction
        add(p["to"], p["from"], p["amount"])

    out = []
    for (a, b), amt in flow.items():
        if amt > 0:
            out.append({"from": a, "to": b, "amount": amt})
        elif amt < 0:
            out.append({"from": b, "to": a, "amount": -amt})
    out.sort(key=lambda t: (idx[t["from"]], idx[t["to"]]))
    return out


# --------------------------------------------------------------------------- settle-up

def optimal_groups(balances: dict[str, int], order: list[str]) -> list[list[str]]:
    """Partition the non-zero members into the maximum number of zero-sum groups.

    Each group of k members needs k-1 payments, so payments = non_zero_members - groups.
    Classic bitmask DP: dp[mask] = max over last-element choice of dp[rest] + (sum==0).
    """
    nz = [m for m in order if balances[m] != 0]
    n = len(nz)
    if n == 0:
        return []
    if n > MAX_EXACT_SETTLE_MEMBERS:
        return [nz]  # fall back: one group, greedy inside
    vals = [balances[m] for m in nz]
    size = 1 << n
    sums = [0] * size
    for mask in range(1, size):
        low = (mask & -mask).bit_length() - 1
        sums[mask] = sums[mask & (mask - 1)] + vals[low]
    dp = [0] * size
    choice = [0] * size
    for mask in range(1, size):
        best, bi = -1, -1
        rest = mask
        while rest:
            bit = rest & -rest
            v = dp[mask ^ bit]
            if v > best:
                best, bi = v, bit
            rest ^= bit
        dp[mask] = best + (1 if sums[mask] == 0 else 0)
        choice[mask] = bi
    chain, mask = [], size - 1
    while mask:
        chain.append(mask)
        mask ^= choice[mask]
    zero_masks = [m for m in chain if sums[m] == 0] + [0]
    groups = []
    for k in range(len(zero_masks) - 1):
        g = zero_masks[k] & ~zero_masks[k + 1]
        groups.append([nz[i] for i in range(n) if g >> i & 1])
    return groups


def greedy_group_plan(group: list[str], balances: dict[str, int], order: list[str]) -> list[dict[str, Any]]:
    """Inside one group: repeatedly pay the largest remaining debt to the largest remaining credit."""
    idx = {m: i for i, m in enumerate(order)}
    cred = [[m, balances[m]] for m in group if balances[m] > 0]
    debt = [[m, -balances[m]] for m in group if balances[m] < 0]
    plan = []
    while debt and cred:
        d = max(debt, key=lambda x: (x[1], -idx[x[0]]))
        c = max(cred, key=lambda x: (x[1], -idx[x[0]]))
        amt = min(d[1], c[1])
        plan.append({"from": d[0], "to": c[0], "amount": amt})
        d[1] -= amt
        c[1] -= amt
        if d[1] == 0:
            debt.remove(d)
        if c[1] == 0:
            cred.remove(c)
    return plan


def settle_plan(balances: dict[str, int], order: list[str]) -> dict[str, Any]:
    groups = optimal_groups(balances, order)
    plan = [p for g in groups for p in greedy_group_plan(g, balances, order)]
    return {"min_payments": len(plan), "plan": plan}


def plain_greedy_count(balances: dict[str, int], order: list[str]) -> int:
    """Naive baseline (no grouping) used only to show why the exact minimum matters."""
    nz = [m for m in order if balances[m] != 0]
    return len(greedy_group_plan(nz, balances, order))


# --------------------------------------------------------------------------- entry point

def compute(case: dict[str, Any]) -> dict[str, Any]:
    """Full result for a fixture case, or {"error": code}."""
    try:
        balances, per_expense = compute_balances(case)
    except SplitError as err:
        return {"error": err.code}
    order = case["trip"]["members"]
    return {
        "balances": balances,
        "expense_home_totals": {k: v["total_home"] for k, v in per_expense.items()},
        "expense_owed": {k: v["owed"] for k, v in per_expense.items()},
        "settle": settle_plan(balances, order),
        "direct": direct_view(case, per_expense),
    }
