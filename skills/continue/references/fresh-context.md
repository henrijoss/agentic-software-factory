# Continue — Fresh-Context Step Loop (depth)

Loaded on demand by the `continue` base skill. The SKILL.md core states the non-interactive mode and
the loop-control contract; the rationale, the reset options, and `loop.sh` usage live here.

## Why fresh context per step

A long-running driven session is the same trap the `implement` skill's per-task loop already names
(`skills/implement/references/session-loop.md`): **one ever-growing session** fills with stale detail,
hardens early assumptions into "facts", and degrades instruction-compliance as the window saturates —
this skillset's top documented failure mode. The `implement` session-loop solves it *within* a phase.
This is the same discipline lifted to the **driver/step** level: the conversation is disposable;
`index.md` + the artifact tree is the only memory carried across steps. After a step's result is
ingested, that step's working-context (file reads, tool output, reasoning) adds only drift — nothing a
fresh step needs, because `index.md` already records exactly where the project stands.

## What truly resets context (and what doesn't)

Three ways to "reset" between steps, only one of which actually zeroes the transcript:

1. **Subagent-per-step** — the driver delegates a step to a fresh subagent; only the small result
   returns. Bounds growth (the bulk dies with the subagent) but the driver's own context still grows,
   and subagents can't nest — so a phase that runs `doubt` (`design`/`implement`/`review`) can't spawn
   doubt's reviewer from inside it. Bounded, not zeroed.
2. **Operator `/clear` + `/continue`** — true reset, but a human presses the button each step. The
   agent cannot wipe its own transcript.
3. **Fresh process per step** (this loop) — each step is a brand-new `claude` process that reads
   `index.md` cold, runs one phase, and exits. **The only true zero**, and unattended. Because each
   step is a top-level process (not a subagent), `doubt` can still spawn its reviewer normally — the
   nesting problem of option 1 does not arise.

`loop.sh` implements option 3.

## The loop-control contract (non-interactive mode)

A headless `/continue` (run via `claude -p`) has no human to answer its gate. Instead, after ingest +
gate-validation, it writes **`.sdlc/loop-control`** with exactly one of:

| Value | Meaning | Loop action |
|---|---|---|
| `continue` | Routine advance; nothing needs a human. | Run the next step. |
| `halt: <reason>` | A human is required. | Stop and surface the reason. |
| `done` | The slice/loop is complete. | Stop cleanly. |

**`halt` is mandatory (never `continue`) for:** an ambiguous gate where the next phase isn't
unambiguous; a **sync gate** holding external drift (`HEAD` != `Last synced commit`); `deploy` or any
outward/irreversible action needing its own authorization; failed gate-validation
(dangling/duplicate/orphan/unreachable); a rejected/uncertain decision a phase would otherwise guess.
This preserves "a human gate on every transition" — the loop auto-advances only the gates that are
genuinely routine, and stops the moment a real decision is owed.

Interactive `/continue` is unchanged: it presents the gate to the operator and writes no control file.

## Running the loop

```bash
# from the project root (where .sdlc/ and docs/<root>/ live):
skills/orchestrator/loop.sh                  # drives /continue, up to MAX_STEPS (default 50)
skills/orchestrator/loop.sh "/orchestrator"  # drive a different prompt/skill
MAX_STEPS=100 skills/orchestrator/loop.sh    # go further
```

Each iteration prints a `── step N ──` banner, clears `.sdlc/loop-control`, runs the fresh process,
then branches on the control file. A missing control file means the step never reached its gate — the
loop stops rather than spinning. The script changes nothing about the artifact tree itself; it only
sequences cold processes.

## How it nests with the other loops

- **`implement`'s session-loop** is the *inner* fresh-context loop — fresh context per **task** within
  the `implement` phase. This step loop is the *outer* one — fresh context per **phase/step**. A single
  `implement` step may itself run several task-sessions before it writes its `loop-control`.
- **`doubt`** rests on the same fresh-context principle (a reviewer that hasn't seen your reasoning).
  Because each step here is a full process, `doubt` spawns its reviewer normally — no nesting limit.
- **`orchestrator`** is the single-session counterpart: same phase graph and gates, but auto-advancing
  *inside one session* (context grows). Use `orchestrator` for an attended run where you want the
  transcript; use `loop.sh` for a long unattended run where you want context zeroed each step.
