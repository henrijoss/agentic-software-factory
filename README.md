# agentic-software-factory

A composable **SDLC agent skillset**: small, single-purpose [Claude Code skills](skills/) that cover
every phase of the software lifecycle and chain together through **human gates**, driven by the thin
`continue` base skill — one step per session, with a fresh-process loop script that relaunches it
interactively per step.

## What it is

- **Composable, big↔small.** Assemble only the skills (and artifact-tree levels) a job needs. A typo
  runs `implement` alone; a product runs the whole loop. No phase is mandatory.
- **Iterative, not waterfall.** The unit of iteration is one **vertical slice / use-case**; the loop is
  a cycle closed by `maintain → specify`. By default each slice runs through to `deploy` before the
  next (`traversal: depth-first`); `requirements-first` instead does the requirements-engineering for
  every requirement up front, then implements in priority order.
- **Anti-staleness by in-place update.** Re-entering a phase overwrites *that phase's* artifact — one
  source of truth, so spec and code cannot silently diverge. A **drift sync** against git
  (`index.md` records the last reconciled commit) catches code committed outside the system between
  sessions.
- **A human gate on every transition — as much or as little as you want.** Each gate surfaces a real
  decision, never "looks good?". How many stop for a human is set by `gatePolicy` (`manual` =
  every gate, default; `milestones` = the big ones; `auto` = skip the routine pickers); the safety gates
  (deploy/irreversible, sync drift, failed validation) always stop regardless.
