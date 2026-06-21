---
name: interview
description: One-question-at-a-time intent extraction — draws out what the user actually wants instead of what they think they should ask for, until you can predict their answers. The engine behind `specify` and `clarify`, and usable from any phase. Use when an ask is underspecified ("build me X" with no who/why/success), when values are in tension and the user hasn't said which wins, when the user invokes ("interview me", "grill me", "are we sure?"), or when you catch yourself silently filling ambiguous gaps before any artifact exists.
---

# Interview

## Overview

What people ask for and what they actually want diverge. They ask for "a dashboard" because that
is what one asks for; they say "make it faster" with no number to hit. This posture closes that gap
**before** any spec, plan, or code exists — the cheapest moment, before switching costs lock the
misfit in.

`interview` is a **posture**, not a phase: it owns no artifact and has no fixed slot in the loop. It
is the elicitation engine other skills call — `specify` runs it to turn an idea into intent,
`clarify` runs it to deepen one requirement, `constitution` runs it for missing principles. The
caller persists the result; `interview` produces a **confirmed statement of intent** and hands it
back.

The method: ask one question at a time, each with your best guess attached, until you can predict
the user's answer before they give it.

## When to Use

- The ask is missing at least one of: **who** the user is, **why** now, what **success** is, what
  the binding **constraint** is.
- The request is conventional rather than specific ("build me X", "make it faster") and you cannot
  unpack the convention without guessing.
- Two reasonable values are in tension (simplicity vs. flexibility, cost vs. speed) and the user
  hasn't said which wins.
- The user invokes it: "interview me", "grill me", "are we sure?", "stress-test my thinking".
- You catch yourself about to fill an ambiguous requirement with an unstated assumption.

**When NOT to use:**

- The ask is unambiguous and self-contained (rename a variable, fix a typo).
- Pure information requests ("how does X work?") or mechanical operations.
- You already have ≥95% confidence — re-read the stop condition before assuming you don't.

## Loading constraints

Needs a live, responsive user. **Do not invoke in non-interactive contexts** (CI, scheduled runs,
`/loop`, autonomous-loop). If you're in one and the ask is underspecified, flag it as a blocker
instead of guessing.

## Inputs / Outputs (abstract)

- **Input:** an underspecified ask plus whatever context the calling phase already holds.
- **Output:** a **confirmed statement of intent** (the Step-4 restate + an explicit Step-5 yes),
  returned to the caller. `interview` writes **no artifact of its own** — the calling phase folds
  the intent into its artifact via the `continue` base skill. Persist standalone only on request
  (see Output).

## Process

### 1. Hypothesize, with a confidence number

Before asking anything, write your current best read in **one sentence** plus an honest 0–100%
confidence. Below ~70%, append on the same line what's still missing.

```
HYPOTHESIS: You want to answer "how are we doing?" in standup; "dashboard" was the convention that came to mind.
CONFIDENCE: ~30% — missing: who it's for, what "metrics" means, what success looks like.
```

The number forces honesty: if you wrote a high number but can't predict the user's reaction to the
next three questions, the number is wrong.

### 2. Ask one question at a time, each with a guess attached

```
Q:     <one focused question>
GUESS: <your hypothesis for the answer, with the reasoning that produced it>
```

Wait for the user to react before the next question. One at a time, not a batch — see
`references/technique.md` for why (the third question usually depends on the first answer; batches
get skimmed). Attaching a guess makes the user react (faster than generating) and exposes *your*
assumptions, which is the point.

### 3. Listen for "want vs. should-want"

The dangerous answers sound like a thoughtful answer rather than the truth: best-practice talk
("scalable", "clean architecture"), deference to convention ("the standard approach"), "I should
probably…". When you hear one, probe:

> *"If you didn't have to justify this to anyone, what would you actually want?"*

That single question often outworks the previous five.

### 4. Restate intent in the user's own words

When confidence is high, write back what you now think they want — tight, their language, line by
line so they can confirm or correct each:

```
- Outcome:      <one line>
- User:         <one line — who benefits>
- Why now:      <one line — what changed>
- Success:      <one line — how we know it worked>
- Constraint:   <one line — the binding limit>
- Out of scope: <one line — what we're explicitly NOT doing>
```

**Out of scope is non-negotiable** — half of misalignment is silent disagreement about non-goals.

### 5. Confirm — an explicit yes, not "whatever you think"

These are **not** a yes: "whatever you think" (delegation → re-ask with two concrete options),
"sounds good" / "sure, let's go" (ambiguous or polite exit → ask "anything you'd refine?"), silence
then "okay let's start" (gave up, didn't converge → ask what you missed). Fold in corrections,
restate, loop until explicit yes.

### The 95% stop

Stop when you can answer yes to: *Can I predict the user's reaction to the next three questions I
would ask?* If yes, produce the restate. If no, ask the next question.

This has a **floor**: if several rounds in you still can't predict, that's information about the ask,
not a reason to grind. Stop and say so: "I've asked X questions and still can't predict your
reactions — something foundational is missing. Want to step back?"

## Output & handoff

The deliverable is the confirmed intent (Step 4 + explicit yes). The calling phase consumes it:
`specify` writes it into the **Specification**, `clarify` into the **Requirement**, `constitution`
into the **Constitution** — all via artifact-io. If invoked standalone and the user wants the intent
to persist across sessions, offer to save to `docs/intent/[topic].md`; save only on confirmation
(the doc itself implies a yes the user hasn't given).

## Red Flags

- Three+ questions in one message — batching, not interviewing.
- A question with no guess attached — surveying, not committing.
- Accepting "whatever you think is best" as a terminal answer.
- Producing a spec/plan/artifact before an explicit yes on the restate.
- A sophistication-signaling answer ("scalable", "modern") accepted without the want-vs-should probe.
- Three+ rounds with confidence not visibly rising — wrong questions; reframe.
- Confidence below ~70% with no reason attached.
- Skipping the "Out of scope" line.

## Verification

- [ ] A hypothesis + confidence number was stated in the first turn (with a reason when < ~70%).
- [ ] Questions were asked one at a time, each with a guess attached.
- [ ] The "what would you actually want?" probe ran on any convention/sophistication-signaling answer.
- [ ] A concrete restate (Outcome / User / Why now / Success / Constraint / Out of scope) was written back.
- [ ] The user gave an explicit yes — not "whatever you think", not "sounds good", not silence.
- [ ] At the stop point, reactions to the next three questions were predictable.
- [ ] Intent handed to the caller (or saved to `docs/intent/` only if the user confirmed).
