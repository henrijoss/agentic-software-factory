# Interview — Technique (depth)

Loaded on demand by the `interview` skill. The SKILL.md core stays lean; rationale, the worked
example, and the rationalizations table live here.

## Why one question at a time, not a batch

- The user can't react to your hypothesis if it's buried in a list of five.
- Batches invite skim-reading and surface answers.
- The third question usually depends on the answer to the first; asking all at once locks in the
  wrong framing before the first answer can correct it.
- The user's energy for careful thinking is finite — spend it one question at a time.

## Why attach a guess to every question

- Reacting to a wrong guess is faster than generating an answer from scratch.
- It commits you to a hypothesis you can be visibly wrong about, which keeps you honest.
- It surfaces *your* assumptions — exactly what the interview exists to expose.

The risk is a polite user agreeing to be agreeable. Mitigate by being visibly willing to be wrong,
and occasionally guess in a direction you expect pushback on. Leading is fine here; sycophancy is
the failure mode, not leading.

## Want vs. should-want — what to listen for

| Signal | Example | Move |
|---|---|---|
| Best-practice talk | "I want it scalable / clean architecture" | "Scalable to what? What breaks today?" |
| Deference to convention | "the way most apps do it" | "What does *your* case need that the default might miss?" |
| Self-justification | "I should probably…", "I'm supposed to…" | the no-justification probe (below) |
| Buzzword as goal | "modern", "robust" stands in for the outcome | "What specific outcome does that get you?" |

The universal probe: *"If you didn't have to justify this to anyone, what would you actually want?"*

## The 95% stop, expanded

The test — *can I predict the user's reaction to the next three questions?* — is checkable, not a
vibe. Two ways to be done, only one good:

- **Converged:** you can predict → produce the restate.
- **Floored:** several rounds in, still can't predict → stop and surface it. Continuing to grind
  past the floor wastes the user's finite attention and signals you're asking the wrong questions.
  Reframe or step back rather than asking a seventh variant of the same question.

## Worked example

**Without `interview`:**

```
User:  build me a dashboard for our metrics
Agent: <starts proposing chart libraries and layouts>
```

The agent silently assumed who it's for, what "metrics" means, and what success is. Every
assumption is a place the user can later say "that's not what I meant."

**With `interview`:**

```
User: build me a dashboard for our metrics

Agent:
HYPOTHESIS: You want to answer "how are we doing?" in standup; "dashboard" came to mind as the conventional answer.
CONFIDENCE: ~30% — missing: who it's for, what "metrics" are, what success looks like.

Q:     Who's asking "how are we doing?" — you alone, the team in standup, or up the chain (manager, exec)?
GUESS: the team in standup; "we" usually scopes that way. For execs the framing changes a lot.

User: It's actually for me. I keep losing track of which experiments are running and their early signal.

Agent:
Updated read: not a team dashboard — a personal experiment tracker. Confidence: ~60% — still missing what "early signal" means and what done looks like.

Q:     Is the gap that you don't know which experiments exist, or that you can't see their results in one place?
GUESS: the second — results live in five tools and reconciling them by hand is what you're tired of.

User: First, actually. I literally don't have a list — they're spread across docs.

Agent: <continues>
```

Two questions in, the real ask isn't "a dashboard." It's "a list." Different artifact, different
scope. The dashboard would have been wrong.

## Common rationalizations

| Rationalization | Reality |
|---|---|
| "The ask is clear enough" | If you can't write the desired outcome in one sentence now, it isn't. Run Step 1 first. |
| "Questions waste their time" | 4–6 targeted questions cost minutes; building the wrong thing costs days, and the user bears it. |
| "I'll figure it out as I build" | Switching costs after code exists are ~10× now. Discovery during implementation is rework. |
| "They said 'whatever you think'" | Delegation, not decision. Re-ask with two concrete options as a choice. |
| "I'll give them options to pick" | Options work when the user knows what they want. They don't yet — options widen the search; questions narrow it. |
| "Attaching my guess leads them" | Leading is the point; reacting beats generating. The risk is sycophancy — mitigate by being willing to be wrong. |
| "We've talked enough, I get it" | Test it: can you predict the next three reactions? If not, you don't get it yet. |
| "They said yes, we're done" | A yes after a vague restate is hollow. Restate concretely and re-confirm. |

## Relationship to other skills

- **`specify` / `clarify`:** the primary callers. `interview` is their elicitation engine; they
  persist the confirmed intent into the Specification / Requirement.
- **`constitution`:** calls `interview` to draw out missing standing principles.
- **`doubt`:** the opposite end of the timeline — `interview` is pre-decision intent extraction;
  `doubt` is post-decision adversarial review of an existing artifact. Both catch divergence, at
  different moments.
