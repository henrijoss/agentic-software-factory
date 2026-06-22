---
name: setup
description: One-time project init for the SDLC skillset — choose where the artifact tree is generated and scaffold its single entry point `index.md`. The tree-root location is configurable with a default of `docs/sdlc/`; the operator may pick a different name. Run once at the start of a project, before `constitution`. After setup, every other skill discovers the tree by locating its single `index.md` — no hardcoded path. Idempotent: if a tree already exists, it reports it and never forks a second one. Also writes `settings.json` beside `index.md` — the skillset-version pin and execution preferences. For storage/structure rules it defers to the `continue` base skill.
---

# Setup (project init)

## Overview

`setup` is the **one-time front door** to a project's artifact tree. It decides *where* the tree is
generated and creates the single entry point `index.md` there. The location is a **configurable
default** — `docs/sdlc/` unless the operator picks another name (e.g. `docs/forge/`, `docs/lifecycle/`)
— so a project can place or rename its tree without editing any skill. After setup, the rest of the
system **discovers** the tree by its single `index.md` (per the `continue` base skill's resolve-root
rule), so nothing downstream hardcodes the path.

It owns no phase artifact and defines no structure of its own — the artifact tree, IDs, invariants,
and the minimal-root template are defined by the `continue` base skill. `setup` just performs the
explicit, idempotent scaffold, plus a **light orient** glance — greenfield vs brownfield and the stack
at a glance — recorded only as `index.md` status. It does **not** catalogue the codebase: a persisted
inventory of existing code is the staleness bomb this skillset exists to prevent. Current-state depth
lives where it can't go stale — harvested by reference in `constitution`, read live in `design`.

## When to Use

- **Start of a project,** before `constitution`, to fix where the tree lives and scaffold `index.md`.
- **To place the tree at a non-default location/name** instead of `docs/sdlc/`.

**When NOT to use:**

- A tree already exists — setup is a no-op that reports the existing root (never fork a second tree);
  just run `continue` / the phase you need.
- As a phase or a driver — it neither owns an artifact nor sequences the loop.
- A one-off single-skill task may skip explicit setup; if it's later persisted, the driver's bootstrap
  fallback creates the default `docs/sdlc/` root when `continue` first runs (see the `continue` base
  skill). A standalone non-system skill creates no tree on its own.

## Inputs / Outputs (abstract)

- **Input:** the project, an optional **tree-root name** (default `sdlc`), and optional confirmation of
  the relevant execution prefs (`verifyMode`, `reviewLoops`, `gatePolicy`).
- **Output:** the bootstrapped tree root — a minimal `index.md` (tree map + ID registry + status
  dashboard) and a `settings.json` (version pin + execution prefs) at `docs/<root>/`, with status
  reflecting greenfield vs brownfield (+ stack), ready for the first phase. No other artifact — no code
  inventory. Plus an interactive **next-step hand-off** (step / loop / manual — see Step 6) so the
  operator knows how to drive from here; interactive-only, nothing persisted.

## Process

### 1. Discover any existing tree first (idempotent)

Resolve the tree root per the `continue` base skill (locate the single SDLC `index.md`). If one
already exists, **stop and report its location** — do not create or fork a second tree. The
single-tree invariant holds.

### 2. Orient — greenfield or brownfield (light, read-only)

Glance at the project to set a current-state signal — **detection only, no cataloguing**:

- **Greenfield vs brownfield:** is there existing source beyond scaffolding? Signal from `src/`, a
  manifest (`package.json` / `pyproject.toml` / `go.mod` / `Cargo.toml` …), and non-trivial git history.
- **Stack at a glance:** language/framework, primary entry point(s), whether `CLAUDE.md` / `README`
  exist — only enough to label status and aim the handoff. Stop there; the deep harvest is
  `constitution`'s job and fine-grained current state is `design`'s (read live, per requirement).

Persist none of this beyond the one-line status in Step 3. Writing a code inventory here violates
setup's charter and plants a snapshot that immediately goes stale.

### 3. Determine the tree-root location

If no tree exists, choose the root: `docs/<name>/` with **default `sdlc`** → `docs/sdlc/`. If the
operator supplied or wants a different name, use `docs/<that-name>/`. Confirm the location with the
operator (a light confirmation — this is not a loop gate, just "generate the tree here?").

### 4. Scaffold the minimal root

Create the single entry point `index.md` at the chosen location using the **minimal-root template**
defined by the `continue` base skill (tree map placeholder + empty ID registry + status). Set the
status from Step 2: greenfield → `bootstrapped — no phases run yet`; brownfield →
`bootstrapped (brownfield: <stack>) — no phases run yet`. Initialize `Last synced commit` to the current
`HEAD` (`git rev-parse HEAD`), or `none` if there is no repo/commit yet — just set the value; the
template/field is defined by the base skill. Create no phase artifacts — levels materialize when their
producing phase runs.

### 5. Write `settings.json`

