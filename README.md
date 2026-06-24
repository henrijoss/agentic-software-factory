# agentic-software-factory

A composable **SDLC agent skillset**: small, single-purpose [Claude Code skills](skills/) that cover
every phase of the software lifecycle and chain along an **advisory graph you navigate by intent**,
driven by the thin `continue` base skill — one step per session, with a fresh-process loop script that
relaunches it interactively per step.

## What it is

- **Composable, big↔small.** Assemble only the skills (and artifact-tree levels) a job needs. A typo
  runs `implement` alone; a product runs the whole loop. No phase is mandatory.
- **Iterative, not waterfall.** The unit of iteration is one **vertical slice / use-case**; the loop is
  an advisory cycle closed by `maintain → specify`. You navigate it freely by intent — there is no
  enforced forward march; the graph only *suggests* a likely next step.
- **Anti-staleness by in-place update.** Re-entering a phase overwrites *that phase's* artifact — one
  source of truth, so spec and code cannot silently diverge. A **drift sync** against git
  (`index.md` records the last reconciled commit) catches code committed outside the system between
  sessions.
- **Interactive by default, one `auto` switch.** Each step surfaces a real choice, never "looks good?".
  How much you stay in the loop is the single `auto` switch: `false` (default) runs the interactive
  end-of-step hand-off each step; `true` (or `/continue --auto`) skips the questions and auto-takes the
  suggested next step. Correctness checks (gate-validation, sync drift, version mismatch) always stop
  regardless of `auto`.
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
     terminal. It relaunches `/continue` as a **brand-new process per step** — context is zeroed each
     time, and each step is seeded with the **last 5 commits** + `index.md`'s next-task and
     bigger-picture note, so `index.md` + git history are the only memory carried across. Each
     `implement` step ends with **one semantic commit** (clean per-task history). It honors `auto`:
     `false` (default) runs interactive — full TUI, normal permissions; you end each step and the loop
     asks whether to go on (its only stop control). `true` (`loop.sh --auto`) runs **unattended** — each
     step uses `claude -p`, which auto-exits, and the loop auto-advances with no prompts. Correctness
     checks always stop regardless. Step cap = `execution.maxSteps` (override with `MAX_STEPS=…`).

Every skill is also directly invocable on its own for one-off use. See
[`continue`](skills/continue) for the structure, settings schema, and chaining rules.

## Resume, jump, and refine

- **`continue` routes by intent, or resumes from `index.md`.** Give it an explicit intent (e.g.
  "refine REQ-2's design") and it routes **straight** to that phase on that artifact and updates it in
  place — no intervening forced step. With **no** intent it reads `index.md`'s status — **Last worked /
  Suggested next** — and proposes the suggested step plus an alternative or two for you to pick; it never
  auto-marches a fixed sequence (unless `auto`). This is what makes the conversation disposable: pick the
  project up days later (or in a fresh process) and `continue` always knows the resume point, because the
  tree — not the chat — is the memory.
- **Jump to any phase with a single skill.** Because every phase skill is a pure transform, you don't
  have to go through `continue`. Invoke a skill directly (e.g. `/design`, `/specify`) to **jump back**
  and re-do an earlier phase for a document whenever you want; re-entering a phase updates that phase's
  artifact in place (one source of truth, no fork). Specs are **living** — `spec.md` and each
  `requirement.md` can be re-clarified any time, before *or* after implementation, never "closed".
- **Refine a phase in a loop until satisfied.** Each step **writes its artifact in place**, then the
  end-of-step hand-off surfaces any **critical open topics** (or, if none, **related topics + concrete
  examples** worth exploring) and offers **Progress to next phase · Continue with a topic · Stop here**.
  Choosing *Continue with a topic* re-runs the same phase on the same document in place — tighten a spec,
  a design, a task set — looping until it's right before progressing. Under `auto` the hand-off questions
  are skipped and the suggested next step is taken automatically.

## The loop

```
constitution → specify → to-requirements → clarify → design → to-tasks → implement
             → verify/test → review → deploy → maintain ─┐
  ▲                                                       │
  └──────────── maintain feeds discovered work back ──────┘  (next vertical slice)

postures invoked from within phases: interview · doubt · incremental
```

The arrows are advisory, not gates — you navigate by intent, and the graph only *suggests* a likely next
step. `verify`/`test`, `deploy`, and `maintain` are **opt-in**: suggested only when there's something to
verify, a release to ship, or observable behavior to watch — never mandatory mainline steps. The driver
`continue` runs the next step — one phase, or one `implement` task — and **stops**; the
`skills/continue/loop.sh` fresh-process loop relaunches it per step (each a fresh session), honoring
`auto` for whether each step's hand-off is interactive.

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
| [`implement`](skills/implement) | one **Task** → working code (one task per fresh session; ends with one semantic `commit`) |
| [`commit`](skills/commit) | a finished change → one **semantic commit** (`type(scope): subject`) on `main`; called at the end of each `implement` task |
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
  index.md              ← SINGLE ENTRY POINT: tree map + ID registry + status (Last worked / Suggested next / Last synced)
  settings.json         ← skillset-version pin + execution prefs (system file, no ID)
  constitution.md       ← [CONST]           (living spec — durable, edited in place)
  spec.md               ← [SPEC]            (living spec — durable, edited in place)
  requirements/
    REQ-01/
      requirement.md    ← [REQ-01]          (living spec — durable; Stakeholders [STK-n] by ID)
      design.md         ← [REQ-01.DESIGN]   (ephemeral — removed when the slice finishes; git keeps it)
      tasks/                                (ephemeral — removed when the slice finishes; git keeps it)
        TASK-01.md      ← [REQ-01.TASK-01]
    REQ-02/ …
  deploy/log.md         ← [DEPLOY]          (optional — appears when deploy runs)
  maintenance/queue.md  ← [MAINT]           (optional — appears when maintain runs)
```

**Living specs vs. ephemeral scaffolding.** `constitution.md`, `spec.md`, and each `requirement.md` are
**living specs** — durable, re-edited in place any time (before or after implementation), never deleted.
`design.md` and `tasks/` are **ephemeral working scaffolding** — removed once the requirement's slice is
finished; the durable record of *why* something was built (and prior approaches to reuse) lives in the
**git commits/tree**, not in those files, and a removed design/task is always recoverable
(`git log -- <path>` / `git show <sha>:<path>`). The per-slice handoff that used to sit in a session file
is now carried by `index.md`'s status + the last few commits.

`index.md` is the root object and plays three roles at once: **tree map**, **ID registry** (stable,
rename-safe ID → path), and **live status dashboard** (which also records the **last synced commit** for
drift detection). Cross-references target IDs through `index.md`, never raw paths; a gate-validation step
fails on any dangling, duplicate, orphan, or unreachable ID.

Beside it, **`settings.json`** pins the skillset `version` the tree was created with (the driver runs a
semver-aware compatibility check at session start — major mismatch halts) and holds the tweakable
`execution` block:

```json
"execution": { "maxSteps": 50, "auto": false, "reviewLoops": 1, "commitPerStep": true }
```

`maxSteps` caps the fresh-process loop, `auto` is the single human-in-the-loop switch (overridable per
invocation with `/continue --auto`), `reviewLoops` is the adversarial `doubt`-pass count, and
`commitPerStep` keeps the commit-per-task history. It's a system file written by `setup`/the driver
bootstrap and read only by `setup`/`continue`; phases receive any settings-derived value as a provided
input, never the file. See the [`continue`](skills/continue) base skill for the full schema and the
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
