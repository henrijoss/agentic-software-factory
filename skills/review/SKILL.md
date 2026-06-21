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

- **Input:** the implemented + verified slice (code/diff, its **Tasks**, the **SessionSummary**
  `[REQ-n.SESSION]` for what changed), plus the **Spec/Requirement**, the **Plan** `[REQ-n.DESIGN]`,
  and the **Constitution** `[CONST]` to review against.
- **Output:** findings + a disposition each. No new tree artifact — record findings/disposition as
  gate state in `index.md` and the SessionSummary (as `test`/`verify` record results). Findings that
  warrant rework re-enter `implement`; a stale upstream artifact re-enters `specify`/`design`.

## Process

### 1. Read what to review against

Read `[CONST]` (standing bars), the Spec/Requirement (the *right thing?*), the Plan (the *planned
way?*), the Tasks' acceptance criteria, and the SessionSummary (what changed). Without the intended
contract, a review is just opinion.

### 2. Correctness — invoke `doubt`

Run the **`doubt`** posture on the slice: adversarial, fresh-context, find-issues. This is the deep
correctness pass; don't duplicate its mechanics here. Re-run or extend `verify`/`test` if a finding
needs behavioral confirmation.

### 3. Consistency / anti-staleness pass

Check the code against the Spec, Requirement, and Plan: did the implementation **diverge** from what
those artifacts say? Two outcomes: the code is wrong → finding; or the artifact is now stale because
the implementation legitimately learned something → route it back to `specify`/`design` for an
**in-place update** (never let spec and code silently diverge — the field's top failure mode). Run
the artifact **gate-validation** (no dangling / duplicate / orphan / unreachable IDs) per
the `continue` base skill.

### 4. Quality — against the constitution's bars

Measure against `[CONST]`'s principles, simplicity defaults, and boundaries. Separate **blockers**
(must fix before ship) from **improvements** (worth doing, not gating). Don't invent bars the
constitution doesn't set.

### 5. Disposition every finding

Classify each (mirrors `doubt`'s reconcile): **fix** (real + actionable → re-enter `implement`),
**accept-as-trade-off** (real but cost of fixing exceeds the benefit → document so the user sees it),
or **noise** (correct under context the review lacked → note and drop). Re-read the code against each
finding before classifying — rubber-stamping is the same failure as ignoring.

### 6. Gate → deploy

Present findings and dispositions and force the decision: *"Are findings resolved or consciously
accepted as trade-offs?"* This gate earns its interruption — it's the last point before ship. On
explicit approval, hand off to `deploy`.

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

## Verification

- [ ] Reviewed against `[CONST]`, the Spec/Requirement, and the Plan — not from memory.
- [ ] `doubt` invoked for the correctness pass (not reimplemented).
- [ ] Consistency/anti-staleness pass run; gate-validation clean; divergences routed to code-fix
      *or* in-place artifact update.
- [ ] Quality measured against the constitution's bars; blockers separated from improvements.
- [ ] Every finding given a disposition (fix / accept-as-trade-off / noise), re-read before classing.
- [ ] Fix-findings re-entered `implement`; accepted trade-offs documented for the user.
- [ ] The gate decision was posed and explicit approval received before handing to `deploy`.
