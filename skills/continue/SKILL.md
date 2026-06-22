---
name: continue
description: The base skill of the SDLC skillset — load it whenever you work within this system. It defines the artifact tree, stable IDs, storage, the tree's structural invariants, gate-validation, and tree-root bootstrap, plus the canonical phase graph. As the sole driver it reads where the project left off from `index.md`, runs the next single step — one phase, or one `implement` task — and stops at its gate. Use to resume/continue a project ("where did we leave off", "do the next step") or whenever a phase skill needs the structure and storage rules. To walk the whole loop, the fresh-process loop (`loop.sh`) relaunches it in a fresh interactive session per step.
---

# Continue (base skill)

## Overview

`continue` is the **foundation of the SDLC skillset**. Any work within this system loads it first: it
is the single place that defines *how artifacts are stored and structured* and *how the loop is
sequenced*. It is also the **sole driver** — it reads `index.md` to see where the project stands,
runs the **next single step** (one phase, or one `implement` task), and stops at that step's human gate.
The operator stays in control step by step. There is no in-session multi-step driver: to walk the whole
loop, the fresh-process loop (`loop.sh`, see `references/fresh-context.md`) relaunches this skill in a
brand-new interactive session for each step, so context is zeroed between steps instead of growing.

Every other skill is a **pure, system-agnostic transform** — it knows nothing of the tree, `index.md`,
IDs, storage, or chaining; it takes the inputs the driver provides and **emits a result** (the result
contract). This skill does everything system-shaped around it: it **assembles** a phase's inputs from
the tree before, and **ingests** the emitted result into the tree after — `continue` is the only actor
that reads/writes the tree, `index.md`, and IDs. Depth (the result contract, ingest and input-assembly
in `references/handoff.md`; the full storage-binding table and optional GitHub edge integrations; the
entry modes and worked example; the **fresh-context step loop** in `references/fresh-context.md`) lives
in `references/` and is loaded on demand.

Each step is **self-contained**: it resumes from `index.md` and ends by writing its result back to the
tree. The conversation is disposable — once a step is ingested, `index.md` holds everything the next
step needs, so the next step can (and for long looped runs, should) start from a **completely
fresh context**. A step is one phase, except in `implement`, where each step is a **single task** — so a
slice's `implement` phase spans as many steps as it has tasks, each a fresh session.
`references/fresh-context.md` covers the fresh-process loop (`loop.sh`) and how `gatePolicy` resolves
each gate in-session below.

## Skillset version

```
SDLC_SKILLSET_VERSION = 0.1.0
```

This is the **single source of truth** for the running skillset's version — the version of the
artifact-tree *contract* this skillset defines. It lives here because `continue` is the definer of that
contract, and the other system skill (`setup`) loads/defers to it for structure. Bumping the skillset =
editing this one line (semver: `major.minor.patch`). A project records the
version it was created/migrated with in its `settings.json` (below); the driver compares the two at
session start (see the **version-compat check** in Process).

## When to Use

- **Resume:** continue a project from where `index.md`'s status dashboard left off — run the next step.
- **Single step:** advance the project by exactly one step (one phase, or one `implement` task), then
  stop at its gate.
- **Structure/storage reference:** any time a phase needs the artifact tree, IDs, paths, bootstrap, or
  gate-validation rules.

**When NOT to use:**

- As a phase itself — it owns no phase artifact; it sequences phases and defines the structure.

For a looped run across many steps, you still use `continue` — the fresh-process loop (`loop.sh`) just
relaunches it interactively per step. There is no separate full-loop driver.

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

**Per-task status (drives the `implement` step loop).** Each `[REQ-n.TASK-m]` registry row carries a
lifecycle status — `pending` (not started), `in-progress` (claimed by a step that didn't finish — e.g. a
crash or `halt` mid-task; the next step resumes it from the SessionSummary rather than skipping it),
`done` (implemented and passed its `verify`/`test` acceptance check), or `blocked` (cannot proceed
without a human). This per-task status is **authoritative** for picking the next `implement` task on a
cold read; the SessionSummary's **Next** is a confirming pointer, not the source of truth. `to-tasks`
registers new tasks as `pending`.

