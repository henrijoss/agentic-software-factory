# SDLC Skillset — Workflow & Architecture

This skillset covers every phase of the software-development lifecycle as a set of small,
composable agent skills, chained through **human gates** by thin drivers (`continue`, `orchestrator`)
built on a `continue` base skill. This document is
the canonical map: the roster, the iterative loop, the composition model, the artifact tree, and the
calling conventions. Individual `SKILL.md` files implement the behavior; this file defines how they
fit together.

> **Authoring status.** Complete. All 14 phase/transition/posture skills plus the two drivers
> (`continue`, `orchestrator`) are authored against this spec (lean `SKILL.md` + `references/` each);
> the mined reference drafts have been consumed and deleted. This document remains the canonical map.
> Shared structure/storage knowledge lives in the **`continue` base skill** (see
> `skills/continue/SKILL.md` and its `references/`); the tree-root **bootstrap** open question is
> resolved there (a driver owns it; phase skills fall back).

## Design principles (locked)

1. **Composable, big↔small.** Process weight is not tiered by rule; you assemble only the skills —
   *and artifact-tree levels* — a job needs. A typo runs `implement` alone; a product runs the full
   chain. No level is mandatory.
2. **Iterative loop, not waterfall.** The unit of iteration is one **vertical slice / use-case**:
   run specify→…→review on a thin end-to-end slice, then loop. Implementation freely informs the
   spec. The lifecycle is a cycle closed by `maintain → specify`.
3. **Anti-staleness by in-place update.** Re-entering any phase **updates that phase's artifact in
   place** — single source of truth. Spec and code cannot silently diverge; re-entry is the
   reconciliation mechanism. (The field's top documented failure mode is a stale spec that an agent
   executes confidently; this rule plus gate-validation is the defense.)
4. **Every gate earns its interruption.** A human gate sits on every phase→phase arrow, but a gate
   must surface crucial information or force a real decision — never "looks good?". A gate with
   nothing to decide is a design smell, not a step. (Gates may be relaxed later if proven needless.)
5. **Base skill + thin drivers, standalone skills.** A `continue` **base skill** defines the
   structure (artifact tree, storage, invariants, bootstrap, phase graph) and is loaded whenever you
   work in the system; it is also the default driver that runs the **next single phase** and stops.
   The `orchestrator` builds on it for unattended **full-loop** runs. Every phase skill is also
   directly invocable on its own.
6. **Auto-advance only when asked for it.** `continue` runs one phase, holds its gate, and stops —
   the operator drives step by step. `orchestrator` is the opt-in variant that, on an explicit "yes"
   at each gate, auto-advances to the next phase — one continuous driven session.
7. **Lean, reliability-first skills.** Frontier models reliably follow only ~150–200 standing
   instructions before compliance degrades. Each `SKILL.md` is a thin operational core under that
   ceiling; depth (rationale, examples, tables) lives in `references/` loaded on demand. The drivers
   load one phase skill at a time.

## Three skill categories

1. **Phase skills** — own and deepen one artifact within a phase. One artifact in, one (better)
   artifact out. Names are SDLC phase verbs.
2. **Transition skills (`to-<phase>`)** — move work *between* phases. This is where **fan-out /
   decomposition** and **stakeholder/user feedback** happen (one artifact → many). They add real
   logic, not just reformat.
3. **Posture skills** — cross-cutting disciplines invoked *from inside* any phase. Descriptive
   names, no fixed position in the loop.

Folder name always equals the frontmatter `name`.

## The lifecycle loop

```
            ┌──── postures (invoked from within any phase): interview · doubt · incremental ────┐
            └──────────────────────────────────────────────────────────────────────────────────┘

   constitution ─▶ specify ─▶ to-requirements ─▶ clarify ─▶ design ─▶ to-tasks ─▶ implement ─▶ verify/test ─▶ review ─▶ deploy ─▶ maintain
   (standing       (idea→     (spec→stake-       (deepen    (req→     (plan→N    (slice's     (behavioral   (findings) (ship)   (triage
    principles,     spec)      holders +          one req)   plan)     tasks +    tasks,        +/or TDD                          live bugs)
    read by all)               N use-cases)                            dep graph) fresh ctx)    gate)                                 │
        ▲                                                                                                                            │
        └──────────────────────── maintain feeds discovered work back into specify (loop closes) ──────────────────────────────────┘
```

- Every `─▶` is a **human gate** (principle 4). A driver pauses and presents the decision; `continue`
  stops there, `orchestrator` auto-advances on explicit approval (principle 6).
- The loop runs **per vertical slice** (principle 2). A second slice re-enters `specify`/`design`
  with the constitution and prior artifacts already in place, updating them in place (principle 3).
- `to-requirements` and `to-tasks` additionally pause for user feedback while fanning out.

