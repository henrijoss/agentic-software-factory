---
name: to-tasks
description: Fans one approved Plan out into N small, verifiable Tasks with a dependency graph — sized, ordered, each with acceptance and verification criteria, before implementation. The transition from design to implement. Use when a Plan is approved and needs decomposing into implementable units, when work needs ordering or parallelizing, or when a task feels too large to start. Distinct from `design` (which decides the approach): this splits an approved approach into work.
---

# To-Tasks

## Overview

`to-tasks` decomposes one approved **Plan** into **N Tasks** — small, independently verifiable units
with explicit acceptance criteria, arranged into a dependency graph and an implementation order. Good
decomposition is the difference between reliable execution and a tangled mess.

This is a **transition skill** (`to-<phase>`): it moves work *between* design and implement, and is
where **fan-out** happens (one Plan → many Tasks). It adds real logic — sizing, ordering, dependency
mapping — not just reformatting. It does **not** decide the approach (that's `design`, upstream) or
write code (that's `implement`, downstream).

## When to Use

- A Plan `[REQ-n.DESIGN]` is approved and needs decomposing into implementable units.
- Work needs ordering, checkpointing, or parallelizing across sessions/agents.
- A task feels too large or vague to start.

**When NOT to use:**

- Deciding the architecture/approach — that's `design`.
- A change whose single unit of work is obvious (go straight to `implement`).
- Writing the code — that's `implement`.

## Inputs / Outputs (abstract)

- **Input:** one approved **Plan** `[REQ-n.DESIGN]`, the **Constitution** `[CONST]` (for the
  project's build/test commands and boundaries — resolve them there, never hardcode), and the parent
  **Requirement** `[REQ-n]` for acceptance context.
- **Output:** N **Task** artifacts `[ID: REQ-n.TASK-m]` plus a dependency graph/order. Storage
  resolves through the `continue` base skill (default: `requirements/REQ-<n>/tasks/TASK-<m>.md`, each
  registered in `index.md`).

## Process

### 1. Read the approved Plan and context

Read the Plan `[REQ-n.DESIGN]`, the Requirement `[REQ-n]`, and `[CONST]`. Decompose the *approved*
approach — don't re-open design decisions here; if the approach turns out wrong, return to `design`.

### 2. Map the dependency graph

Identify what depends on what (e.g. schema → API → client → UI). Implementation order follows the
graph; foundations first. Note what can run in parallel vs. what must be sequential.

### 3. Slice vertically, size, and write tasks

Slice into vertical, end-to-end units (create → list → edit), not horizontal layers. Each Task is
**S–M sized** (1–5 files, one focused session); anything larger is broken down further. Each Task
carries acceptance criteria and a verification step (using `[CONST]` commands). See the task shape
below.

### 4. Order, checkpoint, fan out for feedback

Order so dependencies are satisfied, each task leaves the system working, and high-risk tasks come
early (fail fast). Add checkpoints between groups. As a transition skill, **pause for user feedback**
on the decomposition while fanning out — the task set and ordering are the user's to shape.

### 5. Write the Tasks in place

Write each Task via artifact-io (default `requirements/REQ-<n>/tasks/TASK-<m>.md`) and register each
`REQ-n.TASK-m` in `index.md`. Re-entry **updates tasks in place** — never fork a parallel set.

### 6. Gate → implement

Present the task set, dependency graph, and order, and force the decision: *"Are the tasks sized and
ordered, and is the dependency graph correct?"* This gate earns its interruption: `implement` commits
session-by-session to this decomposition. On explicit approval, hand off to `implement`.

## Task shape

Short form below; template, sizing table, slicing, and a worked example live in
`references/breakdown-guide.md`.

```markdown
# TASK-m — [short title]   (REQ-n.TASK-m)

**Does:** [one paragraph — what this task accomplishes]
**Acceptance:**
- [ ] [specific, testable condition]
**Verify:** [test / build / manual check — commands from CONST]
**Depends on:** [task IDs, or none]
**Scope:** [S: 1–2 files | M: 3–5 files]
```

## Composability (big↔small)

A small Plan may fan out to two or three Tasks with no checkpoints; a large one yields phased groups
with checkpoints and parallel tracks. Never inflate a small Plan into ceremony — the point is the
smallest set of well-ordered, verifiable units.

## Red Flags

- Re-opening or revising the approach — that's `design`; return there instead.
- Tasks that say "implement the feature" with no acceptance criteria.
- No verification step on a task; "and" in a task title (it's two tasks).
- All tasks L/XL-sized — decompose further (agents perform best on S/M).
- Dependency order not considered; no checkpoints between phases.
- Hardcoding `npm`/`tsc`/etc. instead of resolving commands from `[CONST]`.
- Fanning out without pausing for user feedback on the decomposition.

## Verification

- [ ] Decomposed the approved Plan; approach not re-opened.
- [ ] Dependency graph mapped; order satisfies it (foundations + high-risk first).
- [ ] Tasks vertically sliced; each S–M, none larger.
- [ ] Every task has acceptance criteria and a verification step (commands from `[CONST]`).
- [ ] User feedback taken on the decomposition during fan-out.
- [ ] Each Task written via artifact-io as `REQ-n.TASK-m` and registered in `index.md`.
- [ ] Re-entry updated tasks in place — no duplicate set.
- [ ] The gate decision was posed and explicit approval received before handing to `implement`.