**Optional levels.** Directories materialize only when their producing skill runs. A one-off
`implement` may create just `index.md` + `spec.md` + one task — no `requirements/` layer. The
single-entry-point invariant holds at every size.

**In-place update.** Re-entering a phase overwrites that phase's artifact file; it never forks a
parallel copy. Git history carries the versioning.

The full storage-binding table (abstract artifact → read/write op) and the **optional GitHub edge
integrations** (`maintain` inbound, optional one-way mirror — not a backend) live in
`references/artifact-io.md`.

### Settings (`settings.json` — a system file beside `index.md`)

A single `settings.json` sits **next to `index.md`** at `docs/<root>/settings.json`, versioned with the
tree. It pins the skillset version the tree was created/migrated with and holds tweakable execution
preferences. It is a **system file**, not an abstract artifact: **only the system skills (`setup`,
`continue`) read or write it.** Phase skills never see it — anything that must influence
a phase is passed to it as a plain input by the driver (see `references/handoff.md`).

```json
{
  "version": "0.1.0",
  "treeRoot": "docs/sdlc",
  "execution": {
    "maxSteps": 50,
    "verifyMode": "ask",
    "reviewLoops": 1,
    "gatePolicy": "manual",
    "gateOverrides": {},
    "traversal": "depth-first"
  }
}
```

- `version` — the `SDLC_SKILLSET_VERSION` that created or last migrated this tree. Written at init,
  checked by the driver at session start, auto-bumped forward on a safe (same-major, newer) run.
- `treeRoot` — the resolved root path (`docs/<root>`). Confirms — does not replace — discovery, and lets
  `loop.sh`/drivers skip the search.
- `execution.maxSteps` — default step cap for the fresh-process loop (`loop.sh` reads it; the `MAX_STEPS`
  env var still overrides).
- `execution.verifyMode` — `test | verify | both | ask`; the default for the `verify`/`test` node so the
  driver needn't ask each slice (`ask` = prompt as before).
- `execution.reviewLoops` — number of adversarial `doubt` passes per non-trivial decision; the driver
  passes it as an input to `design`/`implement`/`review`.
- `execution.gatePolicy` — `manual | milestones | auto`; how much human review the loop requires at
  phase-transition gates (default `manual` — autonomy is opt-in). It governs only whether the **driver
  pauses for a human** at a gate; it never removes a gate or its validation (see below).
- `execution.gateOverrides` — an object mapping a **just-completed phase name** → `pause | auto`,
  overriding `gatePolicy` for that one gate (e.g. `{"design": "pause", "review": "pause"}`). Default
  `{}`. (`verify`/`test` share the key `verify`.)
- `execution.traversal` — `depth-first | requirements-first` (default `depth-first`); the order the
  loop walks requirements through the graph. `depth-first` runs one slice all the way to `deploy`
  before touching the next requirement (the original behavior). `requirements-first` does the
  requirements-engineering (`clarify` → `design` → `to-tasks`) for **every** draft requirement before
  implementing any, then drains `implement` in `to-requirements` priority order. It governs only the
  advance *target* at the `to-tasks → implement` gate (see *Gate autonomy* and Step 4) — it never adds,
  removes, or relaxes a gate.

**Gate autonomy (how `gatePolicy`/`gateOverrides` are applied).** This is a **system-skill concern** —
only the driver consults it; phase skills never see it (like every other setting). At each gate the
driver resolves *pause vs. advance* by this precedence:

1. **Safety floor first — always pause, ignoring policy and overrides:** `deploy` or any
   outward/irreversible action (ship authorization); a held **sync gate** (external drift); **failed
   gate-validation** (dangling/duplicate/orphan/unreachable); an **ambiguous** next phase; a **major**
   version mismatch. Autonomy can never skip these.
2. Else if `gateOverrides[<phase>]` is set → use it (`pause` or `auto`).
3. Else apply `gatePolicy`: `manual` → pause; `auto` → advance; `milestones` → pause iff the phase is a
   **milestone gate** (`constitution`, `specify`, `design`, `review` — the direction-defining,
   costly-to-reverse decisions), else advance.