### What each gate decides

| Gate | The decision it forces |
|---|---|
| constitution → specify | Are the standing principles right before we commit intent to them? |
| specify → to-requirements | Is the objective/scope/success correct, and is it ready to fan out? |
| to-requirements → clarify | Are these the right use-cases and stakeholders? Which slice first? |
| clarify → design | Is this one requirement unambiguous enough to design against? |
| design → to-tasks | Is the approach/architecture sound and are the risks acceptable? |
| to-tasks → implement | Are tasks sized, ordered, and the dependency graph correct? |
| implement → verify/test | Does the slice do what the task claims? Which verification level applies? |
| verify → review | Is behavior confirmed and ready for adversarial review? |
| review → deploy | Are findings resolved or consciously accepted as trade-offs? |
| deploy → maintain | Did it ship cleanly; what is now in operation? |
| maintain → specify | Which discovered work re-enters the loop, at what priority? |

## Composition model

- **Init (once):** invoke `setup` to choose where the tree is generated (default `docs/sdlc/`) and
  scaffold its single `index.md`. It also orients greenfield vs brownfield (+ stack), recorded as
  `index.md` status — detection only, no code inventory. Optional — a driver/phase falls back to the
  default root if skipped.
- **Next step (default):** invoke `continue`; it reads `index.md`, runs the next single phase, holds
  the gate, and stops. Run it again for the following step.
- **Full project (unattended):** invoke the `orchestrator`; it walks the loop, gating and
  auto-advancing through every phase.
- **Sub-chain:** invoke any phase skill, or `continue`/`orchestrator` starting mid-loop (e.g. a known
  requirement → `design`) without earlier phases.
- **Single skill:** invoke one phase skill directly for a one-off (e.g. `implement` a typo fix).
  Creates only the minimal artifact tree; no requirements/ ceremony.

Composability extends to the **artifact tree**: levels materialize only when their producing skill
runs (see next section).

## Artifact tree & reference discipline

All non-source-code artifacts form **exactly one tree per project with a single entry point**. The
folder layout *is* the tree. Storage is local files, versioned with code (the structure and storage are
defined by the **`continue` base skill** — see `skills/continue/SKILL.md` and
`references/artifact-io.md`). The
tree root `docs/<root>/` is chosen once at `setup` (**default `sdlc`**) and **discovered** thereafter
by locating the single `index.md` — no skill hardcodes the path.

```
docs/<root>/          ← chosen at `setup`; default `docs/sdlc/`
  index.md            ← SINGLE ENTRY POINT: tree map + ID registry + live phase/gate status
  constitution.md     ← standing principles (read by every phase)        [ID: CONST]
  spec.md             ← Specification                                     [ID: SPEC]
  requirements/
    REQ-01/
      requirement.md  ← Requirement/use-case (+ stakeholder refs)         [ID: REQ-01]
      design.md       ← Plan for REQ-01                                   [ID: REQ-01.DESIGN]
      tasks/
        TASK-01.md                                                        [ID: REQ-01.TASK-01]
      sessions/
        summary.md    ← SessionSummary handoff for this slice            [ID: REQ-01.SESSION]
    REQ-02/ …
  deploy/log.md       ← deploy records (optional)                         [ID: DEPLOY]
  maintenance/queue.md← triaged bugs feeding back to specify (optional)   [ID: MAINT]
```

