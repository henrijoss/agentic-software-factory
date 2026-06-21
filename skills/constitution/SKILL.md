---
name: constitution
description: Establishes a project's constitution — a short, durable set of governing principles and non-negotiable constraints that every later SDLC phase reads before it acts. Use at the start of a project before specifying features, when standing rules are implicit or scattered, or when recurring decisions keep getting re-litigated and need one source of truth. Distinct from a per-feature spec: the constitution captures what holds across all features.
---

# Constitution

## Overview

The constitution is the project's standing law: a short, durable set of governing principles and
non-negotiable constraints that **every later phase reads before it acts**. A spec describes one
feature; the constitution describes what holds across all of them — taste, quality bars, tech
constraints, boundaries, and how to resolve recurring trade-offs.

Because every phase loads it, the constitution spends the agent's standing-instruction budget on
**every run**. Keep it ruthlessly small: a handful of high-signal principles, each earning its place.
A bloated constitution degrades compliance everywhere downstream — the opposite of its purpose.

## When to Use

- Starting a new project, before `specify`.
- Standing rules exist but are implicit or scattered (in your head, across docs).
- Recurring decisions keep getting re-litigated and need one source of truth.
- Re-entering to amend principles as the project's values harden.

**When NOT to use:**

- A one-off change in a project that already has a constitution — just read it.
- Per-feature decisions — those belong in the spec/requirement, not the constitution.
- Mechanical tasks (renames, formatting, file moves).

## Inputs / Outputs (abstract)

- **Input:** project context — existing standing docs (`CLAUDE.md`, `README`, `docs/adr/`, memory)
  plus the user's intent for what is non-negotiable.
- **Output:** the **Constitution**, emitted per the result contract for the caller to ingest. The skill
  itself writes no project artifact and resolves no storage — it just produces the constitution.

## Process

### 1. Harvest, don't reinvent

Before asking anything, read what already encodes standing rules: `CLAUDE.md`, `README`, `docs/adr/`,
memory. Much of the constitution may already exist — pull durable principles from there.

On a **brownfield** project (the caller signals greenfield vs brownfield), also capture the
**existing-system facts** that bound every future slice — stack, primary entry points, conventions — but as **references**
(link `CLAUDE.md`, manifests, key directories) plus at most a few lean constraints that pass the budget
test (e.g. "new slices extend the existing Django app; do not re-platform"). Never copy a code inventory
in: that is a snapshot that goes stale the moment code moves. Fine-grained current state is read live by
`design`, per requirement — not frozen here.

### 2. Reference existing sources — never duplicate

If a rule already lives in an authoritative file (e.g. `CLAUDE.md`'s tooling rules), the constitution
**links to it by reference**; it does not copy it. Two copies of a rule are two places to go stale —
the exact failure this skillset fights. The constitution holds the principles that have no other
home, plus explicit references to those that do.

### 3. Elicit the missing principles

For what isn't written down, draw it out. If the durable values are unclear, run the `interview`
posture (one question at a time) rather than guessing. Target the non-negotiables: quality bars,
taste, tech constraints, boundaries (always / ask-first / never), and how to resolve recurring
trade-offs (e.g. simplicity vs. flexibility).

### 4. Keep it lean — the budget test

Every candidate principle must pass: **"Would a later phase change its behavior because of this
line?"** If not, cut it. Aim for ~5–12 principles. The constitution is law, not documentation; if it
reads like a wiki, it is too big. See `references/authoring-guide.md` for the principle-vs-not tests.

### 5. Emit the result

Emit the Constitution per the result contract — the body plus its gate decision — for the caller to
ingest. Write no files and resolve no storage; persistence and any re-entry overwrite are the driver's
job, not this skill's.

### 6. Gate

Force the decision: *"Are these the standing principles we commit every feature to?"* This gate earns
its interruption because everything downstream inherits these. Surface it for the caller — standalone,
present it to the user; under a driver, the driver holds the gate and advances on approval.

## Artifact shape

Short form below; full template, section guidance, and a worked example live in
`references/authoring-guide.md`.

```markdown
# Constitution — [project]

## Principles
- [durable principle; why it matters, in one clause]

## Constraints (non-negotiable)
- [tech / process constraint]

## Boundaries
- Always: …   - Ask first: …   - Never: …

## Trade-off defaults
- When [X] and [Y] conflict, prefer [Z] because …

## References
- [rule that lives elsewhere] → see `path` (single source of truth)
```

## Composability (big↔small)

A tiny project's constitution may be three principles plus a reference to `CLAUDE.md`. A large one
adds constraints, boundaries, and trade-off defaults. Never pad a small project to fill the template
— empty sections are noise that costs budget at every downstream phase.

## Red Flags

- Copying rules that already live in `CLAUDE.md`/ADRs instead of referencing them.
- A constitution longer than ~one screen — it competes with every phase's instruction budget.
- Principles a downstream phase would never act on (documentation, not law).
- Per-feature detail leaking in (belongs in the spec).
- Writing files / resolving storage instead of just emitting the result (that's the driver's job).

## Verification

- [ ] Existing standing docs harvested; nothing duplicated (rules with a home are referenced).
- [ ] Brownfield: existing-system facts captured by reference (+ ≤ a few lean constraints), not as a
      copied code inventory.
- [ ] Each principle passes the budget test (changes some downstream phase's behavior).
- [ ] The constitution fits ~one screen.
- [ ] Emitted per the result contract; no files written / no storage resolved by the skill.
- [ ] The gate decision was posed (caller/driver holds it).
