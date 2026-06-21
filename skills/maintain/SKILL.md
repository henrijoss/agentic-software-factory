---
name: maintain
description: Watches a shipped slice in operation and turns live signals — bugs, incidents, user reports, regressions — into triaged work that re-enters the loop through `specify`. The phase that closes the SDLC cycle. Use after `deploy`, when something live needs attention, or to triage an accumulating issue backlog. Not for the first confirmation a change works (`verify`/`test`) or the pre-ship review (`review`).
---

# Maintain

## Overview

`maintain` is the phase that **closes the loop**. It observes the slice now in operation (per the
Deploy log) and the live signals it generates — bugs, incidents, regressions, user reports,
monitoring alerts — and converts them into **triaged work** that re-enters the lifecycle at
`specify`. Without it the loop is a one-way pipeline; with it the lifecycle is a cycle
(`maintain → specify`).

Its output is **Maintenance queue** entries — triaged items emitted per the result contract, which the
driver appends over time — and a gate that decides *which* discovered work re-enters the loop, *at what
priority*. Like `deploy`, it stays tool-agnostic: where signals come from (trackers, monitoring,
support) resolves from the **Constitution**, not this skill.

## When to Use

- After `deploy`, to watch the live result and capture what it surfaces.
- A live bug, incident, regression, or user report needs triage.
- An accumulated issue backlog needs to be triaged and prioritized for the next slice.

**When NOT to use:**

- The first confirmation a change works — that's `verify`/`test`.
- The pre-ship adversarial pass — that's `review`.
- Actually *fixing* a triaged item — that loops back through `specify` → … → `implement`; `maintain`
  decides and routes, it doesn't implement.

## Inputs / Outputs (abstract)

- **Input:** live signals (bugs, incidents, reports, alerts), the **Deploy log** (what is in operation
  and how to roll it back), the **Constitution** (signal sources, severity/priority bars, escalation
  boundaries), and the existing queue/requirements so triage dedupes — all provided by the caller.
- **Output:** **Maintenance queue** entries emitted per the result contract for the caller to ingest.
  The driver appends/updates entries (never overwriting the whole queue — it accretes over time); the
  skill resolves no SDLC storage itself.

## Process

### 1. Gather signals against what's live

Collect the live signals from the sources the **Constitution** declares, and read the **Deploy log** to
know **what is actually in operation** (version, slice, rollback handle). A report is only actionable
against the deployed reality — confirm the signal concerns what's currently live, not an old build.

### 2. Triage each signal

For each signal, decide and record:

- **Severity** — impact + urgency (per the **Constitution**'s bars; an incident may need immediate
  rollback via the Deploy log's rollback handle, ahead of normal triage).
- **Dedupe** — does this match an existing queue entry or an open Requirement? Merge rather than
  fork a duplicate (the same anti-staleness discipline as the rest of the work).
- **Disposition** — *fix-now* / *backlog* / *won't-fix (accepted)*. Won't-fix is a conscious,
  recorded decision, not silence.
- **Reproduction** — for a bug, the steps/conditions, so the eventual `test` can reproduce-first.

### 3. Emit the triaged entries

Produce the triaged items: signal, severity, disposition, dedupe link, repro. Emit them per the result
contract; the driver appends/updates the queue and updates status. Structural gate-validation over the
tree (links resolve, no dangling/duplicate IDs) is the driver's job at ingest, not this skill's.

### 4. Gate (closes the loop)

Present the triaged queue and force the decision: *"Which discovered work re-enters the loop, at what
priority?"* This gate earns its interruption — it sets what the next iteration builds. Surface it for
the caller — standalone, present it to the user; under a driver, the driver holds the gate and routes
the selected item(s) to `specify` (which updates the Spec in place for the next slice). The loop closes.

## Artifact shape

Append-only queue; full field guidance and a worked example in `references/maintain-guide.md`.

```markdown
## 2026-06-20 — Alert digest sent twice on retry
- Source: prod incident #212 (per the Constitution)   | Severity: high
- Affects: the saved-search alerts slice (live v1.4.0 per the Deploy log)
- Disposition: fix-now → re-enter specify as next slice
- Dedupe: relates to the alerts slice; not a duplicate of an existing entry
- Repro: trigger job, kill mid-send, job retries → second digest
```

## Composability (big↔small)

A solo project may keep a three-line queue and route one bug at a time to `specify`. A larger one
adds severity tiers, incident handling with immediate rollback, and periodic backlog triage. Never
skip the **dedupe** check (forks duplicate work) or the **closing gate** (the loop only closes when a
human picks what re-enters).

## Red Flags

- Treating a signal against an old build as live (read the Deploy log for what's actually in operation).
- Forking a duplicate entry instead of merging into an existing queue entry / Requirement.
- Fixing the issue inside `maintain` instead of routing it back through `specify`.
- Silent won't-fix — undocumented dropped issues are a liability.
- Resolving SDLC storage / persisting the queue instead of emitting entries (that's the driver's job).
- Hardcoding signal sources/trackers instead of resolving them from the **Constitution**.

## Verification

- [ ] Signals gathered from **Constitution**-declared sources; checked against the Deploy log's live state.
- [ ] Each signal triaged: severity, dedupe, disposition (fix-now / backlog / won't-fix), repro.
- [ ] Entries emitted per the result contract (driver appends; not persisted by the skill).
- [ ] Closing gate posed; selected work routed to `specify` by the caller/driver (loop closed).
