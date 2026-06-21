# Clarify — Deep-Dive Guide (depth)

Loaded on demand by the `clarify` skill. What "ready" means, the relationship to `interview` and
`specify`, sharpening acceptance, and a worked example.

## What "ready" means — the readiness bar

A requirement is **ready** when both hold:

1. **`design` can proceed without guessing** — the *what* is pinned tightly enough that choosing an
   approach is about how, never about what the user meant.
2. **`verify`/`test` can check acceptance objectively** — each criterion is a condition someone could
   confirm true/false without re-asking the user.

If either fails, keep clarifying. If clarifying keeps surfacing *new scope* (not just detail), the
problem is upstream — kick back to `to-requirements`/`specify`. Clarify deepens; it doesn't expand.

## Relationship to `interview` and `specify`

- **`interview` is the engine.** Clarify is "run `interview`, scoped to one requirement, then write
  the result in place and gate." All the one-question-at-a-time, guess-attached, want-vs-should-want,
  95%-stop discipline lives in `interview` — don't restate it here.
- **`specify` is the sibling caller.** Same engine, different altitude: `specify` interviews to pin
  the whole Spec's objective/scope/success; `clarify` interviews to pin one Requirement's acceptance.
  Keeping both thin (delegating to `interview`) is what avoids three copies of the same technique.

## Sharpening acceptance (Step 3)

Draft acceptance from `to-requirements` is a *signal*; ready acceptance is a *test*. Convert:

```
draft:  "user can see running experiments at a glance"
ready:
- [ ] the status view lists every experiment with state in {planned, running, done, abandoned}
- [ ] an experiment with no recorded state shows as "planned", not blank
- [ ] the view loads the current user's experiments only
out of scope: filtering, sorting, other users' experiments
```

Techniques:
- Replace adjectives with conditions ("fast" → a latency number; "clear" → what's shown).
- Name the **negative/edge cases** the use-case implies (empty, error, the thing that must *not*
  happen) — these are where `verify` earns its keep.
- Add the **out-of-scope** line explicitly; silent non-goals are half of misalignment.

## Handling open questions (Step 4)

Each draft open question exits in one of two states — never a third:

- **Answered** — fold the answer into the use-case/acceptance.
- **Deferred** — record *why*, and whether it blocks design. A question deferred without a reason is
  a dangling assumption that `design` will resolve by guessing.

## Worked example — REQ-02 from the experiment tracker

```markdown
# REQ-02 — See running experiments at a glance   (ready)

**As a** STK-1 (researcher) **I want** a status view **so that** I know what's live without hunting.

**Acceptance:**
- [ ] view lists each experiment with state in {planned, running, done, abandoned}
- [ ] missing state renders as "planned"
- [ ] shows only the current user's experiments
- [ ] empty state ("no experiments yet") is handled

**Out of scope:** filtering/sorting; teammate (STK-2) shared view — deferred to a later slice.

**Resolved / deferred:**
- "what statuses exist?" → resolved: the four above (interview).
- "teammate visibility?" → deferred: STK-2 view is a separate requirement; does not block design.

**Stakeholders:** STK-1 (STK-2 deferred)
```

Note: still no UI/tech choice (that's `design`) — clarify only made the *what* unambiguous and
testable.

## Anti-patterns

- **Interview duplication.** Re-explaining one-question-at-a-time here instead of invoking the posture.
- **Scope creep dressed as clarification.** Adding new capability/requirements — that's
  `to-requirements`; clarify deepens a single use-case.
- **Design leakage.** Deciding the approach ("use a websocket") while clarifying the *what*.
- **Soft acceptance.** Leaving "should be intuitive / fast / robust" as criteria — untestable, so
  not ready.
- **Dangling questions.** Marking a requirement ready with unresolved, unreasoned open questions.