`continue` always runs **interactively**, so this resolution decides only whether a gate **presents its
decision picker** before the step ends: a resolved **pause** poses the gate's specific decision to the
operator (the picker, or the `── NEXT ──` text footer); a resolved **advance** skips the picker, records
the gate outcome, and ends the step on the saved confirmation alone. Every step ends after one phase
either way — sequencing the next step is the `loop.sh` loop's job (which prompts the operator between
steps), never an in-session walk. The gate and its **gate-validation still run on every transition**;
`gatePolicy` only relaxes the *human prompt* at a *routine* gate.

**`gatePolicy` and `traversal` are orthogonal.** `gatePolicy` resolves *pause vs. advance*; `traversal`
(`execution.traversal`) only chooses, **once a gate has resolved to advance**, the advance *target* —
and only at the `to-tasks → implement` gate. `depth-first` advances to `implement`; `requirements-first`,
when a draft requirement still remains, instead marks the just-tasked requirement deferred and re-enters
`clarify` on the next draft (Step 4). A non-HITL (auto-advancing) `to-tasks` gate therefore always
progresses straight to `implement` under the default `depth-first`; deferral is the opt-in, whether by
the interactive picker or by setting `requirements-first`.

**Forward-compatible:** unknown keys are ignored and any missing key falls back to the default above, so
new settings can be added without breaking older trees. `setup` writes the full file with defaults and
only lightly confirms the relevant prefs; everything else is edited by hand later.

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
  `setup` and the `continue` driver ever create the tree — standalone non-system skills create none.

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

The canonical sequencing source — the loop the driver walks. Linear spine, closed by
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

### 1. Resolve the tree root, read settings, check the version

Locate the tree per "Resolve the tree root" above (discover the single `index.md`). If none exists,
run `setup` — or, as a fallback, create the default `docs/sdlc/` root idempotently **and** write a
default `settings.json` beside it (current `SDLC_SKILLSET_VERSION`, `treeRoot` = the resolved root,
default `execution`). Never overwrite an existing `settings.json`.

Then read `settings.json` and run the **version-compat check** — compare its `version` (recorded `S`)
against `SDLC_SKILLSET_VERSION` (running `R`), as `major.minor.patch`:

- **`R.major != S.major`** → **halt**: incompatible tree structure; require an explicit
  migration/override decision before any phase runs (a safety-floor gate — always pauses for the human).
- **same major, `R > S`** (running newer) → proceed, and **bump** `settings.version` to `R` (record the
  forward migration).
- **same major, `R < S`** (running older than the tree) → **warn** and proceed (same major = compatible
  structure; surface that the tree was last touched by a newer skillset).
- **`R == S`** → proceed.

Honor `treeRoot` from settings to confirm the discovered root. A missing/unparseable `settings.json` on
an existing tree is treated as "unknown version" — write a fresh default (recording `R`) rather than
blocking. Any missing key falls back to its default.

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

### 4. Determine the next step

From the status dashboard + the phase graph, pick the **single** next step. If a single one-off skill
was requested, defer to that phase skill directly. When the next step isn't unambiguous, confirm with
the user rather than guessing (see entry modes in `references/phase-graph.md`). At the **`verify`/`test`
node**, use `settings.execution.verifyMode` to pick `test` / `verify` / both without asking — unless it
is `ask` (prompt as usual).

**Which requirement is next (traversal).** With several `[REQ-n]` at different phases, pick the
requirement to act on by walking them in **`to-requirements` priority order** through these passes (the
first pass that matches wins):

1. **A slice with `implement` already in progress** (any `[REQ-n.TASK-m]` is `in-progress`) → finish
   that slice's `implement`. Never abandon a started slice mid-implement.
2. **A requirement whose tasks are ready and *not* deferred** (status `tasks ready`) → `implement` it.
   This is `depth-first`: a just-tasked, approved requirement implements before the next is clarified.
3. **Else a requirement still in prep** (draft → `clarify`; clarified-not-designed → `design`;
   designed-not-tasked → `to-tasks`) → run its next prep phase. This is where a **deferred** requirement
   steps aside so the next draft gets clarified.
4. **Else a requirement deferred at its `to-tasks` gate** (status `tasks ready · deferred`) → `implement`
   it. The `requirements-first` tail: all prep done, drain implementation in priority order.

