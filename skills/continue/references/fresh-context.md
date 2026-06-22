# Continue — Fresh-Context Step Loop (depth)

Loaded on demand by the `continue` base skill. The SKILL.md core states how `gatePolicy` resolves each
gate in-session; the rationale, the reset options, and `loop.sh` usage live here.

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
permissions, the gate picker all work exactly as in a hand-run `continue`.

## How `gatePolicy` resolves each gate (in-session)

Every step runs interactively, so `gatePolicy` decides only whether a gate **presents its decision
picker** before the step ends — it never writes a control file. After ingest + gate-validation, the
driver resolves the gate by the base skill's gate-autonomy precedence (safety floor →
`gateOverrides[<phase>]` → `gatePolicy`):

| Resolved decision | What the step does |
|---|---|
| Safety floor (always) | Present the decision — the operator must answer (picker / `── NEXT ──` footer). |
| `pause` — `manual`, a milestone gate under `milestones`, or a `pause` override | Present the decision. |
| `advance` — `auto`, a non-milestone gate under `milestones`, or an `auto` override | Skip the picker; end on the saved confirmation. |

**The safety floor always pauses, whatever the policy:** an ambiguous gate where the next phase isn't
unambiguous; a **sync gate** holding external drift (`HEAD` != `Last synced commit`); `deploy` or any
outward/irreversible action needing its own authorization; failed gate-validation
(dangling/duplicate/orphan/unreachable); a major version mismatch; a rejected/uncertain decision a phase
would otherwise guess.

So `gatePolicy: manual` presents a picker at every gate (the operator decides each one), `auto` skips
every routine picker (only the safety floor pauses), and `milestones` presents only at the milestone
gates (`constitution`/`specify`/`design`/`review`) plus the floor. This preserves "a human gate on every
transition" — the gate and its validation still run each step; `gatePolicy` only tunes which routine
gates pause for the picker. Either way the step ends after one phase; `loop.sh` is what relaunches the
next one and asks the operator whether to go on.

## Running the loop

```bash
# from the project root (where docs/<root>/ lives):
skills/continue/loop.sh                  # drives /continue, up to MAX_STEPS (default 50)
skills/continue/loop.sh "/some-prompt"   # drive a different prompt/skill
MAX_STEPS=100 skills/continue/loop.sh    # go further
```

Each iteration prints a `── step N ──` banner, then launches a fresh **interactive** `claude` running
the step — full TUI, normal permissions, working gate picker. An interactive session does not auto-exit,
so you end it (Ctrl-D / `/exit` / **Stop here** at the gate) when the step is done; the loop then asks
`run the next step? [Y/n]` — Enter/`y` continues, `n`/`q` stops. **That between-step prompt is the loop's
only stop control** (there is no `.sdlc/loop-control` file). The script changes nothing about the
artifact tree itself; it only sequences cold processes.

## Headless / unattended runs (`--headless`)

```bash
skills/continue/loop.sh --headless                 # unattended; auto-exit + auto-advance per step
skills/continue/loop.sh --headless "/some-prompt"
HEADLESS=1 skills/continue/loop.sh                 # same, via env
```

The interactive mode above needs an operator to end each step (Ctrl-D) and answer the `[Y/n]` prompt, so
the run stalls at the first finished step if left alone. `--headless` removes both hands-on points: each
step runs `claude -p`, which **auto-exits** when the step is done, and the loop **auto-advances** to the
next step with no prompt — a true unattended Ralph loop. Context still zeroes per step (each `-p` run is
a fresh process); `index.md` remains the only memory carried forward.

A `-p` session has **no interactive picker** (`AskUserQuestion`), so the driver signals the loop with a
**text sentinel** on its last line — this is the source of truth for that contract:

| Last-line sentinel | Meaning | Loop does |
|---|---|---|
| `<sdlc-done>COMPLETE</sdlc-done>` | Step 4 found no next step (project complete) | print "project complete", `exit 0` |
| `<sdlc-gate>PAUSE: <reason></sdlc-gate>` | a safety-floor gate, or a gate that resolved to `pause`, needs a human | print the reason, **stop** (`exit 1`) |
| *(none)* | routine **advance** step (saved confirmation already printed) | run the next step automatically |

The loop appends a short directive to the prompt instructing the driver to follow this contract instead
of presenting a picker. Pair headless with **`gatePolicy: auto`** so only the safety floor (and any
explicit `pause` override) interrupts the run; under `manual`/`milestones` every routine gate emits the
pause sentinel and the loop keeps stopping — the script **warns** when `gatePolicy` isn't `auto`. The
`MAX_STEPS` cap still bounds the run; the completion sentinel just lets it exit early instead of running
empty steps to the cap. After a pause-for-human stop, inspect and rerun — the step resumes from
`index.md` exactly as a cold interactive step would.

## How it nests with the other loops

- **`implement`'s per-task loop is not a separate inner loop** — each task *is* a step/process here.
  Within the `implement` phase one task runs per process, so a slice's `implement` spans as many
  processes as it has tasks. The SessionSummary is the within-slice handoff
  (`skills/implement/references/session-loop.md`), exactly as `index.md` is the cross-phase handoff.
- **`doubt`** rests on the same fresh-context principle (a reviewer that hasn't seen your reasoning).
  Because each step here is a full process, `doubt` spawns its reviewer normally — no nesting limit.
- **This loop is the only driver.** There is no in-session multi-step counterpart; hand-driven
  single-step `continue` (option 2 above, the operator running `/continue` per step) is the equivalent
  without the script. Either way each step is a fresh interactive session with context zeroed.
