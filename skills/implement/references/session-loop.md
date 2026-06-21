# Implement — Fresh-Context Loop (depth)

Loaded on demand by the `implement` skill. The SKILL.md core states the loop; the rationale,
context-loading discipline, and SessionSummary template live here.

## Why a fresh-context loop

A long feature exceeds what one context window holds reliably. Two bad alternatives:

- **One ever-growing session** — context fills with stale detail; assumptions made early harden into
  "facts"; compliance with instructions degrades as the window saturates. The agent drifts and starts
  executing confidently against a stale picture (this skillset's top documented failure mode).
- **Restarting cold each time** — the next session re-derives everything, slowly and inconsistently.

The fresh-context loop is the middle path: each session starts clean but reads a small, current
**handoff** (the SessionSummary) plus the specific Task. State lives in the artifact, not in an
ever-longer conversation. This is the same discipline as the GitHub-issues backend's Session-Context
issue — the handoff is the durable memory; the session is disposable.

This per-**task** loop is the *inner* instance of the driver-level per-**step** loop the `continue`
base skill defines in `references/fresh-context.md` (where `index.md` is the cross-step handoff and
`skills/orchestrator/loop.sh` gives a fresh process per step). A single `implement` step may run
several task-sessions before the step writes its gate decision and the outer loop advances.

## Context-loading discipline (Step 1)

Load the *right* slice, not everything:

- the SessionSummary (where we are) + the current Task (what's next);
- only the Plan sections relevant to this task;
- only the source files this task touches, plus their direct collaborators;
- the **Constitution** for commands and boundaries.

Do **not** load the whole spec tree, every requirement, or the entire codebase. More context is not
more capability past the point where the signal is diluted — it's the cause of drift, not a defense
against it.

## What goes in the SessionSummary

It is a handoff to a future agent (possibly you, with no memory of now). It answers, tersely:

- **Done** — what was completed this slice (tasks, changes), enough to not redo it.
- **Next** — the immediate next task and the exact place to start.
- **Open** — unresolved decisions, blockers, things to watch, deferred-but-noted scope items.
- **Touched** — key files/areas changed, so the next session knows where the work lives.

Keep it tight — it's a pointer into the work, not a transcript. Each session emits the latest summary;
the driver **overwrites the prior summary in place** (anti-staleness), never forking a second one.

## Full template

```markdown
# Session — [slice]

## Done
- [task] [what shipped + acceptance met]

## Next
- [task] [the immediate next unit + where to start]

## Open
- [unresolved decision / blocker / thing to watch]

## Touched
- [path or area] — [what changed]
```

## How it nests with the postures

- **`incremental`** governs *within* a session: thin slices, verify each, keep compilable, hold
  scope. The SessionSummary records the boundary *between* sessions.
- **`doubt`** is invoked at decision points inside a session; if a doubt cycle is left unresolved at
  session end, record it under **Open** so it isn't silently dropped.
- **`verify`/`test`** is the per-task completion gate; the SessionSummary's **Done** should only list
  tasks that passed it.

## One-off composability

For a typo or single-task fix, the loop collapses: one session, one task, run `incremental`, verify,
done — no SessionSummary, no requirements ceremony. Materialize the session layer only when the
work actually spans sessions. (When a driver is persisting, its single-entry-point invariant still
holds regardless of size — but that's the driver's concern, not this skill's.)
