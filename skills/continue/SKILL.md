---
name: continue
description: The base skill of the SDLC skillset — load it whenever you work within this system. It defines the artifact tree, stable IDs, storage, the tree's structural invariants, gate-validation, and tree-root bootstrap, plus the canonical phase graph. As the default driver it reads where the project left off from `index.md`, runs the next single phase, and stops at its gate. Use to resume/continue a project ("where did we leave off", "do the next step") or whenever a phase skill needs the structure and storage rules. For unattended full-loop automation, use `orchestrator` instead.
---

# Continue (base skill)

## Overview

`continue` is the **foundation of the SDLC skillset**. Any work within this system loads it first: it
is the single place that defines *how artifacts are stored and structured* and *how the loop is
sequenced*. It is also the **default driver** — it reads `index.md` to see where the project stands,
runs the **next single phase**, and stops at that phase's human gate. The operator stays in control
step by step. For unattended walking of the whole loop (auto-advancing through gates on approval),
defer to `orchestrator`, which builds on this skill.

Every other skill is a **pure, system-agnostic transform** — it knows nothing of the tree, `index.md`,
IDs, storage, or chaining; it takes the inputs the driver provides and **emits a result** (the result
contract). This skill does everything system-shaped around it: it **assembles** a phase's inputs from
the tree before, and **ingests** the emitted result into the tree after — `continue` is the only actor
that reads/writes the tree, `index.md`, and IDs. Depth (the result contract, ingest and input-assembly
in `references/handoff.md`; the full storage-binding table and optional GitHub edge integrations; the
entry modes and worked example) lives in `references/` and is loaded on demand.

## When to Use

- **Resume:** continue a project from where `index.md`'s status dashboard left off — run the next step.
- **Single step:** advance the project by exactly one phase, then stop at its gate.
- **Structure/storage reference:** any time a phase needs the artifact tree, IDs, paths, bootstrap, or
  gate-validation rules.

**When NOT to use:**

- Unattended full-loop automation across many phases — that's `orchestrator`.
- As a phase itself — it owns no phase artifact; it sequences phases and defines the structure.

## Artifact tree & storage (local files, versioned with code)

All non-source artifacts form **exactly one tree per project with a single entry point**. The folder
layout *is* the tree; storage is local files, versioned with the code (the single canonical store —
there is no swappable backend). The tree root is
`docs/<root>/` — its name is chosen once at init by the `setup` skill, **default `sdlc`** (i.e.
`docs/sdlc/`). All paths below are relative to that resolved root.

```
docs/<root>/          ← root chosen at `setup`; default `docs/sdlc/`
  index.md            ← SINGLE ENTRY POINT: tree map + ID registry + live phase/gate status
  constitution.md     ← [CONST]
  spec.md             ← [SPEC]
  requirements/
    REQ-01/
      requirement.md  ← [REQ-01]        (Stakeholders referenced by ID)
      design.md       ← [REQ-01.DESIGN]
      tasks/
        TASK-01.md    ← [REQ-01.TASK-01]
      sessions/
        summary.md    ← [REQ-01.SESSION]
    REQ-02/ …
  deploy/log.md       ← [DEPLOY]        (optional — appears when deploy runs)
  maintenance/queue.md← [MAINT]         (optional — appears when maintain runs)
```

`index.md` is the **root object** and plays three roles at once: **tree map** (navigable structure),
**ID registry** (stable, rename-safe ID → path), and **status dashboard** (each artifact's current
phase/gate state — this is "where we left off"). Cross-references target IDs through `index.md`, never
raw paths buried in prose. The status dashboard also records the **last synced commit** — the git
`HEAD` the system last reconciled against — which the sync check below reads to detect external drift.

**Optional levels.** Directories materialize only when their producing skill runs. A one-off
`implement` may create just `index.md` + `spec.md` + one task — no `requirements/` layer. The
single-entry-point invariant holds at every size.

**In-place update.** Re-entering a phase overwrites that phase's artifact file; it never forks a
parallel copy. Git history carries the versioning.

