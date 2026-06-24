---
name: implement
description: Turns one Task into working code per invocation, handing off through `index.md` + the commit history so the next task starts in a fresh session and long features survive context limits. Runs the `incremental` posture for execution discipline and `doubt` for non-trivial decisions, gates the task on `verify`/`test`, and ends it with one semantic `commit`. Use to execute one task of an approved breakdown; for a one-off fix it runs on a single task with minimal ceremony. Not for deciding the approach (that's `design`) or splitting work (that's `to-tasks`).
---

# Implement

## Overview

`implement` executes a Task into working code — **exactly one task per invocation**, left verified and
committed, then it hands off. It is the phase where the plan becomes real; it does not decide *what* or
*how* (that's `specify`/`design`) or split the work (`to-tasks`).

The `design.md` and `tasks/` that drive `implement` are **ephemeral working scaffolding**, **removed
when the requirement's slice is finished**. What endures is the **code and its git history** — the
commits are the durable record of why something was built and what prior approaches to reuse; the
scaffolding files are not. Implement against them, but don't treat them as a permanent archive.

Two disciplines run *inside* implement rather than being re-specified here:

- **`incremental`** — the per-session rhythm (thin slices, keep-it-compilable, simplicity, scope).
  Invoke it; don't restate its rules.
- **`doubt`** — fresh-context adversarial review on any non-trivial decision before code stands.

The defining mechanism is the **fresh-context loop**, realized at the *task* level: this invocation
reads the **one** Task it was given plus the **cross-step handoff** — the last few commits (`git log -5`,
seeded by the loop) and `index.md`'s status — implements that task, verifies it, and ends it with **one
semantic commit**. It does **not** loop on to the next task — the driver ends the session and the
`loop.sh` fresh-process loop relaunches a brand-new session for the next task. So a long feature spans
many sessions, each starting fresh from the commit history + `index.md` rather than drifting on stale,
accumulated context (the field's top failure mode). There is no separate handoff file: the per-task
commit records *what shipped*, and the driver records *where we are / what's next* in `index.md`. The cross-task
loop is the *outer* process loop, not an inner in-session loop.

## When to Use

- Executing an approved task breakdown for a slice.
- A one-off fix: `implement` can run on a single task with minimal ceremony (no full tree).
- Resuming a slice mid-flight from `index.md` + the recent commits.

**When NOT to use:**

- Deciding the approach — `design`. Splitting work — `to-tasks`.
- Pure investigation/summary with no code change.

## Inputs / Outputs (abstract)

- **Input:** the **single Task** to implement this invocation, the **Plan** for context, the
  **Constitution** (commands, boundaries — resolve commands there, never hardcode), and the **cross-step
  handoff** (the last few commits + `index.md`'s status) when resuming — all provided by the caller (the
  driver selects which task). If the caller provides a **doubt-pass count**, run that many `doubt` passes
  on non-trivial decisions; otherwise use your own judgment.
- **Output:** working **code**, written directly to the source tree (that is the skill's real work),
  captured as **one semantic commit** (the `commit` skill), plus a lightweight **per-task result**
  (outcome + next pointer) emitted per the result contract for the driver to record in `index.md`. The
  skill writes code and commits, but resolves no SDLC storage and does not touch the artifact tree/index
  itself.

## Process (the fresh-context loop)

### 1. Load only what this task needs

Read the **cross-step handoff** (the last few commits + `index.md`'s status, if resuming), the current
Task, the relevant slice of the Plan, and the **Constitution**. Load the *right* sections and source
files — not the whole spec tree. Flooding context is what causes drift.

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

### 5. Commit the task via `commit`

Once verified, call **`commit`** to record this task as **one semantic commit** on `main` — clean,
granular per-task history. **Exception:** under an `auto`/loop run that defers committing to the loop,
skip this step and let the loop commit the task after the session ends (don't double-commit).

### 6. Emit the per-task result (handoff)

Once this task is committed, emit a lightweight result: this task's **outcome** (`done`, or `blocked`
with why), the immediate **next** task and where to start, and any **open** issues/decisions or
follow-ups (surfaced for `to-tasks`, never minted as tasks here). The commit already records *what
shipped*; this result tells the driver *where we are / what's next* so it can update `index.md`'s **Last
worked** / **Suggested next** and the per-task status. No separate handoff file is written. Emit it per
the result contract; the driver records it.

### 7. Gate, then the session ends

When the task is implemented and verified, force the decision: *"Does this task do what it claims, and
which verification level applies?"* Surface it for the caller — standalone, present it to the user;
under a driver, the driver holds it. The skill is a pure transform and doesn't know whether other tasks
remain: it emits its per-task result and stops. The **driver** decides from `index.md` whether this was
the last task (the implement→verify gate) or just one of many (stop, next session picks the next task).
Either way this session ends here — `implement` never rolls straight into the next task.

## Per-task result shape

Short form below; the fresh-context rationale, context-loading discipline, and what the handoff must
convey live in `references/session-loop.md`. This is a lean report for the driver to fold into
`index.md` — not an artifact written to the tree (the commit is the durable record of what shipped).

```markdown
**Outcome:** [done | blocked: <why>]
**Next:** [the immediate next task + where to start]
**Open:** [unresolved decisions, blockers, follow-ups for `to-tasks`]
**Touched:** [key files/areas changed]
```

## Composability (big↔small)

A one-off fix needs no handoff ceremony (single session, single task): run `incremental`, verify,
commit. A multi-session feature leans on `index.md` + the commit history every resume. Don't manufacture
ceremony for a job that fits in one pass.

## Red Flags

- Restating `incremental`'s rules instead of invoking the posture.
- Loading the whole spec/tree into context instead of the task's slice (invites drift).
- Implementing past the task's scope ("while I'm here") — that's `incremental`'s scope rule, enforce it.
- **Rolling on to the next task in the same invocation** ("might as well keep going") instead of
  committing, emitting the result, and stopping — that recreates the ever-growing-session failure mode at
  task granularity, the exact thing the one-task-per-session loop exists to prevent.
- Skipping `verify`/`test` and declaring a task done.
- Ending a task without a `commit` (outside an `auto`/loop deferral) — the per-task history *is* the
  handoff (next session reads `git log -5`); skipping it leaves the next session blind.
- Ending the task without emitting the per-task result — the driver can't update `index.md`.
- Asserting a non-trivial decision is correct without running `doubt`.
- Resolving SDLC storage / touching the tree or `index.md` instead of emitting the result (driver's job).
- Hardcoding build/test commands instead of resolving from the **Constitution**.

## Verification

- [ ] **Exactly one task** implemented this invocation; the per-task result's **Next** names the task
      for the following session, and the session ended rather than rolling into it.
- [ ] Only the task's relevant context was loaded — not the whole tree.
- [ ] Work executed via the `incremental` posture (thin slices, compilable, scope held).
- [ ] `doubt` run on non-trivial decisions before they stood.
- [ ] Each task driven to its acceptance criteria and gated on `verify`/`test`.
- [ ] Verified task recorded as **one semantic commit** via `commit` — unless an `auto`/loop run defers
      the commit to the loop.
- [ ] Per-task result emitted per the result contract (outcome / next / open / touched) — not persisted
      by the skill itself; the commit records what shipped.
- [ ] Commands resolved from the **Constitution**, not hardcoded.
- [ ] The gate decision was posed (caller/driver holds it).
