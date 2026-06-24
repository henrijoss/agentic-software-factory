# Implement — Fresh-Context Loop (depth)

Loaded on demand by the `implement` skill. The SKILL.md core states the loop; the rationale, the
context-loading discipline, and what the per-task handoff must convey live here.

## Why a fresh-context loop

A long feature exceeds what one context window holds reliably. Two bad alternatives:

- **One ever-growing session** — context fills with stale detail; assumptions made early harden into
  "facts"; compliance with instructions degrades as the window saturates. The agent drifts and starts
  executing confidently against a stale picture (this skillset's top documented failure mode).
- **Restarting cold each time** — the next session re-derives everything, slowly and inconsistently.

The fresh-context loop is the middle path: each session starts clean but reads a small, current
**handoff** plus the specific Task. That handoff is **the git history (the last few commits) +
`index.md`'s status** — what just shipped and what's next — not an ever-longer conversation. State lives
in committed code and the index, not in the session; the session is disposable.

There is **no separate inner in-session loop**: one task = one session = one step. The per-**task** loop
*is* the driver-level per-**step** fresh-process loop the `continue` base skill defines in
`references/fresh-context.md` — `skills/continue/loop.sh` relaunches a brand-new session for each task
and seeds it with `git log -5` + `index.md`'s *Suggested next*, so each task gets truly fresh context.
The cross-task handoff is the **commit history + `index.md`** exactly as the cross-phase handoff is
`index.md`. A slice's `implement` phase therefore spans as many sessions as it has tasks; this
invocation implements one of them, commits it, and stops.

## Context-loading discipline (Step 1)

Load the *right* slice, not everything:

- the last few commits (`git log -5`, seeded by the loop) + `index.md`'s status (where we are / what's
  next) + the current Task;
- only the Plan sections relevant to this task;
- only the source files this task touches, plus their direct collaborators;
- the **Constitution** for commands and boundaries.

Do **not** load the whole spec tree, every requirement, or the entire codebase. More context is not
more capability past the point where the signal is diluted — it's the cause of drift, not a defense
against it.

## What the per-task handoff must convey

There is no separate handoff file. The handoff to the next (memoryless) session is carried by two
durable things the loop already surfaces:

- **The commit** — one semantic `commit` per task (see the `commit` skill) is the record of *what
  shipped and why*. Clean, granular per-task history means `git log -5` tells the next session what just
  happened without a separate summary. Write the commit message so it does that job.
- **`index.md`'s status** — the driver updates **Last worked** (this task/phase) and **Suggested next**
  (the immediate next unit) on ingest; the next session reads them, confirmed against the authoritative
  per-task status in the ID registry.

A follow-up task discovered mid-flight is **not** minted by `implement`; surface it for `to-tasks` (and
note it in the commit body if it bears on the change). An unresolved `doubt` cycle, a blocker, or a
deferred scope item belongs in the commit body and, if it blocks progress, flips the task's status to
`blocked` in `index.md` so it isn't silently dropped.

## How it nests with the postures

- **`incremental`** governs *within* a session: thin slices, verify each, keep compilable, hold scope.
  The commit records the boundary *between* sessions.
- **`doubt`** is invoked at decision points inside a session; if a doubt cycle is left unresolved at
  session end, record it in the commit body (and set `blocked` if it stops the task) so it isn't lost.
  Because each task runs in its own top-level session (not a nested subagent), `doubt` can spawn its
  fresh-context reviewer normally — the one-task-per-session loop preserves that guarantee per task.
- **`verify`/`test`** is the per-task completion gate; only a task that passed it should be committed as
  `done`.

## One-off composability

For a typo or single-task fix, the loop collapses: one session, one task, run `incremental`, verify,
commit, done — no requirements ceremony. (When a driver is persisting, its single-entry-point invariant
still holds regardless of size — but that's the driver's concern, not this skill's.)