**Single entry point.** `index.md` is the root object; every artifact is reachable by walking down
from it. It plays three roles at once: **(a) tree map** (navigable structure), **(b) ID registry**
(ID → path), **(c) live status dashboard** (each artifact's current phase/gate state). A driver
(`continue` or `orchestrator`) reads `index.md` to know where the project stands and updates it as
phases advance.

**Reference discipline — stable IDs + validated registry.** Every artifact has a stable, rename-safe
ID. Cross-references target IDs resolved through `index.md`, never raw paths buried in prose. A
**validation step runs at every gate** and fails on: any dangling ID, any duplicate ID, any
unregistered file (orphan), or any artifact unreachable from `index.md`. This is what operationally
enforces "no stale references" and complements the in-place-update anti-staleness rule.

**Optional levels.** A tiny change may create only `index.md` + `spec.md` + a task; the
`requirements/` layer appears only when `to-requirements` runs. The single-entry-point invariant
holds at every size.

**Delta-only, code is source of truth.** Artifacts describe the **change to make** (the delta), never a
restatement of the existing code. Existing code is the source of truth: read **live** by `design`
(read-only, per requirement, so it can't go stale) and harvested **by reference** by `constitution`. On
a brownfield project `specify` scopes each slice as a delta against existing behavior. No artifact ever
persists a snapshot/inventory of current code — that is precisely the staleness this skillset fights.

## Roster

Each row = one standalone skill a driver can chain. Folder name MUST equal frontmatter `name`.

### Foundational

| Skill | Input → Output |
|---|---|
| `setup` | project (+ optional tree-root name) → scaffolded tree root: single `index.md` at `docs/<root>/` (default `sdlc`). One-time init before the loop; discovered thereafter |
| `constitution` | project context → standing principles/constraints artifact, read by all phases |

### Phase skills

| Skill | Input → Output |
|---|---|
| `specify` | idea → **Specification** (objective, scope, success criteria) |
| `clarify` | one draft **Requirement** → ready Requirement (human deep-dive; engine = `interview`) |
| `design` | one **Requirement** → implementation **Plan** (approach, architecture, risks) |
| `implement` | a slice's **Tasks** → working code, fresh-context loop, follows `incremental` |
| `verify` / `test` | a change → behavioral confirmation and/or TDD tests (gate) |
| `review` | implemented slice → findings + improvements (may invoke `doubt`) |
| `deploy` | reviewed change → shipped (build / prerender / publish per project) |
| `maintain` | live issues/bugs → triaged work fed back to `specify` (closes the loop) |

### Transition skills (`to-<phase>` — decompose + feedback)

| Skill | Input → Output |
|---|---|
| `to-requirements` | **Specification** → Stakeholders + N **Requirements**/Use-cases (fan-out) |
| `to-tasks` | **Plan** → N **Tasks** + dependency graph (fan-out, sizing, ordering) |

### Posture skills (cross-cutting)

| Skill | Role |
|---|---|
| `interview` | one-question-at-a-time intent extraction; engine behind `specify` & `clarify` |
| `doubt` | in-flight adversarial fresh-context review; used in `design`, `implement`, `review` |
| `incremental` | per-session execution discipline (thin slices, keep-it-compilable) |

> `design` + `to-tasks` are the two halves the example `plan-implementation` draft conflated
> ("produce a plan" vs. "split into tasks"). The architecture keeps them split.

### Drivers

| Skill | Role |
|---|---|
| `continue` | base skill: defines the structure (artifact tree, storage, invariants, bootstrap, phase graph), loaded whenever working in the system; default driver — runs the **next single phase** and stops at its gate |
| `orchestrator` | full-loop driver, built on `continue`: walks the whole graph and **auto-advances** through gates on approval for unattended runs |

## Testing & verification strategy

`test` and `verify` are **separate, independently invocable**; the operator picks per task:

- **TDD (`test`, test-first):** logic with a clear input/output contract, bug fixes (reproduce
  first), anything where the contract is known before the code.
- **Verify (`verify`):** UI/visual, integration, "does the app actually do X" — run it and observe.
- **Both:** high-stakes or cross-boundary tasks (unit contract via TDD + behavioral via verify).

The `implement` loop and `review` can each call either or both as a completion gate.

## Storage / I/O layer

Skills must **not** hardcode storage paths. The structure and all artifact read/write are owned by
the **`continue` base skill** (`skills/continue/SKILL.md`); its `references/artifact-io.md` binds each
abstract artifact (Constitution, Specification, Stakeholder, Requirement, Plan, Task, SessionSummary,
plus Deploy/Maintenance state) to storage operations.

- **Canonical store: local files**, versioned with code (the `docs/<root>/` tree above; root chosen at
  `setup`, default `docs/sdlc/`, discovered via the single `index.md`). There is no swappable backend:
  the artifact tree lives in git so a single commit changes an artifact and the code it governs
  atomically, branches carry per-slice state, and in-place re-entry is a reviewable diff — the
  anti-staleness mechanism. Putting the tree in a remote tracker would forfeit all three.
- **GitHub issues are an optional edge integration, not a backend:** `maintain` may ingest issues as a
  live-signal source (declared in `[CONST]`) → `[MAINT]`, and Requirements/Tasks may be mirrored
  one-way to issues for visibility (a derived view; on drift, the files win). See `references/artifact-io.md`.
- The tree satisfies the **single-entry-point / single-tree / ID-registry / gate-validation**
  structural invariants. Storage details live in the base skill, not in every skill.

## Authoring order (done)

Authored in dependency order (all ✅):

`constitution` → `interview` → `specify` → `incremental` + `doubt` → `design` → `to-tasks` →
`implement` → `verify`/`test` → `review` → `to-requirements` → `clarify` → `deploy` → `maintain` →
`continue` + `orchestrator` (drivers last; needed the phases to exist) → `setup` (init front door for
the configurable tree root).

Authoring contract (held by every skill): folder name = frontmatter `name`; abstract Inputs/Outputs
declared; storage via the `continue` base skill; thin operational core under the instruction ceiling +
a `references/` directory for depth. The mined example drafts were replaced as each real skill landed.
