---
name: specify
description: Turns an idea into a Specification — the objective, scope, and testable success criteria for one vertical slice of work, before any design or code. Use at the start of a slice when only a vague idea or feature request exists, when a vague ask ("make it faster", "add search") needs reframing into concrete success criteria, or when re-entering to update the spec as scope shifts. Distinct from the constitution (standing, cross-feature) and from design (the how): the spec is one slice's what and why.
---

# Specify

## Overview

A specification says **what we're building, why, and how we'll know it's done** — for one vertical
slice, before any design or code. It is the shared source of truth between you and the user for that
slice; code without it is guessing.

Keep the spec at the **what/why/success** altitude. The *how* (architecture, approach) is `design`;
the standing rules that hold across every slice (stack, conventions, boundaries) are the
`constitution` — `specify` reads those, never restates them. A spec that describes implementation or
repeats the constitution is mis-scoped.

The unit is a **vertical slice / use-case**, not the whole product (loop principle 2). The first
slice's spec is written from scratch; later slices re-enter and revise it.

`spec.md` is a **living spec**: re-entered freely **before and after** implementation, always updated
**in place**, never "closed" or "done". When code teaches something the spec got wrong, come back and
revise it — the spec tracks the slice for its whole life, not just up to the first implementation.

## When to Use

- Starting a slice when only a vague idea or feature request exists.
- A vague ask ("make it faster", "add search") needs reframing into testable success criteria.
- Re-entering to update objective/scope/success as the slice's shape shifts.
- A maintenance item is fed back into the loop (`maintain → specify`) and needs framing as work.

**When NOT to use:**

- Cross-feature standing rules — that's `constitution`.
- The implementation approach — that's `design`.
- A one-line fix or mechanical task where "done" is self-evident.

## Inputs / Outputs (abstract)

- **Input:** an idea/intent (raw or a fed-back maintenance item), the **Constitution** (provided by the
  caller, always read first), and any prior **Specification** when re-entering.
- **Output:** the **Specification**, emitted per the result contract for the caller to ingest. The skill
  writes no files and resolves no storage.

## Process

### 1. Read the standing context first

Read the **Constitution** and, if re-entering, the prior **Specification**. The constitution's
principles and constraints bound what the spec may commit to — don't restate them, inherit them.

### 2. Extract the real intent — don't guess

If the idea is underspecified (missing who / why now / what success is) or a vague convention,
**run the `interview` posture** (one question at a time) rather than silently filling gaps. `specify`
is `interview`'s primary caller. Surface any assumption you must make explicitly:

```
ASSUMPTIONS:
- This is a web app (not native mobile).
- "Search" means within existing content, not the web.
→ Correct me now or I proceed with these.
```

### 3. Scope to one vertical slice

Frame a thin end-to-end slice, not the whole product. State explicitly what is **in** and what is
**out** — the out-of-scope line prevents silent disagreement about non-goals.

On a **brownfield** project, scope the slice as a **delta against existing behavior**: what changes or
extends, with the existing baseline named by reference (not re-specified). The spec describes the change
to make, never a restatement of code that already exists.

### 4. Reframe vague asks into testable success criteria

Translate conventions into concrete, checkable conditions:

```
ASK:   "make the dashboard faster"
SUCCESS CRITERIA:
- LCP < 2.5s on 4G;  initial data load < 500ms;  CLS < 0.1.
→ Are these the right targets?
```

Success criteria are what `verify`/`review` later check against, so they must be specific. Stay
above implementation — *what* must be true when done, not *how* it's achieved.

### 5. Emit the result

Emit the Specification per the result contract — the body plus its gate decision — for the caller to
ingest. Write no files and resolve no storage; persistence and any re-entry overwrite are the driver's
job.

### 6. Gate

Force the decision: *"Is the objective, scope, and success right — and is it ready to fan out into
requirements?"* This gate earns its interruption: everything downstream decomposes from this. Surface
it for the caller — standalone, present it to the user; under a driver, the driver holds the gate.

## Artifact shape

Short form below; template, the reframe technique, and a worked example live in
`references/spec-guide.md`.

```markdown
# Spec — [slice / feature]

## Objective
[What we're building and why; who benefits.]

## Scope
- In:  [what this slice covers]
- Out: [what it explicitly does NOT]

## Success criteria
- [specific, testable condition]

## Open questions
[Unresolved items needing human input — empty if none.]
```

## Composability (big↔small)

A typo-sized job may skip `specify` entirely (go straight to `implement`); a small slice may have a
three-line spec; a product's first slice carries scope + success + open questions. Never pad to fill
the template — empty sections cost the reader's budget downstream.

## Red Flags

- Restating constitution content (stack, conventions, boundaries) in the spec.
- Describing the implementation approach — that's `design` leaking up.
- Specifying the whole product instead of one vertical slice.
- Vague success ("make it better") that `verify` could never check.
- Silently filling an ambiguous requirement instead of running `interview`.
- No out-of-scope line.
- Writing files / resolving storage instead of just emitting the result (that's the driver's job).

## Verification

- [ ] Constitution read first; nothing from it restated in the spec.
- [ ] Intent extracted via `interview` (or assumptions surfaced explicitly) — not silently guessed.
- [ ] Scope framed as one vertical slice, with an explicit out-of-scope line.
- [ ] Success criteria are specific and testable (something `verify`/`review` can check).
- [ ] No implementation/architecture detail (that's `design`).
- [ ] Emitted per the result contract; no files written / no storage resolved by the skill.
- [ ] The gate decision was posed (caller/driver holds it).
