# agentic-software-factory

A composable **SDLC agent skillset**: small, single-purpose [Claude Code skills](skills/) that cover
every phase of the software lifecycle and chain together through **human gates**, driven by a thin
`orchestrator`.

## What it is

- **Composable, big↔small.** Assemble only the skills (and artifact-tree levels) a job needs. A typo
  runs `implement` alone; a product runs the whole loop. No phase is mandatory.
- **Iterative, not waterfall.** The unit of iteration is one **vertical slice / use-case**. The loop
  is a cycle closed by `maintain → specify`.
- **Anti-staleness by in-place update.** Re-entering a phase overwrites *that phase's* artifact — one
  source of truth, so spec and code cannot silently diverge.
- **A human gate on every transition.** Each gate must surface a real decision, never "looks good?".
- **Base skill + thin drivers, standalone skills.** A `continue` base skill defines the structure and
  is loaded whenever working in the system; it is the default driver (next step, then stop), with
  `orchestrator` as the opt-in full-loop variant. Every skill is also directly invocable on its own.
- **Lean.** Each skill is a small operational core (depth in its `references/`); a driver loads
  **one phase at a time** to stay within the model's reliable instruction budget.

## The loop

```
constitution → specify → to-requirements → clarify → design → to-tasks → implement
             → verify/test → review → deploy → maintain ─┐
  ▲                                                       │
  └──────────── maintain feeds discovered work back ──────┘  (next vertical slice)

postures invoked from within phases: interview · doubt · incremental
```

Every `→` is a human gate. The default driver `continue` runs the next phase and **stops** at its
gate; the opt-in `orchestrator` auto-advances through the whole loop on explicit approval.

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
| [`implement`](skills/implement) | a slice's **Tasks** → working code (fresh-context loop; writes `[REQ-n.SESSION]`) |
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
| [`continue`](skills/continue) | **base skill** — defines the structure (artifact tree, storage, invariants, bootstrap, phase graph), loaded whenever working in the system; default driver: runs the **next single phase** and stops at its gate |
| [`orchestrator`](skills/orchestrator) | full-loop driver built on `continue`: walks the phase graph, loads one skill at a time, holds each gate, **auto-advances** on approval |

## Generated file tree

Running the skillset on a project produces **one artifact tree** under `docs/<root>/`, rooted at a
single entry point. The root name is chosen once at [`setup`](skills/setup) (**default `sdlc`**) and
discovered thereafter via the single `index.md`. Levels materialize only when their producing skill
runs.

```
docs/<root>/            ← chosen at `setup`; default `docs/sdlc/`
  index.md              ← SINGLE ENTRY POINT: tree map + ID registry + live phase/gate status
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
rename-safe ID → path), and **live status dashboard**. Cross-references target IDs through `index.md`,
never raw paths; a gate-validation step fails on any dangling, duplicate, orphan, or unreachable ID.

## Storage

Skills never hardcode storage — the structure and every artifact read/write are owned by the
[`continue`](skills/continue) base skill (see its
[`references/artifact-io.md`](skills/continue/references/artifact-io.md)). The canonical store is **local
files**, versioned with code (the tree above) — there is no swappable backend: keeping the artifact tree
in git is what gives atomic spec+code commits, branch-per-slice state, and the in-place diff that powers
anti-staleness. **GitHub issues** are an optional *edge integration*, not a backend — `maintain` can
ingest issues as a live-signal source, and Requirements/Tasks can be mirrored one-way to issues for
visibility (a derived view; the files stay source of truth).

## Internal docs

- [`WORKFLOW.md`](WORKFLOW.md) — internal architecture spec and design rationale (the canonical map
  behind these skills). Not part of the shipped skillset.
