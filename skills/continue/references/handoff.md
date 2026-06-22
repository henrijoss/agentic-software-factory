# Handoff — Result Contract, Ingest & Input-Assembly (depth)

Loaded on demand by the `continue` base skill. This is
the **seam** between the system skills (`setup`, `continue`) and every
other skill. The other skills are **pure, system-agnostic transforms**: they know nothing
of the artifact tree, `index.md`, stable IDs, storage paths, or which skill runs next.
They take inputs the caller provides and **emit a result**; the driver does everything
system-shaped around them — **assembles inputs** before, and **ingests the result**
after ("`continue` kicks in once the skill finishes").

Three pieces:

1. **The result contract** — the one shape every transform emits.
2. **Ingest** — how a driver turns an emitted result into tree state.
3. **Input-assembly** — how a driver gathers a phase's inputs from the tree first.

## 1. The result contract

A small manifest + body. **No tree paths, no `index.md`, no system IDs** — the driver
assigns those. `slug` and `gate` are hints/intrinsics the transform owns.

```
---
artifact: <abstract noun>       # Specification | Plan | Requirement | Task | Stakeholder | SessionSummary | DeployRecord | MaintenanceItem | Constitution
slug: <suggested-kebab-title>   # naming hint only; the driver assigns the real stable ID
gate: "<intrinsic decision question>"   # e.g. "Is the objective/scope/success right and ready to fan out?"
assumptions: [ ... ]            # surfaced assumptions / open questions (optional)
---
<artifact body markdown>
```

The `gate` is the transform's **intrinsic** decision question — useful standalone and
posed verbatim-or-canonical by the driver. The driver's canonical per-arrow questions
live in `references/phase-graph.md`; on any mismatch the phase-graph table wins.

### Two transports, one contract

| Producer | Artifacts | Transport |
|---|---|---|
| **Phase skills** (`constitution`, `specify`, `clarify`, `design`, `implement`, `verify`/`test`, `review`, `deploy`, `maintain`) | one | **In-context result block** — a fenced block at the end of the run carrying the contract. Nothing written to disk. |
| **Transition skills** (`to-requirements`, `to-tasks`) | many (fan-out) | **Scratch files** under `.sdlc/scratch/` — one file per produced artifact, each with the contract front-matter, plus a fan-out summary (recommended first slice / ordering / dep graph). |

The `to-` prefix is the visible signal: a `to-*` skill **writes scratch files**; every
other skill only prints. Neither ever writes into the artifact tree — that is the
driver's exclusive job.

### `.sdlc/scratch/` convention

- Ephemeral handoff area at the **repo root**, outside any artifact tree (a standalone
  `to-*` run creates no tree). Treat as gitignored scratch.
- One file per produced artifact, e.g. `.sdlc/scratch/REQ-auth-login.md`,
  `.sdlc/scratch/stakeholders.md`, `.sdlc/scratch/dep-graph.md`. Names use the `slug`
  hint; the driver maps them to real IDs on ingest.
- The driver **clears** `.sdlc/scratch/` after a successful ingest.

## 2. Ingest (driver-only — runs after the transform finishes)

The driver captures the emitted result and is the **only** actor that touches tree state.
Steps:

1. **Capture.** Phase skill → read the in-context result block. `to-*` skill → read the
   `.sdlc/scratch/` files.
2. **Resolve/assign ID.** Map the abstract `artifact` + `slug` to the stable ID via
   `references/artifact-io.md` (e.g. `Specification` → `SPEC`; a fanned-out `Requirement`
   → next `REQ-<n>`). On re-entry, resolve to the **existing** ID for that artifact.
3. **Write to the tree.** Write the body to the artifact's storage path (artifact-io
   binding table). **In-place update / no-fork:** re-entry overwrites the existing file;
   never create a parallel copy. New fan-out artifacts create their dir + file.
4. **Register.** Add/update the ID → path row and the status in `index.md` (tree map +
   ID registry + status dashboard). An **`implement`** ingest touches **two** rows: it
   writes the `[REQ-n.SESSION]` SessionSummary in place **and** sets the just-finished
   `[REQ-n.TASK-m]` status (`done`, or `blocked`) — the per-task status the next step reads
   to pick the next task. A **`to-tasks`** ingest sets the requirement's status to `tasks ready`,
   or `tasks ready · deferred` when the gate resolved to defer implement (the
   *Clarify next requirement* pick, or `traversal: requirements-first` with a draft requirement still
   remaining) — the marker the next step's traversal reads (`SKILL.md` Step 4).
5. **Gate-validate.** Run the structural validation (dangling / duplicate / orphan /
   unreachable → fail and surface). A `to-*` fan-out registers **all** produced artifacts
   before validating.
6. **Present the gate.** Pose the decision (canonical question from `phase-graph.md`, or
   the transform's `gate` when it adds specificity) — never "looks good?". Inside
   `implement`, a finished task with more tasks remaining is **not** a gate — just stop;
   only the last task reaches the implement→verify gate.
7. **Stop.** The step always stops here — the session ends. Advancing to the next step is
   the operator's `continue` (interactive) or the `loop.sh` fresh-process loop, never an
   in-session walk. Then **clear** `.sdlc/scratch/`.

The in-place-update and gate-validation invariants live here in the driver — phase
skills no longer restate them.

## 3. Input-assembly (driver-only — runs before the transform)

A transform cannot read `[CONST]` or a prior artifact itself (it doesn't know the tree).
The driver gathers the inputs and passes them as provided content. Which artifacts feed
which phase comes from the **consumed-by** column of the artifact table in
`references/artifact-io.md`. Sketch:

| Phase | Inputs the driver assembles & passes |
|---|---|
| `constitution` | project context (+ existing standing docs to harvest) |
| `specify` | `[CONST]`; prior `[SPEC]` on re-entry; the idea/`[MAINT]` item |
| `to-requirements` | `[SPEC]`, `[CONST]` |
| `clarify` | one draft `[REQ-n]`, `[CONST]` |
| `design` | one `[REQ-n]`, `[CONST]`; prior `[REQ-n.DESIGN]` on re-entry (code read live by the skill itself) |
| `to-tasks` | `[REQ-n.DESIGN]`, `[CONST]` |
| `implement` | the **single** next `[REQ-n.TASK-m]` (lowest non-`done` task whose deps are met — driver-selected), prior `[REQ-n.SESSION]`, `[CONST]` |
| `verify`/`test` | the change + the slice's `[REQ-n]`/tasks |
| `review` | the implemented slice, `[STK-n]`, `[CONST]` |
| `deploy` | the reviewed change, `[CONST]` |
| `maintain` | live-signal sources declared in `[CONST]` |

For `design`, `implement`, and `review`, the driver **also** passes
`settings.execution.reviewLoops` (the adversarial `doubt`-pass count) as a plain
provided input — "run N `doubt` passes on non-trivial decisions". This is the seam
that keeps phases settings-unaware: the phase honors a numeric input exactly like it
consumes `[CONST]`, and never reads `settings.json` (only the system skills do). If
the driver provides no count, the phase uses its own judgment.

Standalone (no driver): the user supplies inputs directly; the transform just runs on
what it's given. This is what makes every non-system skill independently invocable.