The full storage-binding table (abstract artifact → read/write op) and the **optional GitHub edge
integrations** (`maintain` inbound, optional one-way mirror — not a backend) live in
`references/artifact-io.md`.

## Structural invariants (the tree)

The artifact tree MUST satisfy these — the contract, not implementation detail:

1. **Single entry point.** Exactly one root object per project; every artifact reachable from it.
2. **Single tree.** Artifacts form one tree; no second root, no detached subgraph.
3. **ID registry.** The root maps every stable ID → location; references target IDs, never raw paths.
4. **Gate validation.** A validation step runs at **every gate** and FAILS on: a dangling ID, a
   duplicate ID, an unregistered/orphan artifact, or any artifact unreachable from the root.

These plus the in-place-update rule are what keep spec and code from silently diverging.

## Resolve the tree root (discovery + bootstrap)

This is the single canonical rule for **locating the tree root**; every other skill defers here
instead of assuming a path.

- **Discover the single `index.md`.** Locate the one SDLC `index.md` (conventionally under `docs/`),
  identified by its tree-map + ID-registry markers. The root is its directory `docs/<root>/`; all
  artifact paths are relative to it.
  - **Exactly one** → use it.
  - **None** → the tree isn't initialized: run `setup` to choose the location and scaffold it. As a
    **fallback** when a driver runs without prior `setup`, the driver creates the **default**
    `docs/sdlc/` root below — **idempotent**, never overwrite or fork.
  - **Multiple** → violates the single-tree invariant; surface it rather than guessing.
- **`setup` is the front door.** The explicit init that picks the root name (default `sdlc`) and
  scaffolds it; the driver fallback above only guarantees a default root if `setup` was skipped. Only
  `setup` and the two drivers ever create the tree — standalone non-system skills create none.

Minimal root (created by `setup`, or by the fallback at `docs/sdlc/`):

```markdown
# SDLC Index — [project]

## Tree map
(empty — artifacts register here as phases run)

## ID registry
| ID | Path | Status |
|----|------|--------|

## Status
Project: bootstrapped — no phases run yet.
Last synced commit: <sha | none>
```

The status line reflects `setup`'s orient glance: greenfield stays as above; brownfield reads
`bootstrapped (brownfield: <stack>) — no phases run yet`. It is a one-line signal only — never a code
inventory. `Last synced commit` is the git `HEAD` the system last reconciled against (`none` when there
is no repo/commit yet); the sync check maintains it.

## Phase graph

The canonical sequencing source — the loop both drivers walk. Linear spine, closed by
`maintain → specify`:

```
constitution → specify → to-requirements → clarify → design → to-tasks → implement
             → verify/test → review → deploy → maintain → (specify, next slice)
```

- **Postures are not nodes.** `interview`, `doubt`, `incremental` are invoked *inside* phases, never
  scheduled by a driver.
- **`verify`/`test` is one node with a choice** — operator picks TDD (`test`), run-and-observe
  (`verify`), or both; the driver presents the choice, the `test`/`verify` skills define which applies.
- **Transition skills (`to-requirements`, `to-tasks`) fan out** and pause for user feedback at their
  own gate.

Each `→` is a human gate. The gate-decision table and entry modes (full / sub-chain / resume / single)
live in `references/phase-graph.md`.

## Process (default: run the next single step)

### 1. Resolve the tree root

Locate the tree per "Resolve the tree root" above (discover the single `index.md`). If none exists,
run `setup` — or, as a fallback, create the default `docs/sdlc/` root idempotently.

### 2. Read where the project stands

Read `index.md`'s status dashboard and tree map. The current per-artifact phase/gate state is "where
we left off."

### 3. Sync check (drift detection)

Detect code changes made **outside** the system since it last ran — the one blind spot in-place
re-entry can't see. Read `Last synced commit` from the status dashboard and the current `HEAD`
(`git rev-parse HEAD`).

