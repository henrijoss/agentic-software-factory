---
name: continue
description: The base skill of the SDLC skillset — load it whenever you work within this system. It defines the artifact tree, stable IDs, storage, the tree's structural invariants, gate-validation, and tree-root bootstrap, plus an advisory phase graph. As the sole driver it routes by operator intent (or suggests a next step from `index.md` when none is given), runs the next single step — one phase, or one `implement` task — and stops. Use to resume/continue a project ("where did we leave off", "do the next step") or whenever a phase skill needs the structure and storage rules. To walk the whole loop, the fresh-process loop (`loop.sh`) relaunches it in a fresh interactive session per step.
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
`references/fresh-context.md` covers the fresh-process loop (`loop.sh`) and how the `auto` switch
resolves each step's end-of-step hand-off below.

## Skillset version

```
SDLC_SKILLSET_VERSION = 0.2.0
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
crash or `halt` mid-task; the next step resumes it from `index.md` + the recent git history rather than
skipping it), `done` (implemented and passed its `verify`/`test` acceptance check), or `blocked` (cannot
proceed without a human). This per-task status is **authoritative** for picking the next `implement` task
on a cold read; `index.md`'s **Suggested next** + the last few commits are confirming pointers, not the
source of truth. `to-tasks` registers new tasks as `pending`.

**Optional levels.** Directories materialize only when their producing skill runs. A one-off
`implement` may create just `index.md` + `spec.md` + one task — no `requirements/` layer. The
single-entry-point invariant holds at every size.

**In-place update.** Re-entering a phase overwrites that phase's artifact file; it never forks a
parallel copy. Git history carries the versioning.

**Living specs vs. ephemeral scaffolding.** Two classes of artifact live in the tree.
`constitution.md`, `spec.md`, and each `requirement.md` are **living specs** — durable, updated in
place, never deleted. `design.md` and `tasks/` are **ephemeral working scaffolding**: throwaway files
for building one requirement's slice, **deleted when the slice is finished** (see *Finishing a
requirement* below). The durable record of *why* something was built and which prior approaches to
reuse lives in the **git commits/tree**, not in the scaffolding files — git is the record.

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
  "version": "0.2.0",
  "treeRoot": "docs/sdlc",
  "execution": {
    "maxSteps": 50,
    "auto": false,
    "reviewLoops": 1,
    "commitPerStep": true
  }
}
```

- `version` — the `SDLC_SKILLSET_VERSION` that created or last migrated this tree. Written at init,
  checked by the driver at session start, auto-bumped forward on a safe (same-major, newer) run.
- `treeRoot` — the resolved root path (`docs/<root>`). Confirms — does not replace — discovery, and lets
  `loop.sh`/drivers skip the search.
- `execution.maxSteps` — default step cap for the fresh-process loop (`loop.sh` reads it; the `MAX_STEPS`
  env var still overrides).
- `execution.auto` — the single autonomy switch (default `false`). It governs how much the operator is in
  the loop; see *The `auto` switch* below. It never removes a correctness check (gate-validation, sync,
  version-compat).
- `execution.reviewLoops` — number of adversarial `doubt` passes per non-trivial decision; the driver
  passes it as an input to `design`/`implement`/`review`.
- `execution.commitPerStep` — whether `implement` commits after each task (semantic commit via the
  `commit` skill); default `true`. The driver passes it down to `implement`.

**The `auto` switch (interactive by default).** `auto` is the **single** control over how much the
operator is in the loop — a **system-skill concern** only the driver consults; phase skills never see it
(like every setting). It is overridable **per invocation**: `/continue --auto` forces `auto: true` for
that run regardless of the stored default, and the driver passes the resolved `auto` value **down to any
skill it runs** as a plain input.

- **`auto: false` (default)** — the **interactive hand-off** (AC-5): each `clarify`/`design` step writes
  its artifact, then surfaces critical/related topics and the *Progress to next phase · Continue with a
  topic · Stop here* choice; the driver proposes the next step + alternatives (Step 4) and waits for the
  operator's pick. The operator stays in control step by step.
