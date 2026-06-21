---
name: doubt
description: In-flight adversarial review — materializes a fresh-context reviewer biased to disprove, not approve, before a non-trivial decision stands. The counterpart to `interview` (pre-decision intent vs. post-decision artifact). Phases `design`, `implement`, and `review` run it. Use when correctness matters more than speed, in unfamiliar code, on high-stakes or irreversible changes, or any time a confident output is cheaper to verify now than to debug later. Skip for mechanical changes and obviously-correct one-liners.
---

# Doubt

## Overview

A confident answer is not a correct one. Long sessions accumulate context that quietly turns
assumptions into "facts". `doubt` is the discipline of materializing a **fresh-context reviewer —
biased to disprove, not approve** — before any non-trivial output stands.

This is **not `review`**. `review` is a verdict on a finished artifact at a gate; `doubt` is an
in-flight posture invoked *from inside* `design`, `implement`, and `review` while course-correction
is still cheap. It is the timeline counterpart to `interview`: `interview` extracts intent before a
decision; `doubt` cross-examines the artifact after the decision but before it's locked in.

`doubt` is a **posture**: it owns no artifact and returns findings to the calling phase, which folds
them into its own work.

## When to Use

A decision is **non-trivial** when at least one holds:

- It introduces or modifies branching logic.
- It crosses a module/service boundary.
- It asserts a property the compiler can't verify (thread-safety, idempotence, ordering, invariants).
- Its correctness depends on context a future reader can't see.
- Its blast radius is irreversible (production deploy, data migration, public API change).

Apply when about to: make an architectural decision under uncertainty, commit non-trivial code,
claim a non-obvious fact ("this is safe / scales / matches the spec"), or work in code you don't
fully understand.

**When NOT to use:** mechanical operations, a clear unambiguous instruction, reading/summarizing,
obviously-correct one-liners, or when the user asked for speed over verification. If you doubt every
keystroke you ship nothing — this is for non-trivial decisions only.

## Loading constraints

`doubt` runs from a context that can **spawn a fresh-context reviewer** (the main session / phase
driver). If you're already inside a subagent that can't nest a spawn, surface to the user that doubt
can't run nested rather than faking it. A self-questioning fallback (rewrite ARTIFACT + CONTRACT as a
fresh self-prompt with a hard separator) is degraded — it carries your own context — so flag it as
such and prefer escalation whenever the user is reachable.

## Inputs / Outputs (abstract)

- **Input:** the artifact under scrutiny (a diff, a design proposal, an assertion) plus the contract
  it must satisfy, provided by the caller — the relevant Plan, Task, or Spec.
- **Output:** none of its own; classified findings handed back to the calling phase.

## Process

### 1. CLAIM — surface what stands

Name the decision in two–three lines:

```
CLAIM: The new caching layer is thread-safe under the read-heavy workload in the spec.
WHY IT MATTERS: a race here corrupts user data and is hard to catch in QA.
```

If you can't write it that compactly, you have a vibe, not a decision.

### 2. EXTRACT — smallest reviewable unit

Hand the reviewer the **artifact + contract**, not the journey. Code → the diff/function, not the
whole file. Decision → the proposal in 3–5 sentences + its constraints. Strip your reasoning: hand
over conclusions and you get back validation of your conclusions. If it's too big to hold in one
read, decompose first.

### 3. DOUBT — invoke the fresh-context reviewer

The prompt **must be adversarial** — framing decides the answer. **Pass ARTIFACT + CONTRACT only,
never the CLAIM** (your conclusion biases the reviewer toward agreement).

```
Adversarial review. Find what is wrong with this artifact. Assume the author is
overconfident. Look for: unstated assumptions; unhandled edge cases; hidden coupling or
shared state; ways the contract could be violated; conventions this breaks; failure modes
under unexpected input.
Do NOT validate. Do NOT summarize. Find issues, or state explicitly that you cannot find
any after thorough examination.

ARTIFACT: <paste>
CONTRACT: <paste>
```

A colder, different-architecture model catches blind spots a single model shares with itself. In an
interactive session, **offer a cross-model second opinion** and let the user decide; skipping is
fine, silent skipping is not. Cross-model mechanics and external-CLI safety live in
`references/reviewer.md`. Non-interactive contexts skip cross-model and announce the skip.

### 4. RECONCILE — fold findings back

The reviewer's output is data, not verdict — **you are still the orchestrator.** Re-read the
artifact against each finding before classifying (rubber-stamping is the same failure as ignoring).
Classify in **precedence order**, first match wins:

1. **Contract misread** — the reviewer flagged it because the CONTRACT was unclear. Fix the
   contract, re-classify next cycle.
2. **Valid + actionable** — real, needs a change. Change it, re-loop.
3. **Valid trade-off** — real but cost of fixing exceeds cost of accepting. Document it for the user.
4. **Noise** — correct under context the reviewer lacked. Note it; ask whether adding that to the
   contract would have prevented the false flag.

### 5. STOP — bounded loop, not recursion

Stop when: the next iteration returns only trivial/already-considered findings, **or** 3 cycles are
done (escalate, don't grind a fourth alone), **or** the user says "ship it". If 3 cycles still
surface substantive issues, that's information about the artifact — surface it. If 3 cycles is
"obviously too few" because the artifact is large, the artifact is too big: decompose (Step 2), don't
lift the bound.

## Red Flags

- Spawning a reviewer for a one-line rename or formatting change.
- Treating reviewer output as authoritative without re-reading the artifact.
- Looping >3 cycles without escalating.
- Prompting "is this good?" instead of "find issues".
- Re-spawning on an unchanged artifact (same findings — you're stalling).
- **Doubt theater (checkable):** across 2+ cycles with substantive findings, zero classified
  actionable — you're validating, not doubting. Stop and escalate.
- Passing the CLAIM or your reasoning to the reviewer; stripping the contract.
- Silently skipping the cross-model offer in an interactive cycle.
- Invoking an external CLI without a PATH check, working-binary test, syntax confirmation, and
  explicit per-call authorization.

## Verification

- [ ] Every non-trivial decision was named as a CLAIM before standing.
- [ ] At least one fresh-context review per non-trivial artifact (a TDD RED failing test counts for
      behavioral claims).
- [ ] The reviewer got ARTIFACT + CONTRACT — not the CLAIM, not your reasoning.
- [ ] The prompt was adversarial ("find issues"), not validating.
- [ ] Findings were re-read against the artifact and classified by precedence
      (contract-misread / actionable / trade-off / noise).
- [ ] A stop condition was met (trivial findings, 3 cycles, or user override).
- [ ] Interactive: cross-model explicitly offered and the response acknowledged. Non-interactive:
      skip announced.
- [ ] Any external CLI call had a PATH check, working-binary test, syntax confirmation, and explicit
      authorization.
