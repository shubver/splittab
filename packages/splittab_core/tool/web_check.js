// Runs every shared fixture and the 400 random cases through splittab_core COMPILED TO JAVASCRIPT.
// In JS, integers are doubles (exact only up to 2^53) - the same as Flutter web.
//
//   dart compile js -o build/core.js tool/web_entry.dart && node tool/web_check.js
const fs = require('fs');
const path = require('path');
const assert = require('assert');

require(path.join(__dirname, '..', 'build', 'core.js'));
const run = (c) => JSON.parse(globalThis.computeCaseJson(JSON.stringify(c)));

const root = path.join(__dirname, '..', '..', '..', 'fixtures');
const sortT = (ts) => [...ts].sort((a, b) => (a.from + a.to + a.amount).localeCompare(b.from + b.to + b.amount));
let checked = 0;

// 1. hand-written fixtures
for (const f of fs.readdirSync(path.join(root, 'cases')).filter((f) => f.endsWith('.json')).sort()) {
  const c = JSON.parse(fs.readFileSync(path.join(root, 'cases', f)));
  const exp = c.expected, got = run(c);
  if (exp.error) { assert.deepStrictEqual(got, { error: exp.error }, c.id); checked++; continue; }
  assert.strictEqual(got.error, undefined, c.id + ' unexpected error ' + got.error);
  assert.deepStrictEqual(got.balances, exp.balances, c.id + ' balances');
  assert.strictEqual(got.min_payments, exp.settle.min_payments, c.id + ' min payments');
  if (exp.settle.plan) assert.deepStrictEqual(sortT(got.plan), sortT(exp.settle.plan), c.id + ' plan');
  if (exp.direct) assert.deepStrictEqual(got.direct, exp.direct, c.id + ' direct');
  for (const [k, v] of Object.entries(exp.expense_home_totals || {})) assert.strictEqual(got.expense_home_totals[k], v, c.id + ' total ' + k);
  for (const [k, v] of Object.entries(exp.expense_owed || {})) assert.deepStrictEqual(got.expense_owed[k], v, c.id + ' owed ' + k);
  checked++;
}
const fixtureCount = checked;

// 2. random cases with Python-computed expectations
const fuzz = JSON.parse(fs.readFileSync(path.join(root, 'fuzz', 'random-cases.json')));
for (const c of fuzz) {
  const exp = c.expected, got = run(c);
  if (exp.error) { assert.deepStrictEqual(got, { error: exp.error }, c.id); checked++; continue; }
  assert.deepStrictEqual(got.balances, exp.balances, c.id + ' balances');
  assert.strictEqual(got.min_payments, exp.min_payments, c.id + ' min payments');
  assert.deepStrictEqual(got.direct, exp.direct, c.id + ' direct');
  assert.deepStrictEqual(got.expense_home_totals, exp.expense_home_totals, c.id + ' totals');
  assert.deepStrictEqual(got.expense_owed, exp.expense_owed, c.id + ' owed');
  checked++;
}
console.log(`OK: ${fixtureCount} fixtures + ${fuzz.length} random cases match under JavaScript numbers (${checked} checks)`);
