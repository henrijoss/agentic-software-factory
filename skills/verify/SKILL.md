---
name: verify
description: Behavioral verification — run the actual thing and observe whether it does what the task claims. Use for UI/visual, integration across services, and "does the app actually do X" checks, where the behavior is cheaper to confirm by observation than to encode up front. The run-and-observe counterpart to `test` (test-first). Not for pure logic contracts or bug-repro — that's `test`.
---

# Verify

## Overview

`verify` confirms behavior by **running the real thing and observing it** — launching the app,
exercising the path, looking at the result against the task's acceptance criteria. It is the
discipline that catches "it compiles and the unit tests pass, but it doesn't actually work."

It is one of two verification skills — the run-and-observe one; `test` is the test-first one.
**Which applies when:** `verify` for UI/visual/integration/"does it actually do X"; `test` for known
input/output contracts and bug fixes; **both** for high-stakes cross-boundary work (behavioral via
`verify` + unit contract via `test`).

## When to Use

- UI / visual / layout — run it and look.
- Integration across services or components; end-to-end "does the app actually do X".
- Behavior that's awkward or expensive to encode in a unit test but obvious on observation.
- As a per-task completion gate inside `implement`, or called from `review`.

**When NOT to use:**

- A clear input/output contract or a bug fix — that's `test` (test-first).
- Mechanical changes with no observable behavior.

## Inputs / Outputs (abstract)

- **Input:** a change/slice plus its **Task** acceptance criteria, and the **Constitution** for how to
  build, launch, and exercise the app (resolve there — never hardcode) — all provided by the caller.
- **Output:** **observed evidence** that behavior meets (or fails) the acceptance criteria, and a
  pass/fail result, emitted per the result contract. No dedicated artifact and no storage — the driver
  records the gate state.

## Process

### 1. State what "working" looks like

Before running anything, write the observable pass condition from the task's acceptance criteria:
*what will I see if this works?* A vague target ("looks right") can't be verified — make it concrete
(the saved search appears in the list; the digest email arrives with the new item).

### 2. Run the real thing

Build and launch per the **Constitution** and exercise the actual path a user/caller would. Verify against the
real artifact, not a description of it or a mock that assumes the answer.

### 3. Observe against the pass condition

Compare what you observe to Step 1's condition — including the negative/edge cases the task implies
(empty state, error path, the thing that should *not* happen). Capture the evidence (output, a
screenshot, the observed sequence) so the gate decision rests on fact, not assertion.

### 4. On failure, report — don't paper over

If behavior doesn't match, report it faithfully with the evidence and hand back to `implement`. Never
relax the pass condition to make it pass, and never claim "verified" on a step you skipped.

### 5. Gate

When behavior is confirmed, force the decision: *"Is behavior confirmed and ready for adversarial
review?"* Surface it for the caller — standalone, present it to the user; under a driver, the driver
holds the gate.

## Composability (big↔small)

A small UI tweak is one launch-and-look. An integration slice exercises the full path end to end. A
high-stakes change pairs `verify` (behavioral) with `test` (unit contract).
Don't spin up a full e2e harness for a one-screen visual check.

## Red Flags

- Claiming "verified" without running the actual thing (assuming, not observing).
- A pass condition vague enough that anything satisfies it ("looks fine").
- Verifying against a mock/description that bakes in the expected answer.
- Skipping the negative/edge case the task implies.
- Relaxing the pass condition to turn a fail into a pass.
- Reaching for `verify` on a pure logic contract — use `test`.
- Hardcoding build/launch commands instead of resolving from the **Constitution**.

## Verification

- [ ] An observable pass condition was stated from the acceptance criteria before running.
- [ ] The real thing was built/launched (per the **Constitution**) and the actual path exercised.
- [ ] Observation compared to the pass condition, including the implied negative/edge cases.
- [ ] Evidence captured so the gate rests on fact.
- [ ] Failures reported faithfully and handed back — no relaxed conditions, no skipped-but-claimed steps.
- [ ] The gate decision was posed (caller/driver holds it).
