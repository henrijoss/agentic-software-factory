---
name: deploy
description: Ships a reviewed, approved slice into operation — build / prerender / publish using the commands the project declares, gated by an explicit pre-ship authorization because shipping is outward-facing and hard to reverse. Appends a Deploy log entry recording what went live. Use when a slice has passed `review` and findings are resolved or consciously accepted. Not for deciding whether the code is correct (`review`) or for triaging what happens after it's live (`maintain`).
---

# Deploy

## Overview

`deploy` takes a **reviewed, approved** slice and puts it into operation — build, prerender, publish,
release, whatever "ship" means for this project. It is the one phase whose action is **outward-facing
and hard to reverse**: once published, content may be cached, indexed, or depended on by users. So
`deploy` is mechanism-agnostic (the actual ship commands resolve from the **Constitution**, never
hardcoded) and its gate is an **authorization gate before the action**, not a "looks good?" after it.

Its output is the shipped change plus a **Deploy log entry** recording what went live, when, and how to
roll it back — emitted per the result contract; the driver appends it to the log.

## When to Use

- A slice has passed `review`; findings are resolved or consciously accepted as trade-offs.
- Re-shipping after a fix, or shipping a subsequent slice (each ship = a new appended log entry).

**When NOT to use:**

- Deciding whether the code is correct or meets quality bars — that's `review`.
- Confirming behavior the first time — that's `verify`/`test`.
- Triaging what happens once it's live (bugs, incidents) — that's `maintain`.
- A change that hasn't cleared its review gate — never ship past an unresolved blocker.

## Inputs / Outputs (abstract)

- **Input:** the reviewed slice (review findings resolved/accepted), and the **Constitution** — which
  declares the **ship commands** and the deploy **boundaries** (deploy is the classic *ask-first* /
  *never without X* surface) — all provided by the caller. Never infer ship steps from memory.
- **Output:** the **shipped change** (the skill's real outward action), plus a **Deploy log** entry
  emitted per the result contract. The driver appends it to the chronological ship log (an append,
  never an overwrite); the skill resolves no SDLC storage itself.

## Process

### 1. Read the ship contract from the Constitution

Read the **Constitution** for the ship commands (build / prerender / publish / release) and the deploy
boundaries (what requires asking first, what must never happen, required environments/order). If the
constitution doesn't specify how this project ships, **stop and ask** — do not invent a deploy
procedure. Mechanism lives in the project, not this skill.

### 2. Run the pre-ship checklist

Confirm the slice is actually shippable before touching anything outward-facing:

- [ ] `review` gate passed — no unresolved blockers; trade-offs documented.
- [ ] Tree structurally valid — the driver guarantees this via gate-validation at the gate before
      deploy runs; standalone, confirm there is no unresolved structural breakage.
- [ ] Build/checks green per the **Constitution**.
- [ ] **Rollback is known** — how to undo this ship if it goes wrong, written down before shipping.

A failed checklist item blocks the ship; surface it rather than proceeding.

### 3. Authorization gate (before the irreversible action)

Shipping publishes — it may be cached or indexed even if later removed. Present **what is about to go
live, where, by which commands, and the rollback plan**, and get **explicit authorization to ship**.
This is the gate that earns its interruption: it forces a real decision on an outward-facing,
hard-to-reverse action. Approval to *review* is not approval to *ship*; ask here regardless. Respect
every **Constitution** boundary (ask-first / never-without-X).

### 4. Ship

Execute the project's ship commands from the **Constitution**, in the declared order/environments. If a step
fails, stop — do not push past a failed publish into an unknown half-shipped state; fall back to the
rollback plan and report.

### 5. Emit the Deploy log entry

Produce the Deploy log entry: what slice shipped, when, commands/version/target, outcome, and the
rollback handle. Emit it per the result contract; the driver **appends** it to the ship log (never
overwriting prior entries) and updates status to reflect what is now in operation.

### 6. Gate

Confirm the ship landed and present the decision: *"Did it ship cleanly; what is now in operation?"*
Surface it for the caller — standalone, present it to the user; under a driver, the driver holds the
gate and advances to `maintain` (which watches the live result and feeds discovered work back).

## Artifact shape

Append-only log; full field guidance and a worked example in `references/deploy-guide.md`.

```markdown
## 2026-06-20 — saved-search alerts
- Shipped: the slice and its tasks
- Target/version: prod, v1.4.0
- Commands: `npm run build && npm run deploy:prod`   (per the Constitution)
- Outcome: success
- Rollback: `npm run deploy:rollback v1.3.4` / revert <sha>
```

## Composability (big↔small)

A one-off may be a single ship command + a one-line log entry. A production slice runs the full
checklist, staged environments, and a documented rollback. Never skip the **authorization gate** or
the **rollback-known** check regardless of size — those guard the irreversible action, not the
paperwork.

## Red Flags

- Hardcoding ship commands instead of resolving them from the **Constitution**.
- Shipping on the review approval without a distinct **authorization** to publish.
- No rollback plan written down before shipping.
- Shipping past a failed build/publish step into a half-shipped state.
- Overwriting the Deploy log instead of appending (loses the ship history).
- Shipping a slice with an unresolved review blocker.

## Verification

- [ ] Ship commands + boundaries read from the **Constitution**, not invented or remembered.
- [ ] Pre-ship checklist passed: review clean, tree structurally valid, build green, rollback known.
- [ ] Explicit **authorization to ship** obtained at the gate (distinct from review approval),
      honoring **Constitution** boundaries.
- [ ] Ship executed in declared order; a failed step stopped the ship (no half-shipped state).
- [ ] Deploy log entry emitted per the result contract (slice, target, commands, outcome, rollback);
      the driver appends it and updates status.
- [ ] Handoff decision posed (caller/driver advances to `maintain`).
