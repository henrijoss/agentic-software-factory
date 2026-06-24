# Continue — Fresh-Context Step Loop (depth)

Loaded on demand by the `continue` base skill. The SKILL.md core states how the `auto` switch resolves
each step's end-of-step hand-off; the rationale, the reset options, and `loop.sh` usage live here.

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
3. **Fresh process per step** (this loop) — each step is a brand-new interactive `claude` process that
   reads `index.md` cold, runs one step (one phase, or one `implement` task), and exits. **The only true
   zero.** Because each step is a top-level process (not a subagent), `doubt` can still spawn its
   reviewer normally — the nesting problem of option 1 does not arise.

`skills/continue/loop.sh` implements option 3 — the standard way to walk the whole loop (option 2 is the
hand-driven single-step equivalent; the agent cannot relaunch itself, so the loop lives in the script,
launched once from a terminal). It runs each step as a normal interactive session — full TUI, normal
permissions, the interactive end-of-step hand-off all work exactly as in a hand-run `continue`.

## How `auto` resolves each step's hand-off (in-session)

Every step runs interactively, so `auto` decides only whether the step **presents its end-of-step
hand-off** before ending — it never writes a control file. After ingest + gate-validation:

| `auto` | What the step does |
|---|---|
| `false` (default) | Present the interactive end-of-step hand-off (`references/presentation.md`); the operator picks the next move. |
| `true` | Skip the questions; end on the saved confirmation and let the next fresh session auto-take the suggested next step. |

`auto` removes **only the human prompt** — never a correctness check. These always run and always
halt/surface, whatever `auto` is: failed gate-validation (dangling/duplicate/orphan/unreachable), a held
**sync gate** holding external drift (`HEAD` != `Last synced commit`), and a major version mismatch.
`auto: true` is for unattended runs; `auto: false` keeps the operator in the loop step by step. Either
way the step ends after one phase; `loop.sh` relaunches the next one (and, under `auto: false`, asks the
operator whether to go on).

## Running the loop

```bash
# from the project root (where docs/<root>/ lives):
skills/continue/loop.sh                  # drives /continue, up to MAX_STEPS (default 50)
skills/continue/loop.sh "/some-prompt"   # drive a different prompt/skill
skills/continue/loop.sh --auto           # unattended: auto-advance every step
MAX_STEPS=100 skills/continue/loop.sh    # go further
```

Each iteration prints a `── step N ──` banner, then **assembles the fresh step's context** and launches
a cold `claude` running it. The loop seeds exactly three things into every step, so the session
understands what just happened and what to do without re-reading the whole tree:

- the **last 5 commits** (`git log -5`) — recent code history;
- the **next task** — `index.md`'s *Suggested next*;
- a short **bigger-picture note** from `index.md` — the intent that shapes how the code is structured.

The step implements that task and ends with **one semantic commit** (the `commit` skill behavior), so
the loop is **commit-driven**: clean, granular history, one commit per task. Because each step is a fresh
process, context never grows across steps; `index.md` + git history are the only memory carried forward.
The script changes nothing about the artifact tree itself; it only sequences cold processes.

## Interactive vs. unattended (`auto`)

`auto` — the `--auto` flag, `AUTO=1`, or `settings.execution.auto` — decides whether a human stays in the
loop between steps. There is no separate headless mode and no text-sentinel contract:

| `auto` | Per step | Between steps |
|---|---|---|
| `false` (default) | interactive `claude` (full TUI, normal permissions); you end the step (Ctrl-D / `/exit` / **Stop here**) | the loop asks `run the next step? [Y/n]` — Enter/`y` continues, `n`/`q` stops |
| `true` | `claude -p` runs the step and **auto-exits**; `--auto` is passed so it skips its end-of-step questions | the loop **auto-advances** with no prompt |

The `[Y/n]` is the loop's only stop control under `auto:false` (there is no `.sdlc/loop-control` file).
Under `auto:true` the loop runs to `MAX_STEPS` with no sentinels to parse — a step that hits a
correctness check (failed gate-validation, unresolved sync drift, a major version mismatch) halts inside
the step itself. After any stop, inspect and rerun — the step resumes from `index.md` exactly as a cold
step would.

## How it nests with the other loops

- **`implement`'s per-task loop is not a separate inner loop** — each task *is* a step/process here.
  Within the `implement` phase one task runs per process, so a slice's `implement` spans as many
  processes as it has tasks. The within-slice handoff is the **commit history + `index.md`**
  (`skills/implement/references/session-loop.md`) — there is no separate handoff file — exactly as
  `index.md` is the cross-phase handoff.
- **`doubt`** rests on the same fresh-context principle (a reviewer that hasn't seen your reasoning).
  Because each step here is a full process, `doubt` spawns its reviewer normally — no nesting limit.
- **This loop is the only driver.** There is no in-session multi-step counterpart; hand-driven
  single-step `continue` (option 2 above, the operator running `/continue` per step) is the equivalent
  without the script. Either way each step is a fresh interactive session with context zeroed.
