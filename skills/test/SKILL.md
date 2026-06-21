---
name: test
description: Test-driven development — write the failing test before the code, then make it pass. Use when the contract is known before the implementation: logic with a clear input/output, pure functions, parsers, calculations, state machines, and bug fixes (reproduce with a failing test first). The test-first counterpart to `verify` (run-and-observe). Not for UI/visual or "does the app actually do X" — that's `verify`.
---

# Test (TDD)

## Overview

`test` writes the **failing test first**, then the code that makes it pass: RED → GREEN → REFACTOR.
Writing the test first forces the contract to be explicit before any implementation can rationalize
itself into "good enough", and leaves durable automated coverage behind.

It is one of two verification skills — the test-first one; `verify` is the run-and-observe one.
**Which applies when:** `test` for known input/output contracts (pure functions, parsing,
calculations, state machines) and bug fixes; `verify` for UI/integration/"does it actually do X";
**both** for high-stakes cross-boundary work (unit contract via `test` + behavioral via `verify`).

## When to Use

- Logic with a clear input/output contract (pure functions, parsing, calculations, state machines).
- A bug fix — reproduce it with a failing test *first*, then fix.
- Anything where the contract is known before the code exists.
- As a per-task completion gate inside `implement`, or called from `review`.

**When NOT to use:**

- UI/visual, integration, "does the app actually do X" — that's `verify`.
- Mechanical changes with no behavioral contract.
- Throwaway spikes (write the test once the approach is kept).

## Inputs / Outputs (abstract)

- **Input:** a change/slice plus its **Task** acceptance criteria, and the **Constitution** for the
  test framework and commands (resolve them there — never hardcode) — all provided by the caller.
- **Output:** automated **tests in the source tree** (per the Constitution's conventions — the skill's
  real work) and a pass/fail result, emitted per the result contract. No dedicated artifact and no SDLC
  storage — the driver records the gate state.

## Process

### 1. RED — write a failing test for the contract

Translate the acceptance criteria into a test that asserts the desired behavior, and **watch it
fail**. A test that passes before the code exists asserts nothing. The failing test is the contract
made executable — and for a behavioral claim it *is* the `doubt` step (a disproof attempt).

### 2. GREEN — simplest code that passes

Write the minimum code to make the test pass — no more. Don't build beyond what the test demands;
extra behavior is untested behavior (and a scope-discipline violation per `incremental`).

### 3. REFACTOR — clean up under green

With the test green, improve the code (and test) without changing behavior. Re-run to stay green.
Honor the constitution's simplicity default — refactor toward simplest-that-works, not abstraction.

### 4. Cover the edges that matter

Add cases for the boundaries and failure modes the contract implies (empty/null, limits, error
paths) — not every theoretical input. Each case must earn its place; over-testing is its own cost.

### 5. Gate

Run the suite (commands from the **Constitution**). When the task's tests are green, force the
decision: *"Is the contract confirmed and ready for adversarial review?"* Surface it for the caller —
standalone, present it to the user; under a driver, the driver holds the gate.

## Composability (big↔small)

A single pure function may need one RED/GREEN cycle. A bug fix is one failing reproduction + the fix.
A high-stakes change pairs `test` (unit contract) with `verify` (behavioral).
Don't manufacture a test pyramid for a one-line fix.

## Red Flags

- Writing the test after the code ("characterization" of whatever you happened to build) — that's not
  TDD; the test can't disprove anything it was shaped to fit.
- A test that passed the first time it ran — it never went RED, so it asserts nothing.
- Writing code beyond what a test demands.
- Testing implementation details instead of the contract (brittle to refactor).
- Hardcoding the test command instead of resolving from the **Constitution**.
- Reaching for `test` on UI/visual/integration behavior — use `verify`.

## Verification

- [ ] Each behavior was asserted by a test that was watched **fail** before the code (RED first).
- [ ] Only the minimum code to pass was written (GREEN), then cleaned under green (REFACTOR).
- [ ] Edge/failure cases that the contract implies are covered; no over-testing.
- [ ] Tests assert the contract, not implementation details.
- [ ] Commands resolved from the **Constitution**; suite green.
- [ ] Bug fixes began with a failing reproduction.
- [ ] The gate decision was posed (caller/driver holds it).
