# Continue — Presentation Contract (depth)

Loaded on demand by the `continue` base skill (and referenced by `orchestrator`). How the **drivers**
frame their **interactive** conversational output so that, at every step, the operator can see which
phase we're in, what it operates on, where it sits in the loop, and exactly what they must do next.

## Scope (read first)

- **Drivers own this framing.** Only `continue` and `orchestrator` emit it — they are the only actors
  that know loop position, the artifact identity (which `[REQ-n]`/`[TASK-m]`), the resolved gate
  decision, and whether the session is interactive. **Phase/transition skills never emit it** — they
  are pure transforms that return a result the driver frames.
- **Interactive mode only.** In **non-interactive / headless mode** (`claude -p`, `skills/orchestrator/loop.sh`)
  there is no human to read a banner or act on a call-to-action: the driver writes `.sdlc/loop-control`
  (`continue` / `halt: <reason>` / `done`) as defined in `fresh-context.md` and emits **none** of the
  banners, maps, saved confirmations, gate blocks, pickers, or footers below — and never invokes an
  interactive picker. The headless `── step N ──` banner that `loop.sh`
  prints is the headless framing and is deliberately a **light** rule so it never collides with the
  interactive **heavy** phase-start banner.

## The four elements

Running example throughout: the **design** phase (node 5 of 11) operating on **REQ-02 "saved-search
alerts"**, under the default `gatePolicy: manual`.

### 1. Phase-start banner — "a phase begins" (heavy rule `━`)

Emitted **once**, at the top of the message in which a phase begins.

```
━━━ PHASE 5/11 · design ━━━━━━━━━━━━━━━━━━━━━━━━━━━
▶ REQ-02 · saved-search alerts
  Producing: the design Plan (approach, architecture, risks).
```

- `N/11` is the position in the canonical phase graph (`constitution` = 1 … `maintain` = 11; the
  `verify`/`test` node counts as one).
- The second line names the artifact the phase operates on:
  - a whole Requirement → `▶ REQ-02 · saved-search alerts`
  - a Task slice → `▶ REQ-02 · TASK-03 · debounce alert fan-out`
  - a phase with no single artifact (`constitution`, `specify` on a fresh project) → `▶ project · <slice name>`
- The third line states what the phase produces, in one clause.
- The **heavy** `━` rule is what distinguishes phase-start from the gate block (light `─`, below) and
  the headless `── step N ──` banner — the weight contrast signals open-vs-close without relying on color.

### 2. Phase map — vertical checklist (heavy rule's companion)

Emitted **once**, directly under the start banner. Self-labeling and wrap-proof — each phase is its own
short line, so terminal width never breaks it.

```
Phases:
  ✓ constitution
  ✓ specify
  ✓ to-requirements
  ✓ clarify
  ▶ design            ← you are here
    to-tasks
    implement
    verify/test
    review
    deploy   ⚠
    maintain
```

- `✓` done · `▶` current · (leading blank) pending.
- `⚠` marks the **safety-floor** gate (`deploy`) straight from the gate-decision table — the operator
  sees the always-pause gate ahead.
- **Under `gatePolicy: milestones` only,** append `★` to the milestone phases
  (`constitution`/`specify`/`design`/`review`) so the operator sees which gates will pause:
  `▶ design   ★`. Omit `★` under `manual`/`auto` — it would be noise.
- The longest content line (`to-requirements`, plus the `← you are here` tag on the current line) is
  ~35 cols — **never wraps at 80 and survives to ~40 cols**.

### 3. Phase complete & saved — "the tree is persisted" (light rule `─`)

Emitted on **every successful ingest** — after the driver has written the artifact(s) to the tree,
updated `index.md`, and **gate-validation has passed**. This is the signal that the phase finished *and*
the file tree is now on disk, so the conversation is disposable: the operator can `/clear` or close the
session without losing context. **Only assert this once ingest + gate-validation succeed** — if
validation fails, surface that failure instead (the tree is not safe to leave).

Full form (when the step **stops** — manual `continue`, or a pause gate):
```
─── design complete · saved ──────────────────────
✓ REQ-02.DESIGN  → requirements/REQ-02/design.md   (updated in place)
✓ index.md       → registry + status updated

Safe to clear or close — index.md holds the state; resume with /continue.
```

- One `✓` line per artifact written: `<stable ID> → <path>` with `(updated in place)` or `(created)`.
  A `to-*` fan-out lists each new ID or summarizes (`✓ REQ-01…REQ-04 → requirements/  (4 created)`).
