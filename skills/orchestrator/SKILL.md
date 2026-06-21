---
name: orchestrator
description: Drives the SDLC loop end to end for unattended runs — walks the phase graph, runs one phase skill at a time, pauses at every human gate, and AUTO-ADVANCES to the next phase on explicit approval. Built on the `continue` base skill, which defines the artifact tree, storage, invariants, bootstrap, and the phase graph; the orchestrator adds only the auto-advance loop across gates. Use to run a full project or a sub-chain as one continuous driven session. For a single step ("do the next thing and stop"), use `continue` instead. Not itself a phase.
---

# Orchestrator (full-loop driver)

## Overview

The orchestrator is the **full-automation driver**: it turns the standalone skills into one
continuous session that walks the loop, gating and **auto-advancing** through phase after phase on
explicit approval. It adds no SDLC logic of its own and no structure of its own — it **builds on the
`continue` base skill** for the phase graph, the artifact tree/IDs/storage, bootstrap, and
gate-validation. Its one added job over `continue` is auto-advancing across gates instead of stopping
after a single phase.

Use `continue` to run **one** step and stop; use the orchestrator to run the **whole loop** unattended
(stopping only at gates for approval). Like `continue`, it loads **one phase skill at a time**, so the
instruction-budget discipline holds: only the active phase's `SKILL.md` is in context.

## When to Use

- **Full project:** walk the whole loop from `constitution` (or `specify`) through `maintain`,
  slice after slice.
- **Sub-chain:** start mid-loop from a known artifact and auto-advance the back half (e.g. a ready
  `[REQ-n]` → `design` onward).

**When NOT to use:**

- A single step ("do the next thing and stop") — use the `continue` base skill.
- A single one-off skill — invoke that phase skill directly.
- As a phase itself — it sequences phases, it doesn't own an artifact.

## Inputs / Outputs (abstract)

- **Input:** the user's **entry intent** (full / sub-chain — see entry modes in the `continue` base
  skill's `references/phase-graph.md`) and `index.md` (current tree + status). Plus `[CONST]`, which
  every phase loads.
- **Output:** a driven, gated session that advances the project across many phases; `index.md`'s
  **status dashboard** kept current as each phase completes. Phases emit results (pure transforms); the
  driver **ingests** each into the tree via the `continue` base skill — the orchestrator never asks a
  phase to write tree state itself.

## Process

### 1. Defer to the base skill for structure and the next phase

Load the `continue` base skill for the artifact tree, storage, root resolution, gate-validation, the
phase graph, and the **sync/drift check** (`references/sync.md`). Resolve the tree root (discover the
single `index.md`; if none, `setup` or the fallback creates the default `docs/sdlc/` root + a default
`settings.json`). The **version-compat check** and settings reads come for free here too — `continue`
runs them at session start; a **major** version mismatch holds like any other gate (no auto-advance
until migrated/overridden), and the configured `verifyMode`/`reviewLoops` flow through the base skill's
phase-graph and input-assembly logic. Run the
sync check at session start; if external commits since `Last synced commit` are detected, hold the sync
gate and reconcile **before** advancing — like every gate, no auto-advance past unresolved drift.
Resolve the entry mode
(full / sub-chain) and the start phase from `index.md` status + the phase graph; confirm the start
point with the user when it isn't unambiguous. If the intent is a single one-off skill, defer to that
phase skill directly — don't spin up the loop.

### 2. Assemble inputs, run one phase, ingest the result

Per the `continue` base skill (`references/handoff.md`): **assemble** the phase's inputs from the tree
and pass them as content. Load **only** the active phase's `SKILL.md` and run it — a pure transform that
does its work (invoking postures as it needs) and **emits a result** (in-context block, or
`.sdlc/scratch/` for `to-*`); do not pre-empt or duplicate its internal logic, and don't let it touch
the tree. Then **ingest** the result: resolve/assign the ID, write to the tree (in place on re-entry),
register in `index.md`, clear scratch.

### 3. Hold the gate

