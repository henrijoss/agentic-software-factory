---
name: design
description: Turns one Requirement into a Plan — the implementation approach, architecture, and risks for a single unit of behavior, before any tasks or code. The *how* to `specify`'s *what*. Use when a requirement is ready to design against and the approach isn't obvious, when an architectural decision is in play, or when re-entering to revise the approach as understanding shifts. Distinct from `to-tasks` (which splits the plan into tasks): design decides the approach, it does not decompose it.
---

# Design

## Overview

A design says **how** one Requirement will be built: the approach, the architecture, the key
decisions and their rationale, and the risks. It is the counterpart to the spec's *what* — produced
per requirement, before any tasks or code.

Keep design at the **approach/architecture** altitude. Decomposing the approach into sized, ordered
tasks is `to-tasks`, the next skill — design produces the Plan, `to-tasks` splits it. Letting task
breakdown leak into design conflates the two halves the architecture deliberately keeps split.

## When to Use

- A Requirement is ready to design against and the approach isn't obvious.
- An architectural decision is in play (structure, boundaries, data flow, a tech choice).
- Re-entering to revise the approach as understanding shifts during implementation.

**When NOT to use:**

- Splitting the plan into tasks — that's `to-tasks`.
- The *what*/scope of the work — that's `specify`/the Requirement.
- A change whose approach is self-evident (go straight to `to-tasks`/`implement`).

## Inputs / Outputs (abstract)

- **Input:** one **Requirement**, the **Constitution** (always), and any prior **Plan** when
  re-entering — all provided by the caller. If the caller provides a **doubt-pass count**, run that many
  `doubt` passes on non-trivial decisions; otherwise use your own judgment.
- **Output:** the **Plan**, emitted per the result contract for the caller to ingest. The skill writes
  no files and resolves no storage.

## Process

### 1. Read context, investigate read-only

Read the **Constitution** and the **Requirement** (and the prior Plan if re-entering). Investigate the
codebase **read-only**: identify existing patterns, conventions, and components to design *with*, not
against. Map where this requirement touches the system. This read **is** the system's home for
fine-grained current state — done live on every entry, so it cannot go stale; design against the actual
code, never against a persisted snapshot of it. Write no code here — the output is a plan.

### 2. Choose the approach

Decide the structure: key components, data flow, integration points, and the one or two decisions
that shape everything else. Stay at architecture altitude — *how the pieces fit*, not the task list.
Honor the constitution's trade-off defaults (e.g. simplicity until a third use case demands the
abstraction) — don't over-architect a thin slice.

### 3. Surface risks, unknowns, and open questions

Name what could go wrong and how you'd mitigate it; list what you don't yet know. Risks the human
must weigh belong here, not buried in prose — they are most of what the gate decides on.

### 4. Doubt the non-trivial decisions

Before the plan stands, run the **`doubt` posture** on any non-trivial architectural decision —
boundary crossings, irreversible choices, properties the compiler can't verify, decisions made under
uncertainty. Fold findings back into the approach.

### 5. Emit the result

Emit the Plan per the result contract — the body plus its gate decision — for the caller to ingest.
Write no files and resolve no storage; persistence and any re-entry overwrite are the driver's job.

### 6. Gate

Force the decision: *"Is the approach and architecture sound, and are the risks acceptable?"* This gate
earns its interruption: tasks and code commit to this approach. Surface it for the caller — standalone,
present it to the user; under a driver, the driver holds the gate.

## Artifact shape

Short form below; template, the design-vs-tasks boundary, and a worked example live in
`references/design-guide.md`.

```markdown
# Design — [requirement title]

## Approach
[How it will be built, in a few sentences. The shape of the solution.]

## Key decisions
- [decision] — [why; alternative rejected]

## Risks & mitigations
- [risk] → [mitigation]

## Open questions
[Unresolved items needing human input — delete if none.]
```

## Composability (big↔small)

A thin slice may have a three-line approach and one risk; a load-bearing requirement carries key
decisions, several risks, and open questions. Never pad to fill the template — empty sections cost
the reader's budget at the gate and downstream.

## Red Flags

- Decomposing into tasks — that's `to-tasks` leaking down.
- Designing against existing conventions instead of with them (skipped Step 1 investigation).
- Over-architecting a thin slice against the constitution's simplicity default.
- Asserting a non-trivial decision is sound without running `doubt`.
- Key decisions with no rationale / no rejected alternative.
- Writing code during design.
- Writing files / resolving storage instead of just emitting the result (that's the driver's job).

## Verification

- [ ] Constitution and Requirement read; codebase investigated read-only (design with conventions).
- [ ] Approach stated at architecture altitude — no task decomposition.
- [ ] Key decisions carry rationale (and the alternative rejected).
- [ ] Risks and unknowns surfaced with mitigations.
- [ ] `doubt` run on non-trivial decisions before the plan stood.
- [ ] Emitted per the result contract; no files written / no storage resolved by the skill.
- [ ] The gate decision was posed (caller/driver holds it).
