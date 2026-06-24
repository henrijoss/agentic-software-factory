# Phase Graph — advisory "what usually follows next"

Loaded on demand by the `continue` base skill. An **advisory** map of what *usually* follows what, plus
the entry modes and the tree-root bootstrap procedure. It is **not** an enforced sequence and carries
**no gates**: the driver routes by operator **intent** and only *suggests* a likely next step from this
map (see `continue` Step 4). The operator can always override the suggestion.

## The usual order

Linear spine, closed by `maintain → specify`:

```
constitution → specify → to-requirements → clarify → design → to-tasks → implement
             → verify/test → review → deploy → maintain → (specify, next slice)
```

The arrows mean "what commonly comes next", **not** "a required gate". Free navigation by intent is the
rule; this order is only the default suggestion when the operator gives none.

- **Postures are not nodes.** `interview`, `doubt`, `incremental` are invoked *inside* phases
  (`specify`/`clarify` call `interview`; `design`/`implement`/`review` call `doubt`; `implement`
  follows `incremental`). The driver never schedules them — it only routes to phase/transition skills.
- **`verify`/`test` is opt-in:** suggested only when there is observable behavior to confirm. The
  operator picks TDD (`test`), run-and-observe (`verify`), both, or skips it. Never mandatory.
- **`deploy`/`maintain` are opt-in:** suggested only when a deployment/release/operation actually
  exists — never mandatory mainline steps. `deploy` is an outward, hard-to-reverse action; authorize it
  consciously whenever it is the chosen step.
- **Transition skills (`to-requirements`, `to-tasks`) fan out** a set for the operator to review.
- **At each step the driver assembles inputs before and ingests the result after.** Phase/transition
  skills are pure transforms emitting a result; the driver gathers their inputs from the tree and
  persists their output into it (see `references/handoff.md`). The graph only suggests the next node.

## Decisions each step typically weighs

When the driver suggests a step, these are the questions that step usually turns on — **advisory**
prompts the operator weighs, not forced gates. The driver poses the matching one rather than a generic
"looks good?".

| Step | Question it typically turns on |
|---|---|
| constitution → specify | Are the standing principles right before we commit intent to them? |
| specify → to-requirements | Is the objective/scope/success correct, and ready to fan out? |
| to-requirements → clarify | Right use-cases and stakeholders? Which slice first? |
| clarify → design | Is this requirement unambiguous enough to design against? |
| design → to-tasks | Is the approach/architecture sound and the risks acceptable? |
| to-tasks → implement | Are tasks sized, ordered, and the dependency graph correct? |
| implement → verify/test | Does the slice do what the task claims? Which verification level (if any)? |
| verify → review | Is behavior confirmed and ready for adversarial review? |
| review → deploy | Findings resolved or consciously accepted as trade-offs? |
| deploy → maintain | Did it ship cleanly; what is now in operation? |
| maintain → specify | Which discovered work re-enters the loop, at what priority? |

These questions are the advisory considerations surfaced per `references/presentation.md`. This table
stays the single source of the questions; editing one changes the user-facing copy. No display format
lives here.

## Entry modes (composition model)

| Mode | Start | Behavior |
|---|---|---|
| **Full project** | `constitution` (or `specify` if `[CONST]` exists) | Suggest the loop, slice by slice |
| **Sub-chain** | the phase after the chosen artifact | e.g. a ready `[REQ-n]` → `design` → … |
| **Resume** | what `index.md`'s **Suggested next** points to | Continue from where we left off |
| **Intent** | the phase the operator names | Route directly to it, update in place |
| **Single** | — | Defer to the phase skill directly; no driver |

When no intent is given and the next step isn't obvious from `index.md`, propose a step plus 1–2
alternatives rather than guessing (see `continue` Step 4).

At session start — after resolving the tree root, before suggesting a step — the driver runs the **sync
check** (`references/sync.md`): compare `index.md`'s `Last synced commit` to `HEAD` and, on external
drift, reconcile before proceeding.

On a **brownfield** project (status set by `setup`), **Full project** entry still suggests starting at
`constitution` — which harvests existing standing docs and captures existing-system facts by reference —
then `specify`, which scopes the first slice as a delta against existing behavior. The order is
unchanged; only the framing (harvest + delta) differs from greenfield.

## Tree-root resolution & bootstrap

`docs/<root>/index.md` (root chosen at `setup`, default `sdlc`) must exist before any phase writes an
artifact. The root is **discovered**, and creation is **idempotent**:

1. **`setup` is the explicit init.** Picks the root name (default `sdlc`) and scaffolds the minimal
   `index.md` once at project start, with status reflecting greenfield vs brownfield (+ stack).
2. **A driver resolves/falls back.** At session start, discover the single `index.md`; if none exists,
   create the **default** `docs/sdlc/` minimal root. An existing tree is left untouched — never forked.

Only `setup` and the `continue` driver create/write the tree. A standalone phase/transition skill
creates no tree — it emits a result the operator ingests by running `continue`.

The discovery rule, minimal root, and full rationale live in the `continue` base skill and
`references/artifact-io.md`. This keeps the four invariants (single entry point / single tree / ID
registry / gate-validation) satisfiable from the very first phase, at any entry point.
