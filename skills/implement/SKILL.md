---
name: implement
description: Turns a slice's Tasks into working code, one task at a time, in a fresh-context loop that hands off through a SessionSummary so long features survive context limits. Runs the `incremental` posture for execution discipline and `doubt` for non-trivial decisions, and gates each task on `verify`/`test`. Use to execute an approved task breakdown; for a one-off fix it can run on a single task with minimal ceremony. Not for deciding the approach (that's `design`) or splitting work (that's `to-tasks`).
---

# Implement

## Overview

`implement` executes Tasks into working code — **one task at a time**, each task left verified and
committed before the next. It is the phase where the plan becomes real; it does not decide *what* or
*how* (that's `specify`/`design`) or split the work (`to-tasks`).

Two disciplines run *inside* implement rather than being re-specified here:

- **`incremental`** — the per-session rhythm (thin slices, keep-it-compilable, simplicity, scope).
  Invoke it; don't restate its rules.
- **`doubt`** — fresh-context adversarial review on any non-trivial decision before code stands.

The defining mechanism is the **fresh-context loop**: each session reads the Task plus the prior
**SessionSummary**, does a bounded piece of work, and writes the SessionSummary back — so a long
feature survives context limits without the agent drifting on stale, accumulated context (the field's
top failure mode).

## When to Use

- Executing an approved task breakdown for a slice.
- A one-off fix: `implement` can run on a single task with minimal ceremony (no full tree).
- Resuming a slice mid-flight from its SessionSummary.

**When NOT to use:**

- Deciding the approach — `design`. Splitting work — `to-tasks`.
- Pure investigation/summary with no code change.

## Inputs / Outputs (abstract)

- **Input:** the slice's **Tasks**, the **Plan** for context, the **Constitution** (commands,
  boundaries — resolve commands there, never hardcode), and the prior **SessionSummary** when resuming
  — all provided by the caller. If the caller provides a **doubt-pass count**, run that many `doubt`
  passes on non-trivial decisions; otherwise use your own judgment.
- **Output:** working **code**, written directly to the source tree (that is the skill's real work),
  plus an updated **SessionSummary** emitted per the result contract for the caller to ingest. The
  skill writes code, but resolves no SDLC storage and does not touch the artifact tree/index itself.

## Process (the fresh-context loop)

### 1. Load only what this task needs

Read the **SessionSummary** (if resuming), the current Task, the relevant slice of the Plan, and the
**Constitution**. Load the *right* sections and source files — not the whole spec tree. Flooding
context is what causes drift.

### 2. Implement the task via `incremental`

Run the **`incremental`** posture: smallest complete slice → verify → commit → next, keeping the tree
compilable and scope tight. Use the project's commands from the **Constitution**. Build the simplest
thing that satisfies the task's acceptance criteria.

### 3. Doubt the non-trivial decisions

On any non-trivial decision (branching logic, boundary crossing, an unverifiable property, an
irreversible change), run the **`doubt`** posture before it stands. Fold findings back into the code.

### 4. Verify against acceptance criteria

Drive the task to its acceptance criteria and call **`verify`/`test`** as the completion gate for the
task. A task is not done until its acceptance criteria are met and confirmed.

### 5. Emit the SessionSummary handoff

Before the session ends (or context fills), produce the SessionSummary: what's done, what's next, open
issues/decisions, and where to resume. This is what lets the next fresh-context session continue
without re-reading everything. Emit it per the result contract; the driver persists it (overwriting the
prior summary in place).

### 6. Gate

When the task (or slice) is implemented, force the decision: *"Does the slice do what the task
claims, and which verification level applies?"* Surface it for the caller — standalone, present it to
the user; under a driver, the driver holds the gate.

## SessionSummary shape

Short form below; the fresh-context rationale, context-loading discipline, and full template live in
`references/session-loop.md`.

```markdown
# Session — [slice]

**Done:** [tasks/changes completed this slice]
**Next:** [the immediate next task + where to start]
**Open:** [unresolved decisions, blockers, things to watch]
**Touched:** [key files/areas changed]
```

## Composability (big↔small)

A one-off fix may skip the SessionSummary entirely (single session, single task) and just run
`incremental`. A multi-session feature leans on the SessionSummary every resume. Don't manufacture
session ceremony for a job that fits in one pass.

## Red Flags

- Restating `incremental`'s rules instead of invoking the posture.
- Loading the whole spec/tree into context instead of the task's slice (invites drift).
- Implementing past the task's scope ("while I'm here") — that's `incremental`'s scope rule, enforce it.
- Skipping `verify`/`test` and declaring a task done.
- Letting context fill without producing the SessionSummary — the next session resumes blind.
- Asserting a non-trivial decision is correct without running `doubt`.
- Resolving SDLC storage / touching the tree instead of emitting the SessionSummary (driver's job).
- Hardcoding build/test commands instead of resolving from the **Constitution**.

## Verification

- [ ] Only the task's relevant context was loaded — not the whole tree.
- [ ] Work executed via the `incremental` posture (thin slices, compilable, scope held).
- [ ] `doubt` run on non-trivial decisions before they stood.
- [ ] Each task driven to its acceptance criteria and gated on `verify`/`test`.
- [ ] SessionSummary emitted per the result contract (done / next / open / touched) — not persisted by
      the skill itself.
- [ ] Commands resolved from the **Constitution**, not hardcoded.
- [ ] The gate decision was posed (caller/driver holds it).