- **No git repo / no commits / base missing** → skip (treat as no-drift); record `none` and proceed.
- **`HEAD` == recorded** → no external drift; proceed to step 4.
- **`HEAD` != recorded** → examine `recorded..HEAD` (`git diff --stat`, `git log --oneline`), reason
  about which open `[REQ-*]`/`[TASK-*]` those changes may have **resolved or invalidated**, and **hold
  the sync gate**: surface that reconciliation decision to the operator (never "looks good?"). Route the
  decision through normal in-place re-entry (resolved → mark done / confirm via `implement`→`review`;
  invalidated → re-enter `design`/`specify`). Then set `Last synced commit = HEAD`.

The equality test is only a cheap trigger — the value is reading the diff. Depth (own-commit gap,
graceful degradation, gate wording, routing, example) lives in `references/sync.md`.

### 4. Determine the next phase

From the status dashboard + the phase graph, pick the **single** next phase. If a single one-off skill
was requested, defer to that phase skill directly. When the next phase isn't unambiguous, confirm with
the user rather than guessing (see entry modes in `references/phase-graph.md`).

### 5. Assemble inputs, then run exactly one phase

**Assemble** the phase's inputs from the tree (`[CONST]`, the prior artifact on re-entry, the chosen
`[REQ-n]`, …) per the consumed-by mapping in `references/handoff.md`, and pass them as provided content.
Then load and run that one phase skill. It is a pure transform: it does its work (invoking postures as
needed), and **emits its result** — an in-context result block (phase skills) or `.sdlc/scratch/` files
(`to-*` skills). It does **not** touch the tree, `index.md`, or IDs. Do not pre-empt the phase's logic.

### 6. Ingest the result, hold the gate, then stop

**Ingest** per `references/handoff.md`: capture the emitted result → resolve/assign the stable ID →
write to the tree path (artifact-io), updating **in place** on re-entry (never fork) → register/update
`index.md` → clear `.sdlc/scratch/`. Run **gate-validation** (dangling / duplicate / orphan /
unreachable → fail and surface). Present the phase's specific gate decision (never "looks good?").
**Stop** — the operator decides whether to run `continue` again for the next step. (Auto-advancing
across gates is `orchestrator`'s job, not this skill's.)

## Composability (big↔small)

A typo just runs `implement`. A single requirement enters at `design`. A whole product walks the loop
one `continue` step at a time, or hands off to `orchestrator` for unattended runs. Only the phases and
tree levels a job needs ever materialize.

## Red Flags

- Auto-advancing past a gate — that's `orchestrator`; `continue` runs one phase and stops.
- Letting a phase skill write into the tree/`index.md`/IDs instead of emitting a result the driver
  ingests, or skipping input-assembly so the phase has to discover the tree itself.
- Running a phase with no `index.md` entry point, or assuming `docs/sdlc/` instead of resolving the
  root by discovery.
- Forking a duplicate artifact on re-entry instead of updating in place.
- A "looks good?" gate with nothing to decide.
- Skipping gate-validation, letting a stale/broken tree propagate.
- Skipping the sync check, or treating the equality test as a correctness gate instead of examining the
  `recorded..HEAD` diff to reconcile.
- Blocking a phase when there is no git repo/`HEAD` — the sync check degrades to no-drift, never blocks.

## Verification

- [ ] Tree root resolved by discovering the single `index.md` (or `setup`/fallback ran) before any
      phase — no hardcoded `docs/sdlc/` assumption.
- [ ] Status dashboard read; the single next phase chosen from the phase graph (or one-off deferred).
- [ ] Sync check run; any drift (`HEAD` != recorded) surfaced at the sync gate and reconciled, then
      `Last synced commit` updated to `HEAD` (or `none` when git is absent).
- [ ] Phase inputs **assembled** from the tree and passed as content; the phase emitted a result
      (in-context block, or `.sdlc/scratch/` for `to-*`) without touching the tree itself.
- [ ] Exactly **one** phase run, then stopped at its gate — no auto-advance.
- [ ] Result **ingested**: ID resolved, written to the tree, `index.md` registered/updated,
      `.sdlc/scratch/` cleared.
- [ ] Gate-validation run; the phase's real decision posed; `index.md` status updated.
- [ ] Re-entry updated artifacts in place — no duplicate fork.