- **`auto: true`** — skills **skip their end-of-step questions** and the driver **auto-takes the suggested
  next step** (Step 4) without prompting, for unattended runs. The correctness checks still run
  (gate-validation, sync check, version-compat) and still halt/surface on failure — `auto` removes only
  the human prompt, never a check.

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
Last worked: <phase on artifact, e.g. "design on REQ-02" | bootstrapped — no phases run yet>
Suggested next: <the smart next step, e.g. "to-tasks on REQ-02" | specify>
Last synced commit: <sha | none>
```

These three lines are the **cross-step memory** the driver reads when no explicit intent is given (Step
4): **Last worked** is the phase+artifact most recently completed, **Suggested next** is the
context-fitting next step the driver proposes (the operator can always override by intent), and **Last
synced commit** is the git `HEAD` the system last reconciled against (`none` when there is no
repo/commit yet; the sync check maintains it). At bootstrap, **Last worked** reads `bootstrapped — no
phases run yet` (brownfield: `bootstrapped (brownfield: <stack>) — no phases run yet`) and **Suggested
next** points at the first phase. This is a compact signal only — never a code inventory. Together with
the **last few commits** (the `loop.sh` step seeds `git log -5`), it carries the per-slice handoff —
there is no separate handoff file.

## Phase graph (advisory)

An **advisory** map of what *usually* follows what — **not** an enforced sequence and **not** a set of
gates. The driver never marches it; it uses the graph only to *suggest* a likely next step (Step 4),
which the operator can always override by intent. The usual order, closed by `maintain → specify`:

```
constitution → specify → to-requirements → clarify → design → to-tasks → implement
             → verify/test → review → deploy → maintain → (specify, next slice)