Run **gate-validation** per the base skill (dangling / duplicate / orphan / unreachable → fail and
surface). Present the phase's gate decision (the specific question from the graph, never "looks
good?") and **wait for explicit approval**. A gate that surfaces nothing to decide is a smell — say so
rather than rubber-stamping. Outward/irreversible gates (notably `deploy`) require their own explicit
authorization regardless of prior approvals.

### 4. Update status and AUTO-ADVANCE

On explicit approval, update the artifact's status in `index.md`, then advance to the **next phase in
the graph** and return to step 2 — this auto-advance is what distinguishes the orchestrator from
`continue` (which stops after one phase). On rejection or a surfaced divergence, route per the phase
(rework re-enters the phase; a stale upstream artifact re-enters `specify`/`design` for in-place
update) — never auto-advance past an unresolved gate.

### 5. Close or loop

`maintain`'s gate selects discovered work that re-enters `specify` — the loop closes and the next
**vertical slice** begins, re-entering phases that update their artifacts **in place**. End the
session when the user has no further slice to drive.

See `references/orchestration-guide.md` for auto-advance semantics and a worked example.

## Fresh-context variant (long unattended runs)

Auto-advancing inside **one** session means the transcript grows phase after phase — the
ever-growing-session failure mode the `implement` session-loop warns about, now at the phase level. For
a long unattended run where you want context **zeroed each step**, use the fresh-process loop instead:
`skills/orchestrator/loop.sh` runs each step as a brand-new `claude -p "/continue"` process that
resumes cold from `index.md`, runs one phase, writes its result, and exits. The headless `/continue`
records its gate decision in `.sdlc/loop-control` (`continue` / `halt: <reason>` / `done`), so the
`halt` gates — sync drift, `deploy`/irreversible authorization, ambiguous or failed gates — still stop
for a human. Same phase graph, same gates; the only trade is in-session auto-advance (keeps the
transcript) vs. a cold process per step (keeps context flat). See the `continue` base skill's
`references/fresh-context.md`.

## Composability (big↔small)

A typo never needs the orchestrator — invoke `implement` alone. A single step is `continue`. A single
requirement enters at `design` and auto-advances the back half. A product runs the full loop, slice
after slice. The orchestrator materializes only the phases (and artifact-tree levels) the chosen entry
actually needs; no phase or tree level is mandatory.

## Red Flags

- Reaching for the orchestrator when the user wanted one step — that's `continue`.
- Loading several phase skills at once instead of one at a time (defeats the budget discipline).
- Auto-advancing without **explicit** approval, or posing a "looks good?" gate with nothing to decide.
- Re-implementing the base skill's structure/graph logic or a phase's logic in the orchestrator.
- Skipping gate-validation between phases (lets a stale/broken tree propagate).
- Forgetting bootstrap — running a phase with no `index.md` entry point.
- Bypassing `deploy`'s distinct ship authorization because review was approved.
- Reaching for a long single-session run to keep context "for continuity" — that's the
  ever-growing-session failure mode; for long unattended runs use the fresh-process loop (`loop.sh`).

## Verification

- [ ] Structure, graph, bootstrap, gate-validation, the version-compat check, and the sync/drift check
      deferred to the `continue` base skill; version checked and sync check run at session start, a major
      version mismatch held (not auto-advanced), drift (if any) reconciled at its gate before advancing.
- [ ] Entry mode resolved; single steps deferred to `continue`, single one-offs to the phase skill.
- [ ] `index.md` entry point ensured (bootstrap idempotent) before any phase ran.
- [ ] Exactly one phase skill loaded/run at a time, in graph order.
- [ ] Gate-validation run between phases; every gate posed its real decision and got **explicit**
      approval before auto-advancing; rejections routed, not skipped.
- [ ] `index.md` status updated as each phase completed.
- [ ] Loop closure handled (`maintain → specify`) for the next slice; in-place updates on re-entry.
- [ ] For long unattended runs, the fresh-process loop (`loop.sh`) chosen over one growing session;
      `halt` gates still stopped for a human via `.sdlc/loop-control`.
