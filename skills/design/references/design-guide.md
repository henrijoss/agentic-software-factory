# Design — Authoring Guide (depth)

Loaded on demand by the `design` skill. The SKILL.md core stays lean; the boundary tests, template,
worked example, and anti-patterns live here.

## What design is — and the line against `to-tasks`

Design decides the *approach*; `to-tasks` decomposes that approach into work. They are the two halves
the example drafts conflated (a single "produce a plan and split it into tasks" skill). Keeping them
split lets the human approve the *approach* at one gate before any decomposition commits to it.

| Concern | Belongs in | Why |
|---|---|---|
| What the slice must achieve, success criteria | **Spec** / Requirement | the *what*, decided upstream |
| Approach, architecture, key decisions, risks | **Design** | the *how* — this skill |
| Sized, ordered tasks; dependency graph; checkpoints | **`to-tasks`** | decomposition of an approved approach |
| Stack, conventions, boundaries | **Constitution** | standing — design inherits, never restates |

Discriminator: if a line is a *unit of work to schedule*, it's a task (→ `to-tasks`); if it's a
*decision about how the pieces fit*, it's design.

## Plan-mode investigation (Step 1)

Design with the grain of the codebase, not against it. Before choosing an approach, read-only:

- the patterns and conventions already in use for this kind of work;
- the components/modules this requirement will touch and how they're structured;
- existing contracts (types, interfaces, APIs) the new work must fit;
- prior decisions (ADRs, the constitution) that constrain the space.

Write no code. The output is a plan a human can read and say "yes, that's the right approach" or
"no, change X."

## Architecture-decision discipline

Each key decision records the choice **and** why — including the alternative you rejected. A decision
without a rejected alternative is usually not a real decision (there was only one option) or hides
the reasoning the gate needs. Keep it to one line each:

```
- Store saved searches as rows in a `saved_search` table, not as a JSON blob on the user —
  enables per-search indexing and deletion; blob would force rewrites and block querying.
```

## Risks & mitigations

Surface what could go wrong while it's still cheap to change direction. A compact table is enough:

| Risk | Impact | Mitigation |
|---|---|---|
| Daily digest job overlaps with backfill | Med | idempotent job keyed by (user, date) |
| Query cost grows with saved-search count | Low | cap saved searches per user at v1 |

High-impact or uncertain risks are exactly what the `doubt` posture (Step 4) should cross-examine
before the plan stands.

## Full template

```markdown
# Design — [requirement title]

## Approach
<!-- The shape of the solution in a few sentences: key components, data flow, integration points. -->

## Key decisions
<!-- Each: the decision + rationale + the alternative rejected. One line each. -->
- [decision] — [why; alternative rejected]

## Risks & mitigations
<!-- What could go wrong and the plan for it. Table or bullets. -->
- [risk] → [mitigation]

## Open questions
<!-- Unresolved items needing human input. Delete the section if none. -->
- [question]
```

Sections beyond Approach are optional; delete what doesn't apply rather than leaving empty headers.

## Worked example

```markdown
# Design — saved-search alerts

## Approach
Persist each saved search as a row keyed to the user. A daily scheduled job re-runs each saved
query against items created since its last run, collects matches per user, and enqueues one digest
email. Reuse the existing search query builder and the existing email-send service — no new
infra beyond the table and the job.

## Key decisions
- Daily batch job, not real-time triggers — spec scopes a daily digest; triggers add infra and
  duplicate-suppression complexity for no v1 value.
- Dedupe by (saved_search_id, item_id) seen-set — prevents re-sending the same item if the job
  re-runs; alternative (last-run timestamp only) double-sends on overlap.

## Risks & mitigations
- Job overlap re-sends items → make the job idempotent, keyed by (user, date).
- Search-query reuse drifts if the search feature changes → one shared query builder, covered by
  the existing search tests.

## Open questions
- Digest send time fixed at 08:00 member-local, or configurable? (assume fixed for v1)
```

Note: no task list, no sizing, no ordering — that's `to-tasks`. No mention of the project's stack or
"run tests before commit" — that's the constitution.

## Re-entry (anti-staleness)

When implementation reveals the approach was wrong, re-run `design` and emit the revised plan — the
driver **overwrites the existing design in place** on ingest, never a parallel copy. Update the design
*first*, then let `to-tasks`/`implement` re-derive from it.

## Anti-patterns

- **Task leakage.** Listing "Task 1, Task 2…" with sizes and order. That's `to-tasks`; design stops
  at the approach.
- **Designing against the grain.** Inventing a new pattern when the codebase already has one, because
  Step 1 was skipped.
- **Over-architecture.** Abstractions, layers, and extensibility a thin slice doesn't need —
  violates the constitution's simplicity default. Build the simplest approach that satisfies the
  requirement.
- **Decisions without rationale.** "Use a queue" with no why and no rejected alternative — the gate
  can't evaluate it.
- **Confident architecture, no doubt.** Asserting thread-safety/idempotence/ordering without running
  the `doubt` posture on it.
