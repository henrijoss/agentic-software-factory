# Specify — Authoring Guide (depth)

Loaded on demand by the `specify` skill. The SKILL.md core stays lean; the template, the
reframe-as-success-criteria technique, a worked example, and the boundary tests live here.

## What the spec is — and what it isn't

The spec answers three questions for **one slice**: what are we building, why, and how do we know
it's done. It is deliberately narrow:

| Concern | Belongs in | Why |
|---|---|---|
| Stack, commands, conventions, boundaries | **Constitution** `[CONST]` | Standing, cross-feature — the spec inherits them, never repeats them (two copies drift). |
| Objective, scope, success criteria | **Spec** `[SPEC]` | This slice's what + why. |
| Architecture, approach, risks | **Design** `[REQ-n.DESIGN]` | The *how*; decided per requirement after fan-out. |
| Use-cases, stakeholders | **`to-requirements`** | Fan-out happens at the transition, not in the spec. |
| Task sizing, ordering | **`to-tasks`** | Decomposition is a separate transition. |

The discriminator: if a line describes *how* to build it, it's design; if it holds across every
slice, it's the constitution; if it's *what this slice must achieve*, it's the spec.

## The vertical-slice rule

The unit of iteration is one thin end-to-end slice (loop principle 2), not a layer and not the whole
product. A good slice delivers a complete, demonstrable piece of value — narrow but full-depth. This
is what lets the loop run specify→…→review and then come back for the next slice, updating the same
spec in place rather than spec'ing everything up front (which would go stale before code caught up).

## Reframe instructions as success criteria

Vague asks are conventions, not goals. Translate them into conditions `verify`/`review` can check:

```
ASK:   "make the dashboard faster"
SUCCESS CRITERIA:
- LCP < 2.5s on a 4G connection
- initial data load completes < 500ms
- no layout shift during load (CLS < 0.1)
→ Are these the right targets?
```

```
ASK:   "add search"
SUCCESS CRITERIA:
- a user can find any published item by title substring in < 1s
- empty/no-match states are handled
- out of scope: fuzzy/semantic search, searching drafts
→ Right shape?
```

Concrete criteria give the whole downstream loop a target to iterate toward instead of guessing what
"faster" or "better" meant.

## Surfacing assumptions

When you must assume something to proceed, state it as a correctable list rather than burying it in
prose — assumptions are the most dangerous form of misunderstanding because they're invisible:

```
ASSUMPTIONS:
1. Web app, not native mobile.
2. "Users" means signed-in members, not anonymous visitors.
3. Search covers published content only.
→ Correct me now or I proceed with these.
```

If more than one or two assumptions are load-bearing, that's a signal to run `interview` instead.

## Full template

```markdown
# Spec — [slice / feature name]

## Objective
<!-- What we're building and why it matters now; who benefits. 1–3 lines. -->

## Scope
- In:  <!-- what this slice covers, end to end -->
- Out: <!-- what it explicitly does NOT — the non-goals -->

## Success criteria
<!-- Specific, testable conditions. Each is something verify/review can check. -->
- [condition]

## Open questions
<!-- Unresolved items needing human input. Delete the section if none. -->
- [question]
```

Sections beyond Objective/Scope/Success are optional; delete what doesn't apply rather than leaving
empty headers.

## Worked example

```markdown
# Spec — saved-search alerts

## Objective
Let a member save a search and get notified when new matching items appear, so they stop
re-running the same query manually. Driven by repeated "did anything new show up?" support asks.

## Scope
- In:  save a query; a daily check for new matches; one email digest per member per day.
- Out: real-time/push notifications; in-app notification center; non-email channels.

## Success criteria
- A member can save a search from the results page and see it listed under "Saved searches".
- When a new item matches a saved search, the member receives it in the next daily digest.
- No digest is sent when there are zero new matches.
- A member can delete a saved search and stop receiving its alerts.

## Open questions
- Digest send time — fixed (e.g. 08:00 member-local) or member-configurable? (assume fixed for v1)
```

Note: no mention of the queue, the cron mechanism, or the email provider — that's `design`. No
mention of the project's stack or "always run tests" — that's the constitution.

## Re-entry (anti-staleness)

Scope shifts as the slice is built (loop principle 3). When it does, re-run `specify` — it
**overwrites `spec.md` in place**. Never create `spec-v2.md` or a parallel section. Gate-validation
at the next gate confirms no reference went stale. Update the spec *first*, then let the change flow
downstream — never let code silently diverge from it.

## Anti-patterns

- **Big design up front.** Spec'ing the entire product before any slice ships — the spec goes stale
  before code catches it, the exact failure this skillset fights.
- **Constitution smuggling.** Restating stack/commands/boundaries. Now there are two copies; one
  drifts.
- **Design leakage.** "Use a queue and a daily cron" in the spec. That's the how — it belongs in
  `design`, where it can be reviewed as an approach.
- **Unfalsifiable success.** "Make it better/faster/cleaner" with no number or condition. `verify`
  has nothing to check.
- **Silent gap-filling.** Guessing the who/why/success instead of running `interview`.
- **Padding.** Filling every section because it's there. Sections are optional.
