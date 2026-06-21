---
name: to-requirements
description: Fans one Specification out into Stakeholders and N Requirements (use-cases) — discrete units of desired behavior/value, each a vertical-slice candidate, plus who cares about each. The transition from specify to clarify. Use when an approved Spec needs decomposing into use-cases and the people they serve, and to pick which slice to run the loop on first. Distinct from `specify` (one Spec, the what/why) and `clarify` (deepens one requirement): this fans out and sequences.
---

# To-Requirements

## Overview

`to-requirements` decomposes one approved **Specification** into **Stakeholders** and **N
Requirements** (use-cases) — each a discrete unit of desired behavior/value and a candidate vertical
slice — then helps pick which slice to run first. It is where the project's intent fans out into the
units the rest of the loop iterates over.

This is a **transition skill** (`to-<phase>`): it moves work between `specify` and `clarify`, and is
where **fan-out** happens (one Spec → many Requirements + stakeholders). It adds real logic —
use-case decomposition, stakeholder mapping, sequencing — not reformatting. It emits **draft**
Requirements; `clarify` deepens one to ready, and `design` consumes a ready Requirement.

## When to Use

- An approved Spec needs decomposing into use-cases and the stakeholders they serve.
- You need to pick the first vertical slice to run the loop on.
- Re-entering to add/revise requirements as the project's scope grows.

**When NOT to use:**

- Writing the Spec itself (the what/why) — that's `specify`.
- Deepening a single requirement — that's `clarify`.
- Deciding the approach for a requirement — that's `design`.

## Inputs / Outputs (abstract)

- **Input:** the approved **Specification** and the **Constitution** — provided by the caller.
- **Output:** **Stakeholders** + N draft **Requirements**, plus a recommended first slice. As a
  transition skill this fans out to **many** artifacts, so it writes one **scratch file per produced
  artifact** under `.sdlc/scratch/` (each with result-contract front-matter) plus a fan-out summary;
  the driver ingests them into the tree. The skill writes only scratch — never the tree or `index.md`.

## Process

### 1. Read the Spec and context

Read the **Specification** (objective, scope, success) and the **Constitution**. Decompose the
*approved* spec — if the objective or scope turns out wrong, return to `specify` rather than reshaping
it here.

### 2. Identify stakeholders

Name who cares about the outcome and what each needs — the users and other parties the work serves.
Each becomes a Stakeholder that Requirements reference. Stakeholders are *why* a requirement exists; a
requirement with no stakeholder is a smell.

### 3. Decompose into use-case Requirements

Fan the spec out into discrete units of behavior/value. Each Requirement is **one use-case**, framed
as value to a stakeholder (e.g. *"As a member, I want X so that Y"*) and sliced **vertically**
(end-to-end value), not as a horizontal layer. Every requirement hangs off a use-case — no standalone
"enabler" requirements. Keep them **draft-level**: enough to choose and sequence; `clarify` adds the
depth before `design`.

### 4. Sequence — pick the first slice

Order the requirements and recommend which slice to run first: thinnest end-to-end path, highest
risk, or highest value (state which criterion you used). The loop runs one slice at a time, so this
choice matters.

### 5. Fan out for user feedback

As a transition skill, **pause for user feedback** on the set: are these the right use-cases and
stakeholders, and is the first-slice pick correct? The decomposition is the user's to shape.

### 6. Write the fan-out to scratch

Write one file per produced artifact under `.sdlc/scratch/` — a file per Requirement (referencing its
stakeholders by name), the Stakeholder set, and a fan-out summary (ordering + recommended first slice)
— each with the result-contract front-matter. Write **only** scratch; the driver ingests them into the
tree, assigns IDs, and updates any existing set in place.

### 7. Gate

Present the requirements, stakeholders, and first-slice recommendation, and force the decision:
*"Are these the right use-cases and stakeholders? Which slice first?"* Surface it for the caller —
standalone, present it to the user; under a driver, the driver holds the gate and advances the chosen
slice to `clarify`.

## Requirement shape

Short form below; template, decomposition tests, sequencing, and a worked example live in
`references/requirements-guide.md`.

```markdown
# [use-case title]

**As a** [stakeholder] **I want** [capability] **so that** [value].
**Acceptance (draft):** [the signals this is met — clarify will sharpen these]
**Stakeholders:** [stakeholder, …]
**Open questions:** [what clarify must resolve before design]
```

## Composability (big↔small)

A small Spec may fan out to two requirements and one stakeholder. A product yields many, sequenced
into a backlog with a clear first slice. Don't manufacture stakeholders or split a single use-case to
fill a template — the smallest faithful set is the goal.

## Red Flags

- Re-opening the Spec's objective/scope — return to `specify` instead.
- A Requirement with no stakeholder, or "enabler" requirements not hung off a use-case.
- Horizontal decomposition (all-DB, all-API) instead of vertical use-cases.
- Over-specifying a requirement here — that's `clarify`'s job; keep these draft-level.
- Fanning out without pausing for user feedback, or shipping no first-slice recommendation.
- Writing into the tree/`index.md` instead of scratch files (the driver ingests scratch).

## Verification

- [ ] Decomposed the approved Spec; objective/scope not re-opened.
- [ ] Stakeholders identified; every Requirement references at least one.
- [ ] Each Requirement is one vertical use-case (value to a stakeholder), draft-level.
- [ ] Requirements sequenced; a first slice recommended with the criterion stated.
- [ ] User feedback taken on the set during fan-out.
- [ ] Fan-out written to `.sdlc/scratch/` per the result contract (a file per artifact + summary);
      nothing written to the tree/`index.md` by the skill.
- [ ] The gate decision was posed (caller/driver holds it and routes the first slice to `clarify`).
