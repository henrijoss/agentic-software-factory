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

There is **no separate inner in-session loop**: one task = one session = one step. The per-**task** loop
*is* the driver-level per-**step** fresh-process loop the `continue` base skill defines in
`references/fresh-context.md` — `skills/continue/loop.sh` relaunches a brand-new session for each task,
so each task gets truly fresh context. The cross-task handoff is the **SessionSummary** exactly as the
cross-phase handoff is `index.md`. A slice's `implement` phase therefore spans as many sessions as it
has tasks; this invocation implements one of them and stops.

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

It is a handoff to a future agent (the next session, with no memory of now). It answers, tersely:

- **Done** — the tasks completed so far, enough to not redo them. This **accumulates across sessions**:
  each session appends the one task it finished.
- **Next** — the single immediate next task and the exact place to start (the driver confirms this
  against the authoritative per-task status in `index.md`).
- **Open** — unresolved decisions, blockers, things to watch, deferred-but-noted scope items (including
  any follow-up task discovered mid-flight — surfaced here for `to-tasks`, never minted as a task by
  `implement` itself).
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
  session end, record it under **Open** so it isn't silently dropped. Because each task runs in its own
  top-level session (not a nested subagent), `doubt` can spawn its fresh-context reviewer normally — the
  one-task-per-session loop preserves that guarantee per task.
- **`verify`/`test`** is the per-task completion gate; the SessionSummary's **Done** should only list
  tasks that passed it.

## One-off composability

For a typo or single-task fix, the loop collapses: one session, one task, run `incremental`, verify,
done — no SessionSummary, no requirements ceremony. Materialize the session layer only when the
work actually spans sessions. (When a driver is persisting, its single-entry-point invariant still
holds regardless of size — but that's the driver's concern, not this skill's.)
