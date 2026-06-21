# Doubt — Reviewer Mechanics (depth)

Loaded on demand by the `doubt` skill. How to spawn the reviewer, the cross-model offer, and
external-CLI safety. The SKILL.md core stays generic; backend/tooling specifics live here.

## Spawning the fresh-context reviewer

The reviewer must start with **isolated context** — that is the whole point. Any subagent/fresh
session that hasn't seen your reasoning works. If the host (e.g. Claude Code) ships role-based
reviewer agents, they start isolated by design and are usable here; pick one matching the domain.

**The adversarial prompt takes precedence over a reviewer persona's default shape.** Personas tuned
to produce balanced verdicts (strengths + weaknesses) must be overridden — `doubt` needs issues-only
output. Paste the adversarial prompt verbatim so it overrides the default; if a persona's shape
can't be overridden cleanly, fall back to a generic subagent with the adversarial prompt.

If you are inside a context that forbids nested spawning: prefer surfacing to the user that doubt
can't run nested. The self-questioning fallback (rewrite ARTIFACT + CONTRACT as a fresh self-prompt
with a hard mental separator, then walk Steps 1–5) is **not** fresh-context review — you carry your
own context — so label the result degraded and escalate when the user is reachable.

## Cross-model escalation

A single-model reviewer shares blind spots with the original author; a colder, different-architecture
model catches them. Within `doubt`'s opt-in scope, offering cross-model is part of the value.

**Interactive sessions: always offer, never silently skip.** After the single-model review, before
RECONCILE, ask:

> *"Single-model review complete. Want a cross-model second opinion? Options: Gemini CLI, Codex CLI,
> manual external review, or skip."*

Mandatory every interactive cycle, even on low-stakes artifacts — the user decides whether the cost
is worth it; the agent only surfaces the choice.

- **User picks a CLI:** verify it (`which gemini` / `which codex`), test it works (`--version`)
  before the real prompt, confirm the exact invocation (flags, auth, env) with the user, pass
  ARTIFACT + CONTRACT + adversarial prompt **only**, then take output into RECONCILE.
- **CLI unavailable/fails:** surface it; offer manual run, a different tool, or skip. Never silently
  fall back to single-model.
- **User skips:** acknowledge in output (*"Proceeding with single-model findings only"*) and continue.

**Non-interactive contexts** (CI, `/loop`, autonomous-loop, scheduled): cross-model is skipped and
the skip is announced (*"Cross-model skipped: non-interactive context."*). **Never invoke an external
CLI without explicit user authorization** — load-bearing safety property.

## External-CLI safety (load-bearing)

**Never interpolate the artifact into a shell-quoted argument.** Code/markdown/prompts routinely
contain backticks, `$(...)`, and quotes that truncate the prompt or execute embedded shell. Write the
full prompt to a temp file and pipe via stdin.

**Run the CLI read-only / sandboxed.** A doubt artifact may itself contain instructions (intentional
or accidental prompt injection) that a CLI would otherwise execute against your workspace.

Example shapes — verify flags against your installed version, they differ across tools:

```bash
# Write adversarial prompt + ARTIFACT + CONTRACT to /tmp/doubt-prompt.md first, then:

# Codex (read-only sandbox):
codex exec --sandbox read-only -C <repo-path> - < /tmp/doubt-prompt.md

# Gemini (--approval-mode plan is read-only; -p "" reads prompt from stdin):
gemini --approval-mode plan -p "" < /tmp/doubt-prompt.md
```

Each invocation is its own authorization — the artifact, prompt, and flags change between calls, so
re-confirm the exact command with the user before every run.

## Common rationalizations

| Rationalization | Reality |
|---|---|
| "I'm confident, skip it" | Confidence correlates poorly with correctness on novel problems; certainty is where blind spots hide. |
| "Spawning a reviewer is expensive" | Debugging a wrong commit in production costs more. The check is bounded; the bug isn't. |
| "The reviewer will just nitpick" | Only if unscoped. Constrain to "issues that fail the contract." |
| "I'll doubt at the end with `review`" | `review` is a final gate; by then course-correction is expensive. Doubt catches wrong directions early. |
| "If I doubt every step I'll never ship" | Applies to non-trivial decisions only — re-read When NOT to use. |
| "Two opinions are always better" | Not when the second has less context and produces noise. Reconcile, don't defer. |
| "The reviewer disagreed, so I was wrong" | It lacks your context — disagreement is information, not verdict. Re-read, classify, decide. |
| "User said yes once, I can keep invoking the CLI" | Each call is its own authorization; re-confirm the exact command every run. |

## Relationship to other skills

- **`review`:** complementary — `review` is the post-hoc gate verdict; `doubt` is in-flight
  per-decision. Use both.
- **`interview`:** timeline counterpart — `interview` extracts intent pre-decision; `doubt`
  cross-examines the artifact post-decision. Both catch divergence, at different moments.
- **`test`/`verify`:** TDD's RED step is doubt made concrete — a failing test is a disproof attempt
  and satisfies the fresh-context review for behavioral claims.
- **`incremental`:** risk-first slicing puts the riskiest slice first — exactly where `doubt` pays off.