- The `✓ index.md → registry + status updated` line **always** appears — every ingest touches it.
- The closing **safe-to-clear** line states the session is now disposable, in the system's own
  disposability terms (`index.md` + the tree are the only memory carried forward). **No git mention** —
  ingest writes files to disk; committing is the operator's separate step.

Compact form (when the orchestrator **auto-advances** — avoids restacking the full block each phase):
```
✓ saved · REQ-02.DESIGN, index.md
```

### 4. The gate hand-off — make it unmistakably the operator's turn

At a resolved-**pause** gate (see Cadence), after the saved confirmation, hand the **decision** to the
operator. The decision is the gate's **specific** question, sourced from the gate-decision table in
`phase-graph.md` (e.g. `Is the approach/architecture sound and the risks acceptable?`) — never a generic
"looks good?". **The primary mechanism is an interactive selection picker**, not prose: present that
question as a multiple-choice question the operator clicks (the harness's question/selection tool — in
Claude Code, `AskUserQuestion`). A picker reads as "your turn, pick one" far more clearly than a
paragraph the operator must read and answer by typing — which was the whole point of this element.

**Capability ladder (one of three, in order):**

1. **Interactive picker available** → present the decision as a picker. Its **question** is the gate's
   specific decision (from the gate table in `phase-graph.md`); its **options** are
   the gate-specific set below. The "request changes / not ready / hold" path always carries a
   **free-text note** (the picker's note / "Other" free-text) so the operator says *what* to change
   inline. A one-line decision recap is emitted **above** the picker as the detail the short
   option labels can't carry — prefix it with `★` at milestone gates
   (`constitution`/`specify`/`design`/`review`), omit it otherwise.
2. **No picker in the harness** → fall back to the **`── NEXT ──` text footer** (templates below): a final
   light-rule block, `→`-prefixed options, each with an `— …` consequence clause. The operator types
   their choice. Behavior is otherwise identical.
3. **Headless / non-interactive** → no picker, no footer; write `.sdlc/loop-control` (`continue` /
   `halt: <reason>` / `done`) per `fresh-context.md`.

**Picker option sets (gate-specific).** A picker holds ~4 explicit options plus an always-available
free-text "Other"; where space is tight the feedback/changes path rides the note/"Other" rather than
taking an option slot.

| Gate | Question | Options (first = affirmative/continue) |
|---|---|---|
| Routine pause gate | the phase's specific decision | **Approve** (continue to the next phase) · **Request changes** (note what to change; re-runs the phase in place) · **Stop here** (pause the loop) |
| verify/test (`verifyMode: ask`) | "Which verification level?" | **test** (TDD) · **verify** (run-and-observe) · **both** · **Skip** (proceed without verifying — slice recorded **unverified**) — *not-ready feedback via the note* |
| deploy ship authorization (⚠ safety floor) | the ship go/no-go | **Authorize ship** (perform the deploy now — irreversible) · **Hold** (do not ship; back to review / feedback) |
| to-requirements / to-tasks fan-out | "Right set? Which slice first?" | **Approve** (accept the set; start with the proposed slice) · **Re-slice** (different first slice / priority) · **Edit set** (add/drop/merge; re-runs the transition) — *other feedback via the note* |

- **verify/test `Skip`** advances `implement → review` **without** verification; the driver records the
  slice as **unverified** in the status dashboard / session summary — a deliberate, logged choice, never
  silent. (`verifyMode`'s settings enum is unchanged; `Skip` is a runtime picker choice only.)
- **deploy** restates target, version, ship command, and rollback in the element-3 block above the picker
  (matching the "Authorization gate" wording in `skills/deploy/references/deploy-guide.md`); `Authorize
  ship` is the distinct affirmative, never inferred from a prior review approval.

**`── NEXT ──` text footer (fallback form).** Same options as the picker, as a final block; nothing
follows it.

Routine pause gate (e.g. `design → to-tasks`):
```
─── NEXT ──────────────────────────────────────────
→ Approve         — continue to to-tasks (phase 6/11)
→ Request changes — tell me what to change; I re-run design in place
→ Stop here       — pause the loop
```

verify/test (`verifyMode: ask`):
```
─── NEXT · pick verification ──────────────────────
→ test   — TDD, write failing tests first (RED → GREEN → REFACTOR)
→ verify — run-and-observe the behavior
→ both   — tests now, then observe
→ Skip   — proceed to review without verifying (recorded unverified)
```

deploy ship authorization (safety floor):
```
─── NEXT · SHIP AUTHORIZATION ⚠ ───────────────────
About to ship saved-search alerts to PROD as v1.4.0
  via `npm run build && npm run deploy:prod`.
  Rollback: `npm run deploy:rollback v1.3.4` / revert abc123.

→ Authorize ship — perform the deploy now (irreversible)
→ Hold           — do not ship; back to review / feedback
```

to-requirements / to-tasks fan-out:
```
─── NEXT · review the fan-out ─────────────────────
Fanned out: 4 requirements (REQ-01…REQ-04), 3 stakeholders.
First slice proposed: REQ-02 · saved-search alerts.

→ Approve   — accept the set; start with REQ-02 → clarify
→ Re-slice  — different first slice / different priority
→ Edit set  — add / drop / merge requirements; I re-run to-requirements
```

**Hand-off invariants (picker and footer alike):**
- The hand-off is the **last** thing in the message; nothing follows it.
- The first option is the affirmative/continue path, and its consequence is concrete (which phase, which
  artifact) so "Approve" is never blind.
- A changes/feedback path is always present and always carries a **note** stating what to change; acting
  on it re-enters the phase **in place** (no parallel fork).

## Cadence (the anti-noise rule)

- **Phase-start banner + vertical map:** once per phase, at its start. **Not** mid-phase, **not** per
  tool call. This is the single most important rule for keeping the display from becoming wallpaper.
- **Saved confirmation:** once per **successful ingest** (the "phase finished + tree saved" marker) —
  full form when the step stops (manual `continue` / a pause gate), compact one-line form when the
  orchestrator auto-advances. Emitted only after gate-validation **passes**; on failure surface the
  validation error, not a "saved" claim.
- **Gate decision + hand-off (picker or footer):** once per resolved-**pause** gate (end of phase).
  Under `auto` / `milestones`, a gate that **auto-advances** emits **neither** — only the saved
  confirmation and the next phase's start banner. So the hand-off appears **only where the operator
  actually owes a decision**.
- **Mid-phase work** (the phase doing its work, tool calls, reasoning) carries **no** banners, maps, or
  hand-offs — they are phase-boundary furniture only.

## Line-wrapping & graceful degradation (the width ladder)

**No element's correctness depends on the terminal width.** Concretely:

1. **Normal (≥ ~60 cols):** the forms above. Rules are a **fixed short run** (~50 chars) that looks
   intentional — never a full-width fill the agent expects the terminal to wrap.
2. **Narrow (~40–60 cols):** shorten the rule runs; keep the vertical map (already wrap-safe); break
   long decision questions / ship details onto a continued line with a **2-space indent** (as shown)
   rather than letting the terminal hard-wrap mid-word.
3. **Very narrow (< ~40 cols) or glyphs unsafe:** replace the vertical map with the **compact bar** —
   `[✓✓✓✓▶······]  5/11 · design` (11 glyphs, one per phase, fixed order; ~24 cols, never wraps) — and
   if even that is doubtful, a plain `Phase 5/11 · design` indicator. The gate hand-off (picker, or the
   `── NEXT ──` footer when no picker is available) is **always** kept — it is the load-bearing element;
   in the footer fallback, allow its `— …` clauses to drop to a second indented line.

**Universal rule:** never emit a box-drawing rule whose appearance depends on the terminal wrapping it;
rules are fixed-short, the map is atomic-short per line, and long prose is pre-wrapped by hand.

## Marker vocabulary

All glyphs are already in use in this repo — keep them consistent.

| Glyph | Meaning | Where it already appears |
|---|---|---|
| `━` | interactive **phase-start** banner (heavy rule) | new here (heavy weight reserved for phase-start) |
| `─` | saved / gate / closing block & `NEXT` footer; also the headless `── step N ──` step banner | `fresh-context.md` step banner |
| `✓` | done / passed / **saved (artifact written)** | `deploy-guide.md` pre-ship checklist |
| `▶` | current phase / active artifact | README loop diagram |
| `·` | pending phase (in the compact bar) / separator | repo-wide separator |
| `★` | milestone gate | `phase-graph.md` gate-decision table |
| `⚠` | safety-floor gate (always pauses) | `phase-graph.md` gate-decision table |
| `→` | an action / option (and graph flow) | `phase-graph.md`, README, `specify` ASSUMPTIONS |

The **Decision** question rendered in element 4 is sourced from the gate-decision table in
`phase-graph.md` — that table is the single source of the questions; this contract only renders them.
