# Review — Authoring Guide (depth)

Loaded on demand by the `review` skill. The four passes, finding disposition, the anti-staleness
("analyze") pass, project review tooling, and a worked example.

## The four passes, and why review isn't just `doubt`

`doubt` answers *is this artifact correct against its contract?* `review` is broader — it's the
release gate, so it also asks *did we build the right thing* (vs. spec) and *to our standards* (vs.
constitution), and it disposes findings for a human decision. The split:

| Pass | Question | Mechanism |
|---|---|---|
| Correctness | Does it work and hold under scrutiny? | invoke **`doubt`** (+ `verify`/`test`) |
| Consistency | Does code still match spec/plan? Any stale artifact? | the analyze pass (below) |
| Quality | Does it meet the constitution's bars? | measure vs. the **Constitution** |
| Disposition | What happens to each finding? | fix / trade-off / noise |

Delegating correctness to `doubt` is what keeps `review` lean — it adds the consistency, quality, and
disposition layers on top, rather than re-deriving adversarial-review technique.

## The consistency / anti-staleness pass (Spec Kit's "analyze")

The field convention puts a cross-artifact consistency check ("analyze") between tasks and ship. This
skillset folds it into `review` because review is the phase that already has code + all upstream
artifacts in hand. Two distinct failure directions:

1. **Code wrong, artifact right** → a normal finding; fix the code (re-enter `implement`).
2. **Code right, artifact stale** → implementation legitimately learned something the spec/design
   didn't anticipate. The fix is a finding hinting an **artifact update** (`specify`/`design`), not
   "correcting" working code back to a wrong spec. This is the anti-staleness rule.

This is the **content-level** consistency check — does code agree with what the artifacts say. The
**structural** gate-validation over the tree (dangling / duplicate / orphan / unreachable IDs) is the
driver's job at ingest, not review's; review just reports content divergences as findings.

## Finding disposition (precedence, first match wins)

1. **Fix** — real and actionable. Re-enter `implement`; re-review after.
2. **Accept-as-trade-off** — real but the cost of fixing exceeds the benefit now. **Document it** so
   the user consciously accepts it at the gate (an undocumented known issue is a silent liability).
3. **Noise** — correct under context the review lacked. Note it and drop; ask whether the missing
   context belongs in the spec/constitution so it won't re-flag.

Separate **blockers** (gate the ship) from **improvements** (worth doing later) — the gate decision
needs to know what *must* change vs. what *could*. Don't let a pile of nits bury a real blocker.

## Severity, briefly

- **Blocker:** wrong behavior, broken contract, violated constitution boundary, security/data risk.
- **Improvement:** simplification, naming, a better-but-not-required approach, follow-up test.

When in doubt about blocker vs. improvement, the constitution's bars decide; if the constitution is
silent, surface it to the user rather than guessing.

## Project review tooling (stay tool-agnostic)

`review` describes *what* to check, not *which tool*. A project may already have review tooling
(linters, CI, a `/code-review` or `/security-review` command, role-based reviewer agents). Bind to
those through the **Constitution**'s references, the same way commands resolve — don't hardcode a
specific tool in this skill. For security-sensitive slices, a dedicated security pass (e.g. the repo's
`/security-review`) is a reasonable thing for the **Constitution** to mandate; `review` invokes what
the project declares.

## Worked example — saved-search alerts

```
Against: spec (daily digest, dedupe), plan (idempotent job), Constitution (simplicity, run-tests-before-commit).

Correctness (doubt):
- BLOCKER  Job isn't idempotent under retry — dedupe set built per-run, not persisted. → fix (re-implement)
- noise    "No backpressure on email send" — out of scope per spec; note in Open.

Consistency (content-level):
- STALE ARTIFACT  Implementation added per-search mute; spec doesn't mention it. Code is the right
  behavior → finding hinting a spec update (specify), don't strip the feature.

Quality (vs the Constitution):
- improvement  Digest builder duplicates the search query builder — extract shared fn (not gating).

Disposition: 1 blocker → implement; 1 spec update → specify; 1 improvement → backlog; trade-offs: none.
Gate: not ready — resolve the idempotency blocker and the spec update, then re-review.
```

Note: the stale-artifact finding flows *upstream* (to `specify`), not into a code change — that's the
anti-staleness pass doing its job.
