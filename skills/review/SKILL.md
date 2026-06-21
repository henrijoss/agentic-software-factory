---
name: review
description: Adversarial gate on a verified slice — surfaces correctness issues, checks the code still matches its spec/plan (anti-staleness), measures it against the constitution's quality bars, and gives every finding a disposition before ship. The post-hoc verdict that complements the in-flight `doubt` posture. Use when an implemented slice has passed `verify`/`test` and is a candidate to deploy. Not for deciding the approach (`design`) or the first confirmation that it works (`verify`/`test`).
---

# Review

## Overview

`review` is the last gate before ship: an adversarial pass over an **implemented, verified** slice
that produces **findings** and a **disposition** for each (fix / accept-as-trade-off / noise). It
answers three questions at once — is it *correct*, does it still match *what we said we'd build*, and
does it meet our *standing quality bars*.

It is the post-hoc counterpart to `doubt` (the in-flight posture). Rather than reimplementing
adversarial review, `review` **invokes `doubt`** for the deep correctness pass and may call
`verify`/`test` to confirm behavior — staying lean by delegating.

## When to Use

- An implemented slice has passed `verify`/`test` and is a candidate for `deploy`.
- Called as the gate after implementation; can also be invoked standalone on existing code.

**When NOT to use:**

- Deciding the approach — that's `design`.
- The first confirmation that it works — that's `verify`/`test` (review assumes those passed).
- Mechanical changes with no correctness, consistency, or quality surface.

## Inputs / Outputs (abstract)

- **Input:** the implemented + verified slice (code/diff, its **Tasks**, the **SessionSummary** for
  what changed), plus the **Spec/Requirement**, the **Plan**, and the **Constitution** to review
  against — all provided by the caller. If the caller provides a **doubt-pass count**, run that many
  `doubt` passes on the correctness pass; otherwise use your own judgment.
- **Output:** findings + a disposition each, emitted per the result contract. No new artifact and no
  SDLC storage — the driver records the gate state. Each finding carries a routing hint (rework → back
  to `implement`; a stale upstream artifact → back to `specify`/`design`); the driver routes.

## Process

### 1. Read what to review against

Read the **Constitution** (standing bars), the Spec/Requirement (the *right thing?*), the Plan (the
*planned way?*), the Tasks' acceptance criteria, and the SessionSummary (what changed). Without the
intended contract, a review is just opinion.

### 2. Correctness — invoke `doubt`

Run the **`doubt`** posture on the slice: adversarial, fresh-context, find-issues. This is the deep
correctness pass; don't duplicate its mechanics here. Re-run or extend `verify`/`test` if a finding
needs behavioral confirmation.

### 3. Consistency / anti-staleness pass

Check the code against the Spec, Requirement, and Plan: did the implementation **diverge** from what
those artifacts say? Two outcomes: the code is wrong → finding; or the artifact is now stale because
the implementation legitimately learned something → a finding hinting an **in-place update** to
`specify`/`design` (never let spec and code silently diverge — the field's top failure mode). This is
the content-level consistency check; the structural gate-validation over the tree (dangling /
duplicate / orphan / unreachable IDs) is the driver's job at ingest, not review's.

### 4. Quality — against the constitution's bars

Measure against the **Constitution**'s principles, simplicity defaults, and boundaries. Separate **blockers**
(must fix before ship) from **improvements** (worth doing, not gating). Don't invent bars the
constitution doesn't set.

### 5. Disposition every finding

Classify each (mirrors `doubt`'s reconcile): **fix** (real + actionable → re-enter `implement`),
**accept-as-trade-off** (real but cost of fixing exceeds the benefit → document so the user sees it),
or **noise** (correct under context the review lacked → note and drop). Re-read the code against each
finding before classifying — rubber-stamping is the same failure as ignoring.

### 6. Gate

Present findings and dispositions and force the decision: *"Are findings resolved or consciously
accepted as trade-offs?"* This gate earns its interruption — it's the last point before ship. Surface
it for the caller — standalone, present it to the user; under a driver, the driver holds the gate.

## Composability (big↔small)

A one-off fix may be a single `doubt` cycle + a consistency glance. A substantial slice runs all four
passes and a documented trade-off list. Don't run a full review apparatus on a typo — but never skip
the anti-staleness check when an artifact tree exists.

## Red Flags

- Reimplementing adversarial review instead of invoking `doubt`.
- Reviewing without the spec/plan in hand (opinion, not review).
- Skipping the consistency pass — letting code and spec silently diverge.
- Inventing quality bars the constitution doesn't set; or mixing blockers and improvements so the
  gate can't tell what must change.
- Findings with no disposition (a list nobody acts on).
- Rubber-stamping or reflexively deferring to a finding without re-reading the code.
- Forgetting that a legitimate divergence means an artifact update (`specify`/`design`), not just a
  code change.
- Running the structural tree gate-validation or persisting findings — that's the driver, not review.

## Verification

- [ ] Reviewed against the **Constitution**, the Spec/Requirement, and the Plan — not from memory.
- [ ] `doubt` invoked for the correctness pass (not reimplemented).
- [ ] Content-level consistency/anti-staleness pass run; divergences flagged as code-fix *or* in-place
      artifact-update findings (structural gate-validation left to the driver).
- [ ] Quality measured against the constitution's bars; blockers separated from improvements.
- [ ] Every finding given a disposition (fix / accept-as-trade-off / noise), re-read before classing.
- [ ] Findings emitted per the result contract with routing hints; not persisted by the skill.
- [ ] The gate decision was posed (caller/driver holds it).