The `tasks ready · deferred` marker (set at the `to-tasks → implement` gate — see Step 6) is what lets
the *same* tree state resolve to either `implement` now (`depth-first`) or `clarify` next
(`requirements-first`); the choice is persisted in `index.md`, not re-derived. Per-gate choices win
*within* a pass — if `REQ-01` is deferred but `REQ-02` was approved, pass 2 implements `REQ-02`.

**Inside `implement`, a step is one task.** When the chosen slice `[REQ-n]` is in the `implement` phase,
the next step is **one task**, not the whole phase: pick the lowest-ordered `[REQ-n.TASK-m]` that is not
`done` and whose dependency-graph prerequisites (from `to-tasks`) are all `done`, and run `implement` on
**that one task**. When **all** of the slice's tasks are `done`, the next step is the **`verify`/`test`
node** (the implement→verify gate). When the next runnable task is `blocked` or every remaining task has
an unmet dependency, that is a safety-floor **halt** for a human. This per-task granularity is what gives
each task a fresh session under the `loop.sh` loop.

**No next step.** If the project has nothing left to run — all slices complete through their terminal
phase and no queued maintenance — there is no step to take. In an interactive run say so and stop; in a
**headless** run (below) emit the completion sentinel `<sdlc-done>COMPLETE</sdlc-done>` rather than
inventing work, so the loop exits cleanly.

### 5. Assemble inputs, then run exactly one phase

**Assemble** the phase's inputs from the tree (`[CONST]`, the prior artifact on re-entry, the chosen
`[REQ-n]`, …) per the consumed-by mapping in `references/handoff.md`, and pass them as provided content.
For `design`/`implement`/`review`, also pass `settings.execution.reviewLoops` as a plain input (the
adversarial `doubt`-pass count) — the phase honors it without ever reading `settings.json`.
Then load and run that one phase skill. It is a pure transform: it does its work (invoking postures as
needed), and **emits its result** — an in-context result block (phase skills) or `.sdlc/scratch/` files
(`to-*` skills). It does **not** touch the tree, `index.md`, or IDs. Do not pre-empt the phase's logic.

### 6. Ingest the result, hold the gate, then stop

**Ingest** per `references/handoff.md`: capture the emitted result → resolve/assign the stable ID →
write to the tree path (artifact-io), updating **in place** on re-entry (never fork) → register/update
`index.md` → clear `.sdlc/scratch/`. For an `implement` step, ingest also updates the just-finished
**task's status** in `index.md` (`done`, or `blocked`) alongside the SessionSummary it wrote. For a
`to-tasks` step, the requirement's status becomes `tasks ready`, or `tasks ready · deferred` when the
gate resolves to defer implement (the **Clarify next requirement** pick, or `traversal:
requirements-first` while a draft requirement still remains). Run
**gate-validation** (dangling / duplicate / orphan / unreachable → fail and surface). Resolve the gate
via the **gate-autonomy precedence** above: at a **pause** gate, present the step's specific decision to
the operator (never "looks good?"); at an **advance** gate, skip the picker and end on the saved
confirmation. **Stop** — the session ends here either way. The operator runs `continue` again for the
next step, or the `loop.sh` loop relaunches it in a fresh session and prompts whether to go on.
Advancing across steps is the external loop's job, never an in-session walk.

**A finished `implement` task that is not the last one is not a gate.** When tasks remain in the slice,
there is no phase transition yet — the next step is simply the next task. Do **not** consult `gatePolicy`
(it governs phase-transition gates); just stop, leaving the next task `pending`/`in-progress` for the
following fresh session. Only the **last** task completing reaches the implement→verify gate, which then
resolves via the gate-autonomy precedence like any other transition.