Beside `index.md`, write `docs/<root>/settings.json` using the schema/defaults defined by the `continue`
base skill's *Settings* subsection. Set `version` to `continue`'s `SDLC_SKILLSET_VERSION` (the running
skillset version — this is the pin downstream drivers check) and `treeRoot` to the location chosen in
Step 3. Write the full `execution` block with its defaults, and **lightly confirm only the relevant
prefs in one touch** — `verifyMode` (`test`/`verify`/`both`/`ask`, default `ask`), `reviewLoops`
(adversarial `doubt` passes, default `1`), and `gatePolicy` (`manual`/`milestones`/`auto`, default
`manual` — how much human review the loop requires at phase gates; this is the human-in-the-loop dial),
and `traversal` (`depth-first`/`requirements-first`, default `depth-first` — whether to run each slice
through to `deploy` before the next requirement, or do all requirements-engineering first then implement).
Write `gateOverrides` as `{}`; it is the per-phase escape hatch, edited by hand later, not interrogated.
Do not interrogate the operator for every key; the rest are defaulted and editable by hand later. Never
prompt for `version` — it is taken from the skillset, not the operator.

### 6. Hand off — report, then show what to do next

Report the root path and that the project is bootstrapped. When brownfield, note that `constitution`
should **harvest** existing standing docs and capture existing-system facts as references/constraints.
From here on, the driver discovers this `index.md` automatically and ingests each phase's emitted result
into it.

Then, as the message's **last block**, present the **next-step hand-off** — there are three ways to
drive the project from here, and the operator should not have to guess which. Use the same capability
ladder the driver's gate hand-off uses (`skills/continue/references/presentation.md`): **prefer an
interactive picker** (in Claude Code, `AskUserQuestion`), **fall back to a `── NEXT ──` text footer**
when no picker is available. The options, first = recommended:

1. **Step through it now** — run the next step interactively: `continue` runs the first phase
   (`constitution`) and stops at its gate; repeat `/continue` per step, staying in control. **Selecting
   this proceeds into that first step now.**
2. **Run it as a loop** — from the project root run `skills/continue/loop.sh`. It relaunches `/continue`
   as a **fresh interactive process per step** (context zeroed each step; `index.md` is the carried
   memory) — full TUI, normal permissions, the gate picker all work. You end each step's session when
   it's done and the loop asks whether to continue. It honors `gatePolicy`: the default `manual` presents
   a picker at every gate, so set `auto` or `milestones` in `settings.json` to skip the routine pickers
   (`MAX_STEPS` / `execution.maxSteps` caps the run).
3. **Work with the skills by hand** — invoke a single phase skill directly for a one-off, then run
   `/continue` afterward to persist it into the tree.

Selecting option 1 continues into the first step; options 2 and 3 stop here, having shown the operator
exactly what to run.

## Composability (big↔small)

A full project runs `setup` once, then walks the loop. A tiny one-off can skip it and let the driver's
bootstrap fallback create the default `docs/sdlc/` root the first time `continue` persists a result.
Either way there is exactly one tree with one entry point.

## Red Flags

- Creating a second `index.md` when one already exists (forking the tree) instead of reporting it.
- Hardcoding `docs/sdlc/` as if immutable — it is the **default**, not the only, location.
- Scaffolding artifacts beyond the minimal `index.md` + `settings.json` (the driver writes the rest as
  phases run).
- Writing a current-state / code-inventory artifact in setup — a staleness bomb; setup owns no
  artifact, and existing code is read live by `design`, referenced by `constitution`.
- Turning the orient glance into a deep codebase analysis (that's `constitution` harvest / `design`).
- Redefining the tree structure here instead of deferring to the `continue` base skill.
- Omitting `settings.json`, or prompting for `version` / interrogating the operator for every key —
  `version` comes from the skillset, and only the relevant prefs are lightly confirmed; the rest default.
- Handing off silently — reporting the root but not showing the three ways forward (step / loop / manual)
  — leaving the operator to guess the entry point.

## Verification

- [ ] Discovery ran first; an existing tree was reported, not forked.
- [ ] Orient glance ran read-only; greenfield/brownfield (+ stack) reflected in `index.md` status only.
- [ ] No code inventory / current-state artifact written.
- [ ] Tree root chosen as `docs/<root>/` (default `sdlc`); location confirmed with the operator.
- [ ] A single minimal `index.md` created at the chosen location, with `Last synced commit` initialized
      to current `HEAD` (or `none`) — and no phase artifacts.
- [ ] `settings.json` written beside it: `version` = `SDLC_SKILLSET_VERSION`, `treeRoot` = chosen root,
      full `execution` block defaulted (`gateOverrides` = `{}`); only the relevant prefs lightly confirmed
      (`verifyMode`, `reviewLoops`, `gatePolicy`, `traversal`), `version` not prompted.
- [ ] Structure/template deferred to the `continue` base skill; no duplicated structure definition.
- [ ] Handoff reported the root path so downstream skills discover it by its single `index.md`.
- [ ] Next-step hand-off presented the three paths (step / loop / manual) as the last block — picker or
      `── NEXT ──` footer, with the one-line `loop.sh` explanation.