```

- **Postures are not nodes.** `interview`, `doubt`, `incremental` are invoked *inside* phases, never
  scheduled by a driver.
- **`verify`/`test` is opt-in** — suggested only when there is observable behavior to confirm; the
  operator picks TDD (`test`), run-and-observe (`verify`), both, or skips it. Never a mandatory step.
- **`deploy`/`maintain` are opt-in** — suggested only when a deployment/release/operation actually
  exists; never mandatory mainline steps.
- **Transition skills (`to-requirements`, `to-tasks`) fan out** a set for the operator to review.

The arrows are advisory, not gates. The "what usually follows next" reference and entry modes (full /
sub-chain / resume / intent / single) live in `references/phase-graph.md`.

## Process (default: run the next single step)

### 1. Resolve the tree root, read settings, check the version

Locate the tree per "Resolve the tree root" above (discover the single `index.md`). If none exists,
run `setup` — or, as a fallback, create the default `docs/sdlc/` root idempotently **and** write a
default `settings.json` beside it (current `SDLC_SKILLSET_VERSION`, `treeRoot` = the resolved root,
default `execution`). Never overwrite an existing `settings.json`.

Then read `settings.json` and run the **version-compat check** — compare its `version` (recorded `S`)
against `SDLC_SKILLSET_VERSION` (running `R`), as `major.minor.patch`:

- **`R.major != S.major`** → **halt**: incompatible tree structure; require an explicit
  migration/override decision before any phase runs — this halt always stops for the human, even under `auto`.
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

### 4. Determine the next step (intent router + suggester)

The driver is an **intent router with a smart suggester** — it never marches a fixed sequence.

**With explicit intent.** When the operator names what to do (e.g. "refine REQ-2's design",
"re-clarify REQ-1", "implement the next task on REQ-3"), route **directly** to that phase on that
artifact and update it **in place** — no intervening forced graph step, no precondition phase inserted.
Resolve the named artifact to its `[REQ-n]`/ID through `index.md`, assemble that phase's inputs (Step 5),
and run it. A bare one-off skill request likewise defers to that phase skill directly.

**With no explicit intent.** Read `index.md`'s **Last worked** + **Suggested next** — the cross-step
memory of where things stand. **Propose** the suggested step plus **1–2 alternatives** (e.g. the
advisory next phase from the phase graph, or another open `[REQ-n]`) and let the operator pick. The
driver **never auto-takes** a fixed sequence here — the proposal is advisory. (Under `auto` — see
Settings — the driver skips this prompt and takes the suggested step automatically.)

Derive the suggestion from the **advisory** phase graph plus each artifact's current state.
`deploy`, `maintain`, and `verify`/`test` are **opt-in**: suggest them **only when applicable** — a
deployment/release exists (`deploy`/`maintain`), or there is observable behavior to confirm
(`verify`/`test`) — never as mandatory mainline steps. When several `[REQ-n]` are open, prefer not to
abandon a slice already mid-`implement`, but the operator's pick always wins.

**Inside `implement`, a step is one task.** When the chosen slice `[REQ-n]` is in the `implement` phase,
the next step is **one task**: the lowest-ordered `[REQ-n.TASK-m]` that is not `done` and whose
dependency-graph prerequisites (from `to-tasks`) are all `done`. When **all** of the slice's tasks are
`done`, suggest the **`verify`/`test`** node (opt-in). When the next runnable task is `blocked` or every
remaining task has an unmet dependency, halt for a human. This per-task granularity is what gives each
task a fresh session under the `loop.sh` loop.

**No next step.** If the project has nothing left to run, say so and stop — never invent work.

### 5. Assemble inputs, then run exactly one phase

**Assemble** the phase's inputs from the tree (`[CONST]`, the prior artifact on re-entry, the chosen
`[REQ-n]`, …) per the consumed-by mapping in `references/handoff.md`, and pass them as provided content.
For `design`/`implement`/`review`, also pass `settings.execution.reviewLoops` as a plain input (the
adversarial `doubt`-pass count) — the phase honors it without ever reading `settings.json`.
Then load and run that one phase skill. It is a pure transform: it does its work (invoking postures as
needed), and **emits its result** — an in-context result block (phase skills) or `.sdlc/scratch/` files
(`to-*` skills). It does **not** touch the tree, `index.md`, or IDs. Do not pre-empt the phase's logic.

### 6. Ingest the result, then stop

**Ingest** per `references/handoff.md`: capture the emitted result → resolve/assign the stable ID →
write to the tree path (artifact-io), updating **in place** on re-entry (never fork) → register/update
`index.md` → clear `.sdlc/scratch/`. For an `implement` step, ingest also updates the just-finished
**task's status** in `index.md` (`done`, or `blocked`). For a `to-tasks` step, the requirement's status
becomes `tasks ready`. Run **gate-validation** (dangling / duplicate / orphan / unreachable → fail and
surface) — a correctness check that runs on **every** step regardless of `auto`. **Stop** — the session
ends after one step. The operator runs `continue` again, or the `loop.sh` loop relaunches it in a fresh
session. Advancing across steps is the external loop's job, never an in-session walk.

**On a successful ingest** (artifact written, `index.md` updated, gate-validation passed) emit a **saved
confirmation** — the artifact(s) by `<ID> → <path>` plus `index.md`, and a "Safe to clear or close —
`index.md` holds the state; resume with /continue" line — so the operator knows the tree is persisted and
the session is disposable. Only claim "saved" **after** gate-validation passes; on failure surface the
failure instead.

**End-of-step hand-off — `auto: false` (default).** After the saved confirmation, **hand the decision to
the operator** as the **last** thing in the message: the interactive end-of-step hand-off defined in
`references/presentation.md` (AC-5) — surface critical/related topics, then the *Progress to next phase ·
Continue with a topic · Stop here* choice — preferring an interactive selection picker (in Claude Code,
`AskUserQuestion`) over a typed guess. The phase skills (`clarify`/`design`) own their own end-of-step
questions; `continue` proposes the next step + alternatives (Step 4) and relays the choice.

**End-of-step hand-off — `auto: true`.** Skip the questions entirely; the next fresh session auto-takes
the suggested next step (Step 4). The saved confirmation is still emitted — only the human prompt is
skipped. The correctness checks (version-compat, sync check, gate-validation) still run and still
halt/surface on failure; `auto` never skips them.

**A finished `implement` task that is not the last one** is simply followed by the next task — there is
no decision to pose; the next fresh session picks it up, leaving the next task `pending`/`in-progress`.
Only when **all** of a slice's tasks are `done` does it reach the **opt-in** `verify`/`test` step. The
`loop.sh` loop sequences steps (`references/fresh-context.md`); it writes no control file.

## Finishing a requirement (ephemeral cleanup)

The ephemeral scaffolding (`design.md`, `tasks/`) is removed once a requirement's slice is **finished**
— git becomes its sole record. Only the driver does this.

**"Finished" is defined explicitly.** A requirement is finished when **both** hold:

1. its implementation work is **committed** (the slice's tasks are `done` and their code is on `main`), and
2. the operator — or, under `auto`, the driver — **confirms no further work is queued** on it (no
   remaining tasks, no pending re-design/re-clarify).

Until both hold, the scaffolding stays. Reaching "all tasks `done`" alone does **not** finish a
requirement — the operator may still want to re-clarify or re-design it (living specs, AC-3). The
finish is an explicit confirmation, posed at the end-of-step hand-off (or auto-taken under `auto`).

**Cleanup, when a requirement is confirmed finished:**

- **Delete** `requirements/REQ-n/design.md` and the whole `requirements/REQ-n/tasks/` directory from
  the working tree.
- **Remove their IDs** (`[REQ-n.DESIGN]`, every `[REQ-n.TASK-m]`) from `index.md` — both the **ID
  registry** rows and the **tree map**.
- **Keep** `requirements/REQ-n/requirement.md` and its `[REQ-n]` entry — the living spec is durable and
  never deleted.
- Run **gate-validation** afterward: with the design/task IDs gone, no registry row may dangle and no
  artifact may be left orphaned/unreachable.

The deletion is recoverable from git at any time (`git log -- <path>` / `git show <sha>:<path>`); see
`references/artifact-io.md`. The cleanup itself is a normal tree edit committed like any other step.

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
- A "looks good?" hand-off with nothing to decide.
- Under `auto: false`, burying the hand-off above other content instead of as the message's final block,
  or explaining the choice in prose and stopping when an interactive picker was available — the hand-off
  should be a pick, not a typed guess (`references/presentation.md`).
- Claiming "saved / safe to clear" before ingest + gate-validation actually completed, or omitting the
  saved confirmation entirely so the operator can't tell the tree was written and the session is
  disposable.
- Skipping gate-validation, letting a stale/broken tree propagate.
- Skipping the sync check, or treating the equality test as a correctness gate instead of examining the
  `recorded..HEAD` diff to reconcile.
- Blocking a phase when there is no git repo/`HEAD` — the sync check degrades to no-drift, never blocks.
- Letting `auto: true` skip a **correctness check** (gate-validation, sync reconciliation, or the
  version-compat halt) — `auto` removes only the human prompt, never a check; these still halt/surface.
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
- [ ] Settings applied by the driver only: `reviewLoops` passed as a phase input, `commitPerStep` and the
      resolved `auto` value passed down — no phase skill read `settings.json`.
- [ ] `auto` honored: `auto: false` ran the interactive end-of-step hand-off; `auto: true` (or
      `/continue --auto`) skipped the questions and auto-took the suggested next step — and the
      correctness checks (gate-validation, sync, version-compat) still ran and halted on failure regardless.
- [ ] Status read; the single next step chosen by intent or the advisory suggestion — one phase, or,
      inside `implement`, the next non-`done` task whose dependencies are met (or one-off).
- [ ] Sync check run; any drift (`HEAD` != recorded) surfaced and reconciled, then
      `Last synced commit` updated to `HEAD` (or `none` when git is absent).
- [ ] Phase inputs **assembled** from the tree and passed as content; the phase emitted a result
      (in-context block, or `.sdlc/scratch/` for `to-*`) without touching the tree itself.
- [ ] Exactly **one** step run — one phase, or one `implement` task — then stopped; the session ended
      with no in-session advance to the next step.
- [ ] Result **ingested**: ID resolved, written to the tree, `index.md` registered/updated,
      `.sdlc/scratch/` cleared; for an `implement` step, the finished task's status set to `done`/`blocked`.
- [ ] Gate-validation run; under `auto: false` the step's real decision posed via the interactive
      hand-off, under `auto: true` it ended on the saved confirmation with no prompt.
- [ ] Re-entry updated artifacts in place — no duplicate fork.
- [ ] The step resumed from `index.md` and ended by writing its result back — self-contained, so the
      next step can start from a fresh context.
