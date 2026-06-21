---
name: deploy
description: Ships a reviewed, approved slice into operation — build / prerender / publish using the commands the project declares, gated by an explicit pre-ship authorization because shipping is outward-facing and hard to reverse. Appends a Deploy log entry recording what went live. Use when a slice has passed `review` and findings are resolved or consciously accepted. Not for deciding whether the code is correct (`review`) or for triaging what happens after it's live (`maintain`).
---

# Deploy

## Overview

`deploy` takes a **reviewed, approved** slice and puts it into operation — build, prerender, publish,
release, whatever "ship" means for this project. It is the one phase whose action is **outward-facing
and hard to reverse**: once published, content may be cached, indexed, or depended on by users. So
`deploy` is mechanism-agnostic (the actual ship commands resolve from `[CONST]`, never hardcoded) and
its gate is an **authorization gate before the action**, not a "looks good?" after it.

It produces no in-place artifact. Its output is the shipped change plus an **append-only** entry in
the Deploy log `[DEPLOY]` recording what went live, when, and how to roll it back.

## When to Use

- A slice has passed `review`; findings are resolved or consciously accepted as trade-offs.
- Re-shipping after a fix, or shipping a subsequent slice (each ship = a new appended log entry).

**When NOT to use:**

- Deciding whether the code is correct or meets quality bars — that's `review`.
- Confirming behavior the first time — that's `verify`/`test`.
- Triaging what happens once it's live (bugs, incidents) — that's `maintain`.
- A change that hasn't cleared its review gate — never ship past an unresolved blocker.

## Inputs / Outputs (abstract)

- **Input:** the reviewed slice (review findings resolved/accepted), and the **Constitution**
  `[CONST]` — which declares the **ship commands** and the deploy **boundaries** (deploy is the
  classic *ask-first* / *never without X* surface). Read both; never infer ship steps from memory.
- **Output:** the **shipped change**, plus a **Deploy log** entry `[DEPLOY]`. Storage resolves
  through the `continue` base skill (default `docs/sdlc/deploy/log.md`). This is an **append**, never
  an in-place overwrite — the log is the project's chronological ship record.

## Process

### 1. Read the ship contract from `[CONST]`

Read `[CONST]` for the ship commands (build / prerender / publish / release) and the deploy
boundaries (what requires asking first, what must never happen, required environments/order). If the
constitution doesn't specify how this project ships, **stop and ask** — do not invent a deploy
procedure. Mechanism lives in the project, not this skill.

### 2. Run the pre-ship checklist

Confirm the slice is actually shippable before touching anything outward-facing:

- [ ] `review` gate passed — no unresolved blockers; trade-offs documented.
- [ ] Artifact **gate-validation** clean (no dangling / duplicate / orphan / unreachable ID) per
      the `continue` base skill.
- [ ] Build/checks green per `[CONST]`.
- [ ] **Rollback is known** — how to undo this ship if it goes wrong, written down before shipping.

A failed checklist item blocks the ship; surface it rather than proceeding.

### 3. Authorization gate (before the irreversible action)

Shipping publishes — it may be cached or indexed even if later removed. Present **what is about to go
live, where, by which commands, and the rollback plan**, and get **explicit authorization to ship**.
This is the gate that earns its interruption: it forces a real decision on an outward-facing,
hard-to-reverse action. Approval to *review* is not approval to *ship*; ask here regardless. Respect
every `[CONST]` boundary (ask-first / never-without-X).

### 4. Ship

Execute the project's ship commands from `[CONST]`, in the declared order/environments. If a step
fails, stop — do not push past a failed publish into an unknown half-shipped state; fall back to the
rollback plan and report.

### 5. Append the Deploy log entry

Write a new `[DEPLOY]` entry via artifact-io (default append to `docs/sdlc/deploy/log.md`): what
slice/IDs shipped, when, commands/version/target, outcome, and the rollback handle. **Append** —
never overwrite prior entries. Update `index.md` status to reflect what is now in operation.

### 6. Gate → maintain

Confirm the ship landed and present the decision: *"Did it ship cleanly; what is now in operation?"*
On confirmation, hand off to `maintain` (which watches the live result and feeds discovered work back
to `specify`).

## Artifact shape

Append-only log; full field guidance and a worked example in `references/deploy-guide.md`.

```markdown
## [DEPLOY] 2026-06-20 — REQ-03 saved-search alerts
- Shipped: REQ-03 (TASK-01..03)
- Target/version: prod, v1.4.0
- Commands: `npm run build && npm run deploy:prod`   (per [CONST])
- Outcome: success
- Rollback: `npm run deploy:rollback v1.3.4` / revert <sha>
```

## Composability (big↔small)

A one-off may be a single ship command + a one-line log entry. A production slice runs the full
checklist, staged environments, and a documented rollback. Never skip the **authorization gate** or
the **rollback-known** check regardless of size — those guard the irreversible action, not the
paperwork.

## Red Flags

- Hardcoding ship commands instead of resolving them from `[CONST]`.
- Shipping on the review approval without a distinct **authorization** to publish.
- No rollback plan written down before shipping.
- Shipping past a failed build/publish step into a half-shipped state.
- Overwriting the Deploy log instead of appending (loses the ship history).
- Shipping a slice with an unresolved review blocker.

## Verification

- [ ] Ship commands + boundaries read from `[CONST]`, not invented or remembered.
- [ ] Pre-ship checklist passed: review clean, gate-validation clean, build green, rollback known.
- [ ] Explicit **authorization to ship** obtained at the gate (distinct from review approval),
      honoring `[CONST]` boundaries.
- [ ] Ship executed in declared order; a failed step stopped the ship (no half-shipped state).
- [ ] `[DEPLOY]` entry **appended** (not overwritten) with slice IDs, target, commands, outcome,
      rollback; `index.md` status updated.
- [ ] Handoff decision posed and confirmed before `maintain`.
