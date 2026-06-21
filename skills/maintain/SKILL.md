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

It owns no in-place artifact. Its output is the **Maintenance queue** `[MAINT]` — triaged entries
appended over time — and a gate that decides *which* discovered work re-enters the loop, *at what
priority*. Like `deploy`, it stays tool-agnostic: where signals come from (trackers, monitoring,
support) resolves from `[CONST]`, not this skill.

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

- **Input:** live signals (bugs, incidents, reports, alerts), the **Deploy log** `[DEPLOY]` (what is
  in operation and how to roll it back), and the **Constitution** `[CONST]` (signal sources,
  severity/priority bars, escalation boundaries). Read existing artifacts so triage dedupes against
  what already exists.
- **Output:** **Maintenance queue** entries `[MAINT]`. Storage resolves through
  the `continue` base skill (default `docs/sdlc/maintenance/queue.md`). Triage is **append/update of
  entries**, not an in-place overwrite of the whole queue — the queue accretes over time.

## Process

### 1. Gather signals against what's live

Collect the live signals from the sources `[CONST]` declares, and read `[DEPLOY]` to know **what is
actually in operation** (version, slice IDs, rollback handle). A report is only actionable against the
deployed reality — confirm the signal concerns what's currently live, not an old build.

### 2. Triage each signal

For each signal, decide and record:

- **Severity** — impact + urgency (per `[CONST]`'s bars; an incident may need immediate rollback via
  the `[DEPLOY]` handle, ahead of normal triage).
- **Dedupe** — does this match an existing `[MAINT]` entry or an open `[REQ-n]`? Merge rather than
  fork a duplicate (the same anti-staleness discipline as the rest of the tree).
- **Disposition** — *fix-now* / *backlog* / *won't-fix (accepted)*. Won't-fix is a conscious,
  recorded decision, not silence.
- **Reproduction** — for a bug, the steps/conditions, so the eventual `test` can reproduce-first.

### 3. Append to the Maintenance queue

Write triaged items as `[MAINT]` entries via artifact-io (default append to
`docs/sdlc/maintenance/queue.md`): signal, severity, disposition, dedupe link, repro. Append/update
entries — don't overwrite the queue. Update `index.md` status to reflect open maintenance load.

### 4. Run gate-validation

Run the artifact **gate-validation** per the `continue` base skill (no dangling / duplicate / orphan /
unreachable ID) — entries that link to `[REQ-n]`/`[DEPLOY]` must resolve.

### 5. Gate → specify (closes the loop)

Present the triaged queue and force the decision: *"Which discovered work re-enters the loop, at what
priority?"* This gate earns its interruption — it sets what the next iteration builds. On explicit
approval, hand the selected item(s) to `specify`, which updates the Spec **in place** for the next
vertical slice. The loop is now closed.

## Artifact shape

Append-only queue; full field guidance and a worked example in `references/maintain-guide.md`.

```markdown
## [MAINT-04] 2026-06-20 — Alert digest sent twice on retry
- Source: prod incident #212 (per [CONST])      | Severity: high
- Affects: REQ-03 (live v1.4.0 per [DEPLOY])
- Disposition: fix-now → re-enter specify as next slice
- Dedupe: relates to REQ-03; not a duplicate of MAINT-02
- Repro: trigger job, kill mid-send, job retries → second digest
```

## Composability (big↔small)

A solo project may keep a three-line queue and route one bug at a time to `specify`. A larger one
adds severity tiers, incident handling with immediate rollback, and periodic backlog triage. Never
skip the **dedupe** check (forks duplicate work) or the **closing gate** (the loop only closes when a
human picks what re-enters).

## Red Flags

- Treating a signal against an old build as live (read `[DEPLOY]` for what's actually in operation).
- Forking a duplicate entry instead of merging into an existing `[MAINT]`/`[REQ-n]`.
- Fixing the issue inside `maintain` instead of routing it back through `specify`.
- Silent won't-fix — undocumented dropped issues are a liability.
- Overwriting the queue instead of appending (loses the maintenance history).
- Hardcoding signal sources/trackers instead of resolving them from `[CONST]`.

## Verification

- [ ] Signals gathered from `[CONST]`-declared sources; checked against `[DEPLOY]`'s live state.
- [ ] Each signal triaged: severity, dedupe, disposition (fix-now / backlog / won't-fix), repro.
- [ ] Entries **appended** to `[MAINT]` (not overwritten); `index.md` status updated.
- [ ] Gate-validation clean (links to `[REQ-n]`/`[DEPLOY]` resolve).
- [ ] Closing gate posed; selected work explicitly approved and handed to `specify` (loop closed).
