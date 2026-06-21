# Phase Graph — Sequencing (depth)

Loaded on demand by the `continue` base skill (and referenced by `orchestrator`). The canonical phase
graph, gate-decision table, entry modes, and the tree-root bootstrap procedure. Both drivers walk this
graph; `continue` runs one step of it, `orchestrator` auto-advances along it.

## The phase graph

Linear spine, closed by `maintain → specify`:

```
constitution → specify → to-requirements → clarify → design → to-tasks → implement
             → verify/test → review → deploy → maintain → (specify, next slice)
```

- **Postures are not nodes.** `interview`, `doubt`, `incremental` are invoked *inside* phases
  (`specify`/`clarify` call `interview`; `design`/`implement`/`review` call `doubt`; `implement`
  follows `incremental`). A driver never schedules them — it only sequences phase/transition skills.
- **`verify`/`test` is one node with a choice:** the operator picks TDD (`test`), run-and-observe
  (`verify`), or both per the task. The driver presents the choice; the `test`/`verify` skills define
  which applies.
- **Transition skills (`to-requirements`, `to-tasks`) fan out** and pause for user feedback as part of
  their own gate — a driver just holds that gate like any other.
- **At each node the driver assembles inputs before and ingests the result after.** Phase/transition
  skills are pure transforms emitting a result; the driver gathers their inputs from the tree and
  persists their output into it (see `references/handoff.md`). The graph only sequences nodes.

## Gate decisions (what each arrow forces)

A driver poses the matching question at each gate — never a generic "looks good?".

| Gate | Decision forced |
|---|---|
| constitution → specify | Are the standing principles right before we commit intent to them? |
| specify → to-requirements | Is the objective/scope/success correct, and ready to fan out? |
| to-requirements → clarify | Right use-cases and stakeholders? Which slice first? |
| clarify → design | Is this requirement unambiguous enough to design against? |
| design → to-tasks | Is the approach/architecture sound and the risks acceptable? |
| to-tasks → implement | Are tasks sized, ordered, and the dependency graph correct? |
| implement → verify/test | Does the slice do what the task claims? Which verification level? |
| verify → review | Is behavior confirmed and ready for adversarial review? |
| review → deploy | Findings resolved or consciously accepted as trade-offs? |
| deploy → maintain | Did it ship cleanly; what is now in operation? (+ pre-ship authorization) |
| maintain → specify | Which discovered work re-enters the loop, at what priority? |

`deploy` carries an extra, inverted gate *before* its action (explicit ship authorization) — honor it
even within a driven session; review approval ≠ ship approval.

## Entry modes (composition model)

| Mode | Start | Behavior |
|---|---|---|
| **Full project** | `constitution` (or `specify` if `[CONST]` exists) | Walk the whole loop, slice by slice |
| **Sub-chain** | the phase after the chosen artifact | e.g. a ready `[REQ-n]` → `design` → … |
| **Resume** | what `index.md` status says is next | Continue from where we left off |
| **Single** | — | Defer to the phase skill directly; no driver |

When the start phase isn't unambiguous from `index.md`, confirm with the user rather than guessing.

At session start — after resolving the tree root, before determining the start/next phase — both
drivers run the **sync check** (`references/sync.md`): compare `index.md`'s `Last synced commit` to
`HEAD` and, on external drift, hold the sync gate to reconcile before walking the graph.

On a **brownfield** project (status set by `setup`), **Full project** entry still starts at
`constitution` — which harvests existing standing docs and captures existing-system facts by reference —
then `specify`, which scopes the first slice as a delta against existing behavior. The graph is
unchanged; only the framing (harvest + delta) differs from greenfield.

## Tree-root resolution & bootstrap

`docs/<root>/index.md` (root chosen at `setup`, default `sdlc`) must exist before any phase writes an
artifact. The root is **discovered**, and creation is **idempotent**:

1. **`setup` is the explicit init.** Picks the root name (default `sdlc`) and scaffolds the minimal
   `index.md` once at project start, with status reflecting greenfield vs brownfield (+ stack).
2. **A driver resolves/falls back.** At session start, discover the single `index.md`; if none exists,
   create the **default** `docs/sdlc/` minimal root. An existing tree is left untouched — never forked.

Only `setup` and the two drivers create/write the tree. A standalone phase/transition skill creates no
tree — it emits a result the operator ingests by running `continue`.

The discovery rule, minimal root, and full rationale live in the `continue` base skill and
`references/artifact-io.md`. This keeps the four invariants (single entry point / single tree / ID
registry / gate-validation) satisfiable from the very first phase, at any entry point.
