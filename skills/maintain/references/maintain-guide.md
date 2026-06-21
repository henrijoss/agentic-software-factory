# Maintain — Authoring Guide (depth)

Loaded on demand by the `maintain` skill. How the loop actually closes, triage discipline, the
append-only queue, incident vs. routine handling, staying tool-agnostic, and a worked example.

## How the loop closes (and why `maintain` doesn't fix)

The lifecycle is a cycle, not a pipeline. `deploy` puts a slice in operation;
operation generates signals; `maintain` turns those signals into the *input for the next iteration*.
The closing arrow is `maintain → specify`: selected work re-enters at `specify`, which updates the
Spec **in place** (anti-staleness) and the loop runs again on the next vertical slice.

Crucially, `maintain` **decides and routes — it does not implement**. A fix is itself a vertical
slice: it goes specify → … → implement → review → deploy like any other work. If `maintain` fixed
things directly it would bypass every gate and every artifact, silently diverging code from spec —
the exact failure this skillset fights. So the output of `maintain` is a *triaged, prioritized
decision*, not a code change.

## Triage discipline

For each signal, four decisions, in order:

| Decision | Question | Note |
|---|---|---|
| Severity | How bad / how urgent? | Use `[CONST]` bars; a sev-high incident may trigger immediate rollback via `[DEPLOY]` *before* normal triage |
| Dedupe | Does this already exist? | Merge into the existing `[MAINT]`/`[REQ-n]`; never fork a duplicate |
| Disposition | Fix-now / backlog / won't-fix? | Won't-fix is recorded with a reason, not silence |
| Repro | Can it be reproduced? | Capture steps so the eventual `test` can reproduce-first |

Dedupe is the maintenance counterpart to in-place update: two entries for one problem are two places
to go stale. Won't-fix being *explicit* matters — an undocumented dropped bug is a silent liability
that resurfaces later with no record of the decision.

## Incident vs. routine

- **Incident (live breakage):** safety first. The `[DEPLOY]` entry carries the rollback handle —
  consider rolling back *before* triaging the fix, so users aren't sitting in breakage while you
  decide. Record the incident and the rollback in `[MAINT]` afterward.
- **Routine (bug report, regression, request):** normal triage → queue → batch into the closing gate.

## Append-only queue — why not in-place

Same reasoning as the Deploy log: `[MAINT]` is an **accreting record**, not a single current-state
artifact. Entries are appended and individually updated (status changes as an item is picked up or
closed), but the queue as a whole is never overwritten — you need the history of what was reported,
triaged, and decided. `index.md`'s status dashboard reflects the *current* open load; the queue
carries the timeline.

## Stay tool-agnostic

Where signals come from differs per project — a GitHub issue tracker, Sentry/monitoring alerts,
support tickets, user emails. `maintain` describes *what* to do with a signal, not *where* it lives.
Sources, severity bars, and escalation/rollback boundaries resolve from `[CONST]`. If `[CONST]` is
silent on signal sources or severity, that's a gap — ask, and consider whether the answer belongs in
the constitution so the next cycle doesn't re-ask.

## The closing gate — what it decides

Not "is the queue triaged?" but **"which discovered work re-enters the loop, at what priority?"** It
forces a real prioritization decision: of everything in the queue, what does the next iteration
build? That's a human call (it sets the project's direction), which is why it earns its interruption.
On approval the selected item(s) hand to `specify`.

## Worked example — post-ship of REQ-03

```
Read [DEPLOY]: REQ-03 live as v1.4.0; rollback = deploy:rollback v1.3.4.
Signals (per [CONST]: GitHub issues + Sentry):
  - #212 Sentry: digest sent twice on job retry  (5 users affected)
  - #213 user request: "let me snooze an alert"
  - Sentry noise: transient SMTP timeout, self-recovered

Triage:
  MAINT-04  #212  sev: high   dedupe: relates REQ-03, new   disp: fix-now   repro: kill job mid-send
  MAINT-05  #213  sev: low    dedupe: new feature           disp: backlog   (a future slice)
  -         SMTP  sev: noise  self-recovered                disp: won't-fix (note: add alert threshold?)

Append MAINT-04, MAINT-05 to queue; update index.md (open: 1 high, 1 backlog).
Gate-validation: links to REQ-03 / DEPLOY resolve  ✓

Closing gate:
  "Open maintenance: MAINT-04 (high, double-send) and MAINT-05 (low, snooze).
   Which re-enters the loop now, at what priority?"
  → user: MAINT-04 now as next slice; MAINT-05 backlog.
Hand MAINT-04 to specify → updates spec in place → next iteration begins. Loop closed.
```

Note: the double-send fix goes to `specify`, not straight to a code edit — it's a new slice through
the full loop. And the won't-fix SMTP item is *recorded*, with a follow-up question, not silently
dropped.