**Interactive framing (presentation contract).** Every step is interactive — frame the output per
`references/presentation.md`: at phase entry emit a **phase-start banner** (`━━━ PHASE N/11 · <phase> ━━━`
+ the `[REQ-n]`/`[TASK-m]` it operates on) followed once by the **vertical phase map** (✓ done · ▶
current · pending); at a **pause** gate emit a **`── <phase> complete · GATE ──`** block carrying this
gate's specific decision question (at an **advance** gate the saved confirmation is the final block — no
gate block, no picker). On a **successful ingest** (artifact written, `index.md` updated,
gate-validation passed) emit a **saved confirmation** — the artifact(s) by `<ID> → <path>` plus
`index.md`, and a "Safe to clear or close — `index.md` holds the state; resume with /continue" line — so
the operator knows the tree is persisted and the session is disposable. Only claim "saved" **after**
gate-validation passes; on failure surface the failure instead. At a **pause** gate, **hand the decision
to the operator** as the **last** thing in the message. Prefer an **interactive selection picker** (the
harness's question tool — in Claude Code,
`AskUserQuestion`) so it is unmistakably their turn: Approve / Request changes (with a note for what to
change) / Stop, or the gate's variant (verify/test → test/verify/both/Skip; deploy → Authorize ship/Hold;
fan-out → Approve/Re-slice/Edit set). At the **`to-tasks → implement` gate**, when a draft
(un-prepared) requirement still remains, the fan-out picker also offers **Clarify next requirement** —
accept this task set but defer `implement` and re-enter `clarify` on the next draft requirement (the
affirmative option under `requirements-first`, otherwise after Approve). If no picker is available, fall
back to the **`── NEXT ──`** text footer with the same options. Banners/maps appear once per phase, never
mid-phase. The reference holds the literal templates, the picker option sets, and the narrow-terminal
degradation ladder.

**Gate resolution (pause vs. advance).** After ingest + gate-validation, resolve the gate via the
**gate-autonomy precedence** above. A resolved **pause** presents the decision (picker / `── NEXT ──`
footer) and the step ends on the operator's choice; a resolved **advance** skips the picker, ends on the
saved confirmation, and the next fresh session simply moves on. The **safety floor always pauses** — an
ambiguous next step, a held **sync gate** (external drift), `deploy` or any outward/irreversible
authorization, failed gate-validation, a major version mismatch, or a decision the phase would otherwise
have to guess. A finished `implement` task with **more tasks remaining** is not a gate — end the step
and let the next fresh session pick the next task (only the safety floor can interrupt). At a
`to-tasks → implement` gate that resolves to **advance**, `execution.traversal` picks the target:
`depth-first` proceeds to implement this slice next; `requirements-first` marks the requirement
`tasks ready · deferred` so the next session, finding no non-deferred ready slice, clarifies the next
draft requirement (Step 4), and once no draft remains drains `implement` in priority order. The deferral
lives in the persisted status. This is how the human-gate-on-every-transition rule holds while
`gatePolicy` tunes which routine gates still pause. The `loop.sh` loop sequences steps and prompts the
operator between them (`references/fresh-context.md`); it writes no control file.

**Headless (no interactive picker).** Under `loop.sh --headless` each step runs `claude -p`, which has no
picker, so the hand-off degrades to a **text sentinel** on the step's last line (the contract and table
live in `references/fresh-context.md`): an **advance** gate ends on the saved confirmation as usual; a
**pause** or **safety-floor** gate emits `<sdlc-gate>PAUSE: <reason></sdlc-gate>` and stops for the human
instead of presenting the picker; and when Step 4 finds no next step the driver emits
`<sdlc-done>COMPLETE</sdlc-done>`. Headless assumes `gatePolicy: auto` so only the safety floor (and any
`pause` override) interrupts an otherwise unattended run.

## Composability (big↔small)

A typo just runs `implement`. A single requirement enters at `design`. A whole product walks the loop
one `continue` step at a time — by hand, or via the `loop.sh` fresh-process loop that relaunches
`continue` interactively per step. Only the phases and tree levels a job needs ever materialize.

## Red Flags

- Auto-advancing past a gate within one session, or looping over multiple steps in a single session to
  "keep going" — `continue` runs one step (one phase, or one `implement` task) and stops; the `loop.sh`
  fresh-process loop is what advances across steps, each in a new session.
- Letting a phase skill write into the tree/`index.md`/IDs instead of emitting a result the driver
  ingests, or skipping input-assembly so the phase has to discover the tree itself.
- Running a phase with no `index.md` entry point, or assuming `docs/sdlc/` instead of resolving the
  root by discovery.
- Forking a duplicate artifact on re-entry instead of updating in place.
- A "looks good?" gate with nothing to decide.
- Emitting the gate block / picker / `NEXT` footer at an **advance** gate (it skips the picker and ends
  on the saved confirmation), or burying the hand-off above other content instead of as the message's
  final block.