- **Fresh context per step, pure standalone skills.** Only `setup` and the `continue` base skill (the
  sole driver) know the tree/IDs/storage/chaining; every other skill is a **pure transform** that takes
  provided inputs and emits a result, so each is directly invocable on its own. The driver runs one
  step from `index.md` and stops — so the conversation is disposable and context never grows across
  steps (see [Getting started](#getting-started)).

## Getting started

Install the skills where Claude Code finds them (copy `skills/` into `~/.claude/skills/`, or symlink
this repo), then from your project root:

1. **`setup`** — one-time. Scaffolds the artifact tree root: a single `index.md` at `docs/<root>/`
   (default `docs/sdlc/`) plus its `settings.json`. Discovered automatically thereafter.
2. **`constitution`** — set the standing principles and constraints every later phase reads.
3. **`continue`** — run the next single step (one phase, or one `implement` task) and stop at its gate.
   Two ways to drive it:
   - **Manual** — invoke `/continue` yourself, review at each gate, invoke it again for the next step.
     You stay in control step by step.
   - **Looped (Ralph loop)** — run [`skills/continue/loop.sh`](skills/continue/loop.sh) once from a
     terminal. It relaunches `/continue` as a **brand-new interactive process per step** — full TUI,
     normal permissions, the gate picker all work — so context is zeroed each time; `index.md` is the
     only memory carried across. You end each step's session when it's done and the loop asks whether to
     go on (its only stop control). It honors `gatePolicy` for which gates present a picker; the safety
     gates always pause regardless. Step cap = `execution.maxSteps` (override with `MAX_STEPS=…`).
     - **Unattended** — add `--headless` (`loop.sh --headless`) to run it hands-off: each step uses
       `claude -p`, which **auto-exits**, and the loop **auto-advances** with no prompts. There's no
       interactive picker, so the driver signals via text sentinels (it stops only at safety/`pause`
       gates, exits when the project is complete). Pair with `gatePolicy: auto`.

Every skill is also directly invocable on its own for one-off use. See
[`continue`](skills/continue) for the structure, settings schema, and chaining rules.

## Resume, jump, and refine

- **`continue` is a pointer into the artifact tree.** It carries no state of its own — it reads
  `index.md`'s live status dashboard to find exactly **where you left off**: which phase, and for
  `implement` which `REQ`/`TASK` item. It then runs that one next step and stops. This is the feature
  that makes the conversation disposable: pick the project up days later (or in a fresh process) and
  `continue` always knows the resume point, because the tree — not the chat — is the memory.
- **Jump to any phase with a single skill.** Because every phase skill is a pure transform, you don't
  have to go through `continue`. Invoke a skill directly (e.g. `/design`, `/specify`) to **jump back**
  and re-do an earlier phase for a document whenever you want; re-entering a phase updates that phase's
  artifact in place (one source of truth, no fork).
- **Refine a phase in a loop until satisfied.** Every phase ends at its gate offering **Approve**
  (continue to the next phase) · **Request changes** (refine — note what to change; it **re-runs the
  same phase in place**) · **Stop here**. Choosing *Request changes* repeatedly lets you iterate one
  phase on one document — tighten a spec, a design, a task set — looping over the same step until it's
  right, before advancing.

## The loop

```
constitution → specify → to-requirements → clarify → design → to-tasks → implement
             → verify/test → review → deploy → maintain ─┐
  ▲                                                       │
  └──────────── maintain feeds discovered work back ──────┘  (next vertical slice)

postures invoked from within phases: interview · doubt · incremental
```

Every `→` is a human gate. The driver `continue` runs the next step — one phase, or one `implement`
task — and **stops** at its gate; the `skills/continue/loop.sh` fresh-process loop relaunches it per step
(each a fresh interactive session), respecting `gatePolicy` for which gates present a picker.

## Skills

Each skill is a folder under [`skills/`](skills/) (`SKILL.md` + a `references/` directory for depth).
Folder name = the skill's `name`.

### Foundational
| Skill | Input → Output |
|---|---|
| [`setup`](skills/setup) | project (+ optional tree-root name) → scaffolded tree root: single `index.md` at `docs/<root>/` (default `sdlc`). One-time init; discovered thereafter |
| [`constitution`](skills/constitution) | project context → standing principles/constraints `[CONST]`, read by every phase |

### Phase
| Skill | Input → Output |
|---|---|
| [`specify`](skills/specify) | idea → **Specification** `[SPEC]` (objective, scope, success criteria) |
| [`clarify`](skills/clarify) | draft **Requirement** → ready Requirement (deep-dive; engine = `interview`) |
| [`design`](skills/design) | one **Requirement** → **Plan** `[REQ-n.DESIGN]` (approach, architecture, risks) |
| [`implement`](skills/implement) | one **Task** → working code (one task per fresh session; writes `[REQ-n.SESSION]`) |
| [`test`](skills/test) | a change → **TDD** tests, test-first (RED → GREEN → REFACTOR) |
| [`verify`](skills/verify) | a change → behavioral confirmation by running and observing |
| [`review`](skills/review) | verified slice → findings + dispositions (invokes `doubt`) |
| [`deploy`](skills/deploy) | reviewed slice → **shipped** + Deploy log `[DEPLOY]` (per-project ship commands) |
| [`maintain`](skills/maintain) | live signals → triaged **Maintenance queue** `[MAINT]`; closes the loop |

### Transition (`to-<phase>` — decompose + gather feedback)
| Skill | Input → Output |
|---|---|
| [`to-requirements`](skills/to-requirements) | **Specification** → Stakeholders `[STK-n]` + N **Requirements** `[REQ-n]` |
| [`to-tasks`](skills/to-tasks) | **Plan** → N **Tasks** `[REQ-n.TASK-m]` + dependency graph |

### Posture (cross-cutting, invoked from inside phases)
| Skill | Role |
|---|---|
| [`interview`](skills/interview) | one-question-at-a-time intent extraction; engine behind `specify` & `clarify` |
| [`doubt`](skills/doubt) | in-flight adversarial fresh-context review; used in `design`, `implement`, `review` |
| [`incremental`](skills/incremental) | per-session execution discipline (thin slices, keep-it-compilable) |

### Driver
| Skill | Role |
|---|---|
| [`continue`](skills/continue) | **base skill** and sole driver — defines the structure (artifact tree, storage, invariants, bootstrap, phase graph), loaded whenever working in the system; runs the **next single step** (one phase, or one `implement` task) and stops at its gate. Its [`loop.sh`](skills/continue/loop.sh) relaunches it as a fresh interactive session per step for full-loop runs |

## Generated file tree

Running the skillset on a project produces **one artifact tree** under `docs/<root>/`, rooted at a
single entry point. The root name is chosen once at [`setup`](skills/setup) (**default `sdlc`**) and
discovered thereafter via the single `index.md`. Levels materialize only when their producing skill
runs.

```
docs/<root>/            ← chosen at `setup`; default `docs/sdlc/`
  index.md              ← SINGLE ENTRY POINT: tree map + ID registry + live phase/gate status
  settings.json         ← skillset-version pin + execution prefs (system file, no ID)
  constitution.md       ← [CONST]
  spec.md               ← [SPEC]
  requirements/
    REQ-01/
      requirement.md    ← [REQ-01]          (Stakeholders [STK-n] referenced by ID)
      design.md         ← [REQ-01.DESIGN]
      tasks/
        TASK-01.md      ← [REQ-01.TASK-01]
      sessions/
        summary.md      ← [REQ-01.SESSION]  (fresh-context handoff)
    REQ-02/ …
  deploy/log.md         ← [DEPLOY]          (append-only; appears when deploy runs)
  maintenance/queue.md  ← [MAINT]           (appears when maintain runs)
```

`index.md` is the root object and plays three roles at once: **tree map**, **ID registry** (stable,
rename-safe ID → path), and **live status dashboard** (which also records the **last synced commit** for
drift detection). Cross-references target IDs through `index.md`, never raw paths; a gate-validation step
fails on any dangling, duplicate, orphan, or unreachable ID.

Beside it, **`settings.json`** pins the skillset `version` the tree was created with (the driver runs a
semver-aware compatibility check at session start — major mismatch halts) and holds tweakable
`execution` prefs. It's a system file written by `setup`/the driver bootstrap and read only by
`setup`/`continue`; phases receive any settings-derived value as a provided input, never the file. See
the [`continue`](skills/continue) base skill for the full settings schema and the
`SDLC_SKILLSET_VERSION` constant.

## Storage

Non-system skills never touch storage — they emit a **result** and the driver persists it. The
structure and every artifact read/write are owned by the [`continue`](skills/continue) base skill (see
its [`references/artifact-io.md`](skills/continue/references/artifact-io.md) for the storage binding and
[`references/handoff.md`](skills/continue/references/handoff.md) for the result contract, the
`.sdlc/scratch/` convention used by `to-*` skills, and the assemble/ingest seam). The canonical store is **local
files**, versioned with code (the tree above) — there is no swappable backend: keeping the artifact tree
in git is what gives atomic spec+code commits, branch-per-slice state, and the in-place diff that powers
anti-staleness. **GitHub issues** are an optional *edge integration*, not a backend — `maintain` can
ingest issues as a live-signal source, and Requirements/Tasks can be mirrored one-way to issues for
visibility (a derived view; the files stay source of truth).
