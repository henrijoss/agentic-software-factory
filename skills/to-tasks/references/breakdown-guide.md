# To-Tasks — Breakdown Guide (depth)

Loaded on demand by the `to-tasks` skill. The SKILL.md core stays lean; the dependency-graph method,
slicing, sizing, templates, and a worked example live here.

## The line against `design` (upstream) and `implement` (downstream)

| Concern | Belongs in | Why |
|---|---|---|
| Approach, architecture, key decisions, risks | **`design`** | the *how* — decided and approved before decomposition |
| Sized/ordered Tasks, dependency graph, checkpoints | **`to-tasks`** | decomposition of the approved approach — this skill |
| Writing the code, per-session discipline | **`implement`** + `incremental` | execution of a task |

If decomposition surfaces that the approach is wrong, **stop and return to `design`** — don't quietly
re-architect inside task breakdown.

## Step 2 — the dependency graph

Map what depends on what; implementation order follows it bottom-up (build foundations first):

```
Database schema
  ├── API models/types
  │     ├── API endpoints ── Frontend client ── UI components
  │     └── Validation logic
  └── Seed data / migrations
```

Then classify for scheduling:

- **Safe to parallelize:** independent feature slices, tests for already-built features, docs.
- **Must be sequential:** migrations, shared-state changes, dependency chains.
- **Needs coordination:** features sharing a contract — define the contract first, then parallelize.

## Step 3 — vertical slicing (not horizontal)

Build one complete path at a time, not all-of-each-layer:

```
Bad (horizontal):                 Good (vertical):
  Task 1: entire DB schema          Task 1: user can register   (schema + API + UI)
  Task 2: all API endpoints         Task 2: user can log in      (auth + API + UI)
  Task 3: all UI                    Task 3: user can create item (schema + API + UI)
  Task 4: connect everything        Task 4: user can list items  (query + API + UI)
```

Each vertical slice delivers working, testable functionality and mirrors the loop's slice unit and
the `incremental` posture's preferred strategy.

## Sizing

| Size | Files | Scope | Example |
|---|---|---|---|
| XS | 1 | single function/config | add a validation rule |
| S | 1–2 | one component/endpoint | add an API endpoint |
| M | 3–5 | one feature slice | registration flow |
| L | 5–8 | multi-component | search w/ filtering + pagination |
| XL | 8+ | **too large — break down** | — |

Agents perform best on S/M. Break a task down further when: it would take more than one focused
session; acceptance needs more than ~3 bullets; it touches two independent subsystems; or the title
contains "and".

## Task template (full)

```markdown
# [short descriptive title]

**Does:** [one paragraph — what this task accomplishes and why]

**Acceptance:**
- [ ] [specific, testable condition]
- [ ] [specific, testable condition]

**Verify:**
- [ ] tests pass: [command from the Constitution]
- [ ] build succeeds: [command from the Constitution]
- [ ] manual: [what to check, if applicable]

**Depends on:** [which other tasks, or none]
**Files likely touched:** [paths]
**Scope:** [XS | S | M]   (L+ → break down further)
```

## Step 4 — ordering & checkpoints

Order so that: dependencies are satisfied; each task leaves the system working; high-risk/uncertain
tasks come early (fail fast). Insert a checkpoint after each group:

```markdown
## Checkpoint — after TASK-01..03
- [ ] all tests pass, build clean
- [ ] core flow works end to end
- [ ] reviewed with human before proceeding
```

As a transition skill, fan-out is also a **feedback moment**: present the set and ordering and let the
user reshape it before the gate.

## Worked example — saved-search alerts

```
Dependency graph:
  saved_search table ── save-search API ── "Saved searches" UI
                    └── daily digest job ── email send (existing service)

Tasks (vertical, ordered):
  TASK-01 (S)  Save a search: table + POST endpoint + tests              depends: none
  TASK-02 (S)  List/delete saved searches: GET/DELETE + "Saved searches" UI   depends: 01
  TASK-03 (M)  Daily digest job: query new matches, dedupe, enqueue email     depends: 01
  TASK-04 (S)  Wire job → existing email service + idempotency key            depends: 03
  Checkpoint after 01–02: a user can save, see, and delete a search end to end.
```

Note: no architecture rationale here (that's the Plan) — just units of work, sized and ordered.

## Common rationalizations

| Rationalization | Reality |
|---|---|
| "I'll figure tasks out as I go" | That's how you get a tangled mess and rework. 10 min of breakdown saves hours. |
| "The tasks are obvious" | Write them anyway — explicit tasks surface hidden deps and forgotten edge cases. |
| "Acceptance criteria are overhead" | Without them `implement` and `verify` have nothing to check against. |
| "One big task is simpler" | Big tasks hide bugs and block parallelism; S/M tasks are where agents are reliable. |