- Claiming "saved / safe to clear" before ingest + gate-validation actually completed, or omitting the
  saved confirmation entirely so the operator can't tell the tree was written and the session is
  disposable. Explaining the gate in prose and stopping when an interactive picker was
  available — the hand-off should be a pick (or its text-footer fallback), not a typed guess
  (`references/presentation.md`).
- Skipping gate-validation, letting a stale/broken tree propagate.
- Skipping the sync check, or treating the equality test as a correctness gate instead of examining the
  `recorded..HEAD` diff to reconcile.
- Blocking a phase when there is no git repo/`HEAD` — the sync check degrades to no-drift, never blocks.
- Auto-advancing (skipping the picker at) a **safety-floor** gate because `gatePolicy` is
  `auto`/`milestones` (or a `gateOverrides` entry says `auto`) — the floor (`deploy`/irreversible, sync
  drift, failed validation, ambiguous phase, major version mismatch) always pauses, policy
  notwithstanding. When in doubt, pause.
- Treating `gatePolicy` as a license to **skip a gate or its gate-validation** — it only relaxes the
  *human prompt* at a routine gate; the gate and its validation still run on every transition.
- Deferring `implement` to clarify the next requirement under `depth-first` (deferral is opt-in:
  the interactive **Clarify next requirement** pick, or `traversal: requirements-first`), or abandoning a
  slice with `implement` **in progress** to chase requirements-first — an in-progress slice finishes
  first (Step 4, pass 1).
- Carrying one step's working-context into the next instead of resuming cold from `index.md` — the
  ever-growing-session failure mode at step granularity.
- Running a phase without the version-compat check, or auto-advancing past a **major** version mismatch
  instead of halting for a migration/override decision.
- Letting a phase skill read `settings.json` directly instead of receiving settings-derived values as
  provided inputs — only `setup`/`continue` touch the file.

## Verification

- [ ] Tree root resolved by discovering the single `index.md` (or `setup`/fallback ran) before any
      phase — no hardcoded `docs/sdlc/` assumption; `settings.json` read (or default-written on
      fallback) and the version-compat check run before any phase — major mismatch halted, same-major
      newer bumped the recorded version.
- [ ] Settings applied by the driver only: `verifyMode` chose the verify/test node, `reviewLoops` passed
      as a phase input, `gatePolicy`/`gateOverrides` resolved each gate's pause-vs-advance — no phase
      skill read `settings.json`.
- [ ] Gate autonomy honored the precedence (safety floor → `gateOverrides` → `gatePolicy`): the safety
      floor still paused (presented its picker) under every policy; only routine gates auto-advanced.
- [ ] Status dashboard read; the single next step chosen from the phase graph — one phase, or, inside
      `implement`, the next non-`done` task whose dependencies are met (or one-off deferred).
- [ ] `traversal` honored at the `to-tasks → implement` gate: `depth-first` advanced to `implement`;
      `requirements-first` (or an interactive **Clarify next requirement** pick) marked the requirement
      `tasks ready · deferred` and clarified the next draft, draining deferred slices in priority order
      only once no prep remained — and a slice already mid-`implement` finished first.
- [ ] Sync check run; any drift (`HEAD` != recorded) surfaced at the sync gate and reconciled, then
      `Last synced commit` updated to `HEAD` (or `none` when git is absent).
- [ ] Phase inputs **assembled** from the tree and passed as content; the phase emitted a result
      (in-context block, or `.sdlc/scratch/` for `to-*`) without touching the tree itself.
- [ ] Exactly **one** step run — one phase, or one `implement` task — then stopped; the session ended
      with no in-session advance to the next step.
- [ ] Result **ingested**: ID resolved, written to the tree, `index.md` registered/updated,
      `.sdlc/scratch/` cleared; for an `implement` step, the finished task's status set to `done`/`blocked`.
- [ ] Gate-validation run; at a pause gate the phase's real decision posed (picker / `NEXT` footer); at
      an advance gate the picker skipped and the step ended on the saved confirmation — any gate owing a
      human decision (safety floor) paused regardless of policy.
- [ ] Re-entry updated artifacts in place — no duplicate fork.
- [ ] The step resumed from `index.md` and ended by writing its result back — self-contained, so the
      next step can start from a fresh context.
