# Maintain — Authoring Guide (depth)

Loaded on demand by the `maintain` skill. How the loop actually closes, triage discipline, the
append-only queue, incident vs. routine handling, staying tool-agnostic, and a worked example.

## How the loop closes (and why `maintain` doesn't fix)

The lifecycle is a cycle, not a pipeline. `deploy` puts a slice in operation;
operation generates signals; `maintain` turns those signals into the *input for the next iteration*.
The closing arrow is `maintain → specify`: selected work re-enters at `specify`, which revises the
Spec (anti-staleness) and the loop runs again on the next vertical slice.

Crucially, `maintain` **decides and routes — it does not implement**. A fix is itself a vertical
slice: it goes specify → … → implement → review → deploy like any other work. If `maintain` fixed
things directly it would bypass every gate and every artifact, silently diverging code from spec —
the exact failure this skillset fights. So the output of `maintain` is a *triaged, prioritized
decision*, not a code change.

## Triage discipline

For each signal, four decisions, in order:

| Decision | Question | Note |
|---|---|---|
| Severity | How bad / how urgent? | Use the **Constitution**'s bars; a sev-high incident may trigger immediate rollback via the Deploy log's handle *before* normal triage |
| Dedupe | Does this already exist? | Merge into the existing queue entry / Requirement; never fork a duplicate |
| Disposition | Fix-now / backlog / won't-fix? | Won't-fix is recorded with a reason, not silence |
| Repro | Can it be reproduced? | Capture steps so the eventual `test` can reproduce-first |

Dedupe is the maintenance counterpart to in-place update: two entries for one problem are two places
to go stale. Won't-fix being *explicit* matters — an undocumented dropped bug is a silent liability
that resurfaces later with no record of the decision.

## Incident vs. routine

- **Incident (live breakage):** safety first. The Deploy log entry carries the rollback handle —
  consider rolling back *before* triaging the fix, so users aren't sitting in breakage while you
  decide. Record the incident and the rollback in the queue afterward.
- **Routine (bug report, regression, request):** normal triage → queue → batch into the closing gate.

## Append-only queue — why not overwrite

Same reasoning as the Deploy log: the queue is an **accreting record**, not a single current-state
artifact. The skill emits entries; the driver appends and individually updates them (status changes as
an item is picked up or closed), but the queue as a whole is never overwritten — you need the history
of what was reported, triaged, and decided. The driver-maintained status reflects the *current* open
load; the queue carries the timeline.

## Stay tool-agnostic

Where signals come from differs per project — a GitHub issue tracker, Sentry/monitoring alerts,
support tickets, user emails. `maintain` describes *what* to do with a signal, not *where* it lives.
Sources, severity bars, and escalation/rollback boundaries resolve from the **Constitution**. If it is
silent on signal sources or severity, that's a gap — ask, and consider whether the answer belongs in
the constitution so the next cycle doesn't re-ask.

## The closing gate — what it decides

Not "is the queue triaged?" but **"which discovered work re-enters the loop, at what priority?"** It
forces a real prioritization decision: of everything in the queue, what does the next iteration
build? That's a human call (it sets the project's direction), which is why it earns its interruption.
On approval the selected item(s) hand to `specify`.

## Worked example — post-ship of REQ-03

```
Read the Deploy log: saved-search alerts live as v1.4.0; rollback = deploy:rollback v1.3.4.
Signals (per the Constitution: GitHub issues + Sentry):
  - #212 Sentry: digest sent twice on job retry  (5 users affected)
  - #213 user request: "let me snooze an alert"
  - Sentry noise: transient SMTP timeout, self-recovered

Triage (emitted as entries; the driver appends them):
  double-send   #212  sev: high   dedupe: relates to alerts slice, new   disp: fix-now   repro: kill job mid-send
  snooze alert  #213  sev: low    dedupe: new feature                    disp: backlog   (a future slice)
  SMTP noise    -     sev: noise  self-recovered                         disp: won't-fix (note: add alert threshold?)

Driver appends the two actionable entries; status → open: 1 high, 1 backlog.

Closing gate:
  "Open maintenance: double-send (high) and snooze-alert (low).
   Which re-enters the loop now, at what priority?"
  → user: double-send now as next slice; snooze backlog.
Driver routes the double-send fix to specify → revises spec → next iteration begins. Loop closed.
```

Note: the double-send fix goes to `specify`, not straight to a code edit — it's a new slice through
the full loop. And the won't-fix SMTP item is *recorded*, with a follow-up question, not silently
dropped.
