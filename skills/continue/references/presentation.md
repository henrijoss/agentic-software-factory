# Continue — Presentation Contract (depth)

Loaded on demand by the `continue` base skill. How the **driver** frames its **interactive**
conversational output so that, at each step, the operator sees what was just produced, what is worth
discussing next, and the choice they own. This is a **light, conversational** contract — there is no
phase banner, no `N/11` position, and no vertical phase map: the system navigates by **intent +
advisory suggestion** (`continue` Step 4), not a fixed sequence, so a "you are at node 5 of 11" map
would misrepresent how it actually moves.

## Scope (read first)

- **The driver owns this framing.** Only `continue` emits it — it is the only actor that knows what was
  ingested and the resolved next-step suggestion. **Phase/transition skills never emit it** — they are
  pure transforms that return a result the driver frames.
- **The `auto` switch decides the hand-off.** Under `auto: false` (default) a step presents the
  end-of-step hand-off below; under `auto: true` it **skips** the hand-off, ends on the saved
  confirmation, and the next fresh session auto-takes the suggested next step (see `fresh-context.md`).
  The `── step N ──` light rule printed between steps is emitted by `loop.sh` itself, not the driver.

## 1. Saved confirmation — "the tree is persisted" (light rule `─`)

Emitted on **every successful ingest** — after the driver has written the artifact(s) to the tree,
updated `index.md`, and **gate-validation has passed**. It signals the phase finished *and* the file
tree is on disk, so the conversation is disposable: the operator can `/clear` or close without losing
context. **Only assert this once ingest + gate-validation succeed** — on failure, surface that failure
instead (the tree is not safe to leave).

Full form (when the step **stops** — manual `continue`, or a pause):
```
─── design saved ──────────────────────────────────
✓ REQ-02.DESIGN  → requirements/REQ-02/design.md   (updated in place)
✓ index.md       → registry + status updated

Safe to clear or close — index.md holds the state; resume with /continue.
```

- One `✓` line per artifact written: `<stable ID> → <path>` with `(updated in place)` or `(created)`.
  A `to-*` fan-out lists each new ID or summarizes (`✓ REQ-01…REQ-04 → requirements/  (4 created)`).
- The `✓ index.md → registry + status updated` line **always** appears — every ingest touches it.
- The closing **safe-to-clear** line states the session is now disposable in the system's own terms
  (`index.md` + the tree are the only memory carried forward). **No git mention** — ingest writes files;
  committing is a separate step.

Compact form (when the operator runs `continue` again **in the same interactive session**):
```
✓ saved · REQ-02.DESIGN, index.md
```

## 2. End-of-step hand-off (`auto: false`) — the conversational contract

This replaces the old heavy gate block. After the saved confirmation, the driver hands the conversation
to the operator in **three parts, in order**:

1. **Critical open topics first.** Surface any open topics/questions that still genuinely need
   discussion before this artifact is sound — the things that would bite if left unresolved. When there
   are critical ones, lead with them: they are the reason to keep talking before progressing.
2. **If none are critical, offer related topics + concrete examples.** When nothing is critical, suggest
   1–3 related angles worth exploring, **each with a concrete example** so the operator reacts to
   something specific rather than an abstract prompt. This is how `clarify`/`design` keep deepening a
   living spec instead of rushing forward.
3. **Present the choice** the operator owns:
   - **Progress to next phase** — take the suggested next step (`continue` Step 4 names it concretely).
   - **Continue with a topic** — re-run this phase **in place** on a chosen topic (no fork).
   - **Stop here** — pause the loop; `index.md` holds the state.

**Prefer an interactive picker** (in Claude Code, `AskUserQuestion`) over a typed prompt — a pick reads
as "your turn" far more clearly than a paragraph the operator must answer by typing. When no picker is
available, fall back to a light `── next ──` text footer with the same three options, each with a short
consequence clause. The hand-off is **always the last thing in the message**; nothing follows it.

Picker form: the **question** is "Where next on REQ-02?" (or the phase's specific decision); the
**options** are the three above, with the *Continue with a topic* path carrying a **free-text note** so
the operator names which topic. A one-line recap of the critical/related topics sits **above** the picker.

Footer fallback:
```
─── next ──────────────────────────────────────────
→ Progress to next phase — <suggested step, e.g. to-tasks on REQ-02>
→ Continue with a topic  — tell me which; I re-run design in place
→ Stop here              — pause; index.md holds the state
```

**Loop-by-default (clarify/design).** `clarify` and `design` **loop by default**: every iteration
**writes the artifact in place before this hand-off**, so *Continue with a topic* always re-enters an
already-saved artifact (never a fork). Choosing a topic re-runs the phase, writes again, and returns here.

## 3. Other steps (transition fan-outs, opt-in steps)

Transition fan-outs (`to-requirements`, `to-tasks`) and **opt-in** steps (`verify`/`test`, `deploy`) owe
the same lightweight hand-off, but their options are the step's specific decision rather than the
topic-exploration triad:

- **`to-requirements` / `to-tasks`** — **Approve** (accept the set; start the proposed slice) ·
  **Re-slice** / **Edit set** (re-runs the transition) — other feedback via the note.
- **`verify`/`test`** (opt-in, only when observable behavior exists) — **test** (TDD) · **verify**
  (run-and-observe) · **both** · **Skip** (proceeds without verifying; slice recorded **unverified**).
- **`deploy`** (opt-in, outward and irreversible, only when a deploy actually exists) — restate target,
  version, ship command, and rollback **above** the picker; **Authorize ship** · **Hold**. The
  affirmative is explicit, never inferred from a prior review approval.

A finished `implement` task with **more tasks remaining** owes **no** decision — emit the saved
confirmation and a plain `next: [REQ-n.TASK-m]` pointer (no picker); the only thing to do is run it.

## 4. `auto: true`

No hand-off at all: the saved confirmation is the final block and the next fresh session auto-takes the
suggested next step. A **correctness check** (failed gate-validation, unresolved sync drift, a major
version mismatch) always stops for the human regardless of `auto`.

## Cadence (the anti-noise rule)

- **Saved confirmation:** once per **successful ingest** — full form when the session ends here, compact
  one-line form when the operator runs `continue` again in the same session. Emitted only after
  gate-validation **passes**; on failure surface the validation error, not a "saved" claim.
- **End-of-step hand-off:** once, under `auto: false`, as the message's **final block**. None under
  `auto: true`, and none for a non-final `implement` task (just the next-task pointer).
- **Mid-phase work** (tool calls, reasoning) carries **no** furniture — the hand-off is a phase-boundary
  element only.

## Line-wrapping & graceful degradation

**No element's correctness depends on the terminal width.** Rules are a **fixed short run** (~50 chars)
that looks intentional — never a full-width fill the agent expects the terminal to wrap. Long prose is
pre-wrapped by hand; break long lines onto a **2-space-indented** continued line rather than relying on
the terminal. The hand-off (picker, or the `── next ──` footer when no picker is available) is **always**
kept — it is the load-bearing element.

## Marker vocabulary

All glyphs are already in use in this repo — keep them consistent.

| Glyph | Meaning | Where it already appears |
|---|---|---|
| `─` | saved / next / closing block & footer; also the `── step N ──` banner `loop.sh` prints between steps | `fresh-context.md` step banner |
| `✓` | done / passed / **saved (artifact written)** | `deploy-guide.md` pre-ship checklist |
| `▶` | active artifact | README loop diagram |
| `·` | separator | repo-wide separator |
| `→` | an action / option | README, `specify` ASSUMPTIONS |
