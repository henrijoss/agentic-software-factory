# To-Requirements — Decomposition Guide (depth)

Loaded on demand by the `to-requirements` skill. Stakeholder identification, use-case decomposition,
sequencing, the template, a worked example, and the handoff shape `clarify`/`design` expect.

## The line against `specify` (upstream) and `clarify` (downstream)

| Concern | Belongs in | Why |
|---|---|---|
| Objective, scope, success for the whole effort | **`specify`** | the singular what/why — decided before fan-out |
| Stakeholders + N use-case Requirements; sequencing | **`to-requirements`** | the fan-out — this skill |
| Deepening one Requirement to ready (deep-dive) | **`clarify`** | per-requirement detail before design |
| The approach for one Requirement | **`design`** | the how |

Keep requirements **draft-level** here. Over-specifying one now wastes effort if it isn't the first
slice and duplicates what `clarify` will do properly.

## Identifying stakeholders (Step 2)

A stakeholder is anyone who cares about the outcome and what they need from it — primary users, but
also operators, reviewers, downstream consumers, the business. For each: who they are and the need
the work must serve. Stakeholders are the *why* behind requirements; the every-requirement-hangs-off-
a-use-case rule (no standalone enablers) is what keeps the backlog tied to real value.

## Use-case decomposition (Step 3)

Fan the spec's scope into discrete units of behavior/value. Good requirements are:

- **Vertical** — one complete path that delivers value end to end, not a layer ("the database").
- **Independent-ish** — can be built and shipped on its own slice; minimal hidden coupling.
- **Valuable** — a stakeholder is better off when it's done (state who and how).
- **Right-sized** — one use-case, not a bundle. "And" in the title usually means two requirements.

This mirrors the loop's vertical-slice unit and the vertical slicing that
`to-tasks` and `incremental` use further down — the slice identity is set here.

## Sequencing — choosing the first slice (Step 4)

The loop runs one slice at a time, so order matters. Recommend a first slice by one explicit
criterion:

- **Thinnest end-to-end** — proves the whole path works with the least code (good default for a new
  project / walking skeleton).
- **Highest risk** — surfaces the scariest unknown first (pairs with `incremental` risk-first
  slicing and `design`/`doubt`).
- **Highest value** — ships the most-wanted capability first.

State which you used so the user can override with their own priority.

## Requirement template (full)

```markdown
# [use-case title]

**As a** [stakeholder] **I want** [capability] **so that** [value].

**Acceptance (draft):**
- [signal this use-case is satisfied — clarify will sharpen into testable criteria]

**Stakeholders:** [stakeholder, …]
**Depends on:** [other requirements, or none]
**Open questions:**
- [what clarify must resolve before this can be designed]
```

What `clarify` and `design` expect from this: a single, vertically-sliced use-case with its
stakeholder(s), draft acceptance signals, and the open questions to resolve. `clarify` turns the
draft acceptance + open questions into ready, unambiguous criteria; `design` then plans against the
ready Requirement. Keep the shape stable so the handoff is clean.

## Worked example — "experiment tracker" spec → requirements

```markdown
Stakeholders:
- Researcher (me) — needs to not lose track of running experiments.
- Teammate — occasionally needs to see what's running.

Requirements (draft, sequenced):
# Register an experiment
As a Researcher I want to add an experiment with its hypothesis so that there's one list, not five docs.
Acceptance (draft): can add an experiment; it appears in a single list.
Stakeholders: Researcher   Open questions: which fields are required?

# See running experiments at a glance
As a Researcher I want a status view so that I know what's live without hunting.
Acceptance (draft): a view shows each experiment's status. Depends on: Register an experiment
Stakeholders: Researcher, Teammate   Open questions: what statuses exist?

First slice: Register an experiment (thinnest end-to-end — nothing else works without the list existing).
```

Note: no UI/tech detail (that's `design`) and no fully-nailed acceptance (that's `clarify`) — just
the right vertical use-cases, their stakeholders, and a justified first slice.

## Anti-patterns

- **Enabler requirements.** "Set up the database" as a standalone requirement — it serves no use-case
  directly. Fold infrastructure into the first slice that needs it.
- **Horizontal decomposition.** Splitting by layer instead of by user-visible value.
- **Premature depth.** Writing full acceptance criteria for every requirement here; `clarify` does
  that for the slice actually being built next.
- **Orphan stakeholders / orphan requirements.** A stakeholder no requirement serves, or a
  requirement no stakeholder needs — cut it.
- **No first-slice recommendation.** Handing back an unordered pile; the loop needs a starting point.
