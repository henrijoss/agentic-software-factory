---
name: clarify
description: Sharpens one Requirement — resolves its open questions and turns vague acceptance signals into sharp, testable, unambiguous criteria, so `design` can plan against it without guessing. The human deep-dive on a single requirement; its engine is the `interview` posture. `requirement.md` is a living spec: re-enter to re-clarify any time — including mid/post-implementation when code teaches something new — updated in place, never closed. Use when a requirement chosen for the next slice is still ambiguous. Distinct from `to-requirements` (which fans the spec into many drafts) and `design` (the how).
---

# Clarify

## Overview

`clarify` **sharpens** one Requirement: every open question resolved (or explicitly deferred), and
vague acceptance signals sharpened into unambiguous, testable criteria. It is the deep-dive that ensures
the next phase isn't designing against a moving target.

`requirement.md` is a **living spec** — there is no one-way "draft → ready" transition that closes it.
A requirement can be re-clarified **at any point**: before design, but also **mid- or
post-implementation**, when working code teaches something the requirement got wrong. Every re-entry
updates `requirement.md` **in place** (the driver overwrites it, never forks a copy); the requirement
is never "already ready, cannot re-open".

Its **engine is the `interview` posture** — one question at a time, with a guess attached, until the
intent is pinned. `clarify` doesn't reimplement that; it *invokes* `interview` and adds the
requirement-specific framing (what "ready" means, sharpening acceptance, the in-place update and
gate). Note the symmetry: `specify` calls `interview` for the whole Spec; `clarify` calls it for one
Requirement.

## When to Use

- A Requirement chosen for the next slice still carries open questions or vague acceptance.
- Before `design`, when the approach can't be chosen because the *what* is still fuzzy.
- Re-entering to re-clarify **at any point** — including mid- or post-implementation — when intent
  shifts or working code reveals the requirement was wrong.

**When NOT to use:**

- Fanning the Spec into requirements — that's `to-requirements`.
- Deciding the approach/architecture — that's `design`.
- A requirement that is already unambiguous and testable (go straight to `design`).

## Inputs / Outputs (abstract)

- **Input:** one **Requirement** (at any maturity — fresh draft or one revisited post-implementation),
  its **Stakeholders**, and the **Constitution** — all provided by the caller.
- **Output:** the same **Requirement**, sharpened — sharp acceptance criteria, open questions resolved
  or explicitly deferred — emitted per the result contract for the caller to ingest, who updates
  `requirement.md` in place. The skill writes no files and resolves no storage.

## Process

### 1. Read the requirement and its context

Read the **Requirement** (the use-case, current acceptance, open questions), its **Stakeholders**, and the
**Constitution**. Clarify *this one* requirement — don't re-open the fan-out (that's `to-requirements`).

### 2. Resolve the unknowns via `interview`

Run the **`interview`** posture on the requirement's open questions and ambiguities: one focused
question at a time, each with your best guess, until you can predict the user's answers. Watch for
"want vs. should-want" on acceptance ("make it fast" → a number). Don't reimplement interview's
mechanics — invoke them.

### 3. Sharpen acceptance into testable criteria

Turn each rough acceptance signal into a criterion `verify`/`test` could check objectively: concrete
conditions, edge/negative cases the use-case implies, and an explicit out-of-scope line. Vague
acceptance is the main thing `clarify` exists to kill.

### 4. Resolve or explicitly defer open questions

Every open question ends as **answered** or **deferred with a reason** (and, if deferred, a note on
whether it blocks design). None left dangling — a dangling question becomes a silent assumption in
`design`.

### 5. Emit the ready Requirement

Emit the ready Requirement per the result contract — the use-case stays; acceptance becomes ready; the
open-questions section shrinks to resolved/deferred. Write no files; persistence and the in-place
overwrite of the existing requirement are the driver's job.

### 6. Loop by default, then hand off

`clarify` **loops by default**: each pass emits the updated requirement (the driver writes it **in place**
before the hand-off), so the operator can keep deepening it rather than being forced forward. For the
hand-off, surface **critical open topics** still needing discussion before the requirement is sound; if
none are critical, offer **related topics + concrete examples** worth exploring. The bar to progress:
could `design` proceed without guessing, and could `verify`/`test` check acceptance objectively?

Surface this for the caller — standalone, present it to the user; under a driver, the driver writes the
requirement in place and presents the *Progress to next phase · Continue with a topic · Stop here* choice
(`references/presentation.md`). Under `auto`, the questions are skipped and the suggested next step is
auto-taken.

## Ready Requirement shape

Short form below; the readiness checklist, sharpening technique, and a worked example live in
`references/clarify-guide.md`.

```markdown
# [use-case title]

**As a** [stakeholder] **I want** [capability] **so that** [value].
**Acceptance:**
- [ ] [sharp, testable criterion]
**Out of scope:** [explicit non-goals]
**Resolved / deferred:** [former open questions + their answer or deferral reason]
**Stakeholders:** [stakeholder, …]
```

## Composability (big↔small)

A nearly-clear requirement may need one interview question and a tightened criterion. A fuzzy one
needs several rounds. If clarifying keeps re-opening scope, the issue is upstream — kick back to
`to-requirements`/`specify` rather than grinding here.

## Red Flags

- Reimplementing `interview` instead of invoking it.
- Re-fanning the spec / inventing new requirements — that's `to-requirements`.
- Designing (choosing an approach) inside clarify — that's `design`.
- Leaving acceptance vague enough that `verify`/`test` can't check it.
- Dangling open questions that silently become assumptions downstream.
- No out-of-scope line on the ready requirement.
- Writing files / resolving storage instead of just emitting the result (that's the driver's job).

## Verification

- [ ] Worked one requirement; fan-out not re-opened.
- [ ] Open questions resolved via `interview` (invoked, not reimplemented).
- [ ] Acceptance sharpened into testable criteria with edge cases and an out-of-scope line.
- [ ] Every open question ended answered or explicitly deferred (none dangling).
- [ ] Emitted per the result contract; no files written / no storage resolved by the skill.
- [ ] Readiness bar met: `design` could proceed without guessing; `verify` could check acceptance.
- [ ] The gate decision was posed (caller/driver holds it).
