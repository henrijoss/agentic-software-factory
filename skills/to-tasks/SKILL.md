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

The `tasks/` it feeds are **ephemeral working scaffolding** — throwaway units for building one
requirement's slice, **removed when that slice is finished**. The durable record of what was built and
why lives in the **git commits/tree**, not in the task files. Decompose for execution, not for posterity.

## When to Use

- A Plan is approved and needs decomposing into implementable units.
- Work needs ordering, checkpointing, or parallelizing across sessions and agents.
- A task feels too large or vague to start.

**When NOT to use:**

- Deciding the architecture/approach — that's `design`.
- A change whose single unit of work is obvious (go straight to `implement`).
- Writing the code — that's `implement`.

## Inputs / Outputs (abstract)

- **Input:** one approved **Plan**, the **Constitution** (for the project's build/test commands and
  boundaries — resolve them there, never hardcode), and the parent **Requirement** for acceptance
  context — all provided by the caller.
- **Output:** N **Tasks** plus a dependency graph/order. As a transition skill it fans out to **many**
  artifacts, so it writes one **scratch file per Task** under `.sdlc/scratch/` (each with
  result-contract front-matter) plus the dependency graph/order; the driver ingests them into the tree.
  The skill writes only scratch — never the tree or `index.md`.

## Process

### 1. Read the approved Plan and context

Read the **Plan**, the **Requirement**, and the **Constitution**. Decompose the *approved*
approach — don't re-open design decisions here; if the approach turns out wrong, return to `design`.

### 2. Map the dependency graph

Identify what depends on what (e.g. schema → API → client → UI). Implementation order follows the
graph; foundations first. Note what can run in parallel vs. what must be sequential.

### 3. Slice vertically, size, and write tasks

Slice into vertical, end-to-end units (create → list → edit), not horizontal layers. Each Task is
**S–M sized** (1–5 files, one focused session); anything larger is broken down further. Each Task
carries acceptance criteria and a verification step (using the **Constitution**'s commands). See the
task shape below.

### 4. Order, checkpoint, fan out for feedback

Order so dependencies are satisfied, each task leaves the system working, and high-risk tasks come
early (fail fast). Add checkpoints between groups. As a transition skill, **pause for user feedback**
on the decomposition while fanning out — the task set and ordering are the user's to shape.

### 5. Write the fan-out to scratch

Write one file per Task under `.sdlc/scratch/` plus the dependency graph/order, each with the
result-contract front-matter. Write **only** scratch; the driver ingests the tasks into the tree,
assigns IDs, and updates any existing set in place.

### 6. Gate

Present the task set, dependency graph, and order, and force the decision: *"Are the tasks sized and
ordered, and is the dependency graph correct?"* This gate earns its interruption: `implement` commits
session-by-session to this decomposition. Surface it for the caller — standalone, present it to the
user; under a driver, the driver holds the gate and advances to `implement`.

## Task shape

Short form below; template, sizing table, slicing, and a worked example live in
`references/breakdown-guide.md`.

```markdown
# [short task title]

**Does:** [one paragraph — what this task accomplishes]
**Acceptance:**
- [ ] [specific, testable condition]
**Verify:** [test / build / manual check — commands from the Constitution]
**Depends on:** [which other tasks, or none]
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
- Hardcoding `npm`/`tsc`/etc. instead of resolving commands from the **Constitution**.
- Fanning out without pausing for user feedback on the decomposition.
- Writing into the tree/`index.md` instead of scratch files (the driver ingests scratch).

## Verification

- [ ] Decomposed the approved Plan; approach not re-opened.
- [ ] Dependency graph mapped; order satisfies it (foundations + high-risk first).
- [ ] Tasks vertically sliced; each S–M, none larger.
- [ ] Every task has acceptance criteria and a verification step (commands from the **Constitution**).
- [ ] User feedback taken on the decomposition during fan-out.
- [ ] Fan-out written to `.sdlc/scratch/` per the result contract (a file per Task + dep graph);
      nothing written to the tree/`index.md` by the skill.
- [ ] The gate decision was posed (caller/driver holds it and advances to `implement`).
