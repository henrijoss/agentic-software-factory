# Sync — Git Drift Detection (depth)

Loaded on demand by the `continue` base skill. Defines the
**sync check**: how the driver detects code committed **outside** the system since it last ran, and
reconciles the artifact tree against it. The driver runs this at session start, after resolving the
tree root and before determining the next step.

## Why this exists

The skillset's anti-staleness rule (in-place re-entry + gate-validation) only catches drift introduced
**through** the system. A human or another agent that commits code **between** system sessions is
invisible to it — open `[REQ-*]`/`[TASK-*]` may already be **resolved** (or **invalidated**) by changes
the artifacts never saw. That is the field's top failure mode (a stale spec executed confidently)
arriving through the one door in-place update leaves open. The sync check makes the canonical git store
itself the staleness signal: `index.md` records the last commit the system reconciled against, and the
driver compares it to `HEAD`.

Scope is **committed changes only** — `HEAD` vs the recorded hash. Uncommitted working-tree edits are
out of scope (deliberately: the recorded-hash mechanism is git-history based and deterministic).

## The recorded hash

`index.md`'s status dashboard carries `Last synced commit: <sha | none>` — the git `HEAD` the system
last reconciled against. It is **not** a precise equality gate; it is a cheap trigger. The value is in
reading the diff when it differs, not in the equality itself.

### Own-commit gap (by design)

A file that records "the current commit" can never contain the hash of the commit that writes it
(chicken-and-egg). So the system's own prior-session commit **always** shows as drift on the next run.
This is expected, not a bug: the reconciliation reads `recorded..HEAD`, sees the changes are already
reflected in the artifacts at `HEAD` (the artifacts in that commit already describe them), confirms
cheaply with no churn, and re-records `HEAD`. Never suppress the check to avoid this — the confirm is
fast, and the same pass is what catches *genuine* external drift.

## Procedure

1. Read `Last synced commit` from `index.md`.
2. Get current head: `git rev-parse HEAD`.
3. Branch:
   - **Git absent / no commits / recorded base unreachable** → graceful degrade (below): treat as
     no-drift, set `Last synced commit` to the current `HEAD` if one exists else `none`, proceed.
   - **`HEAD` == recorded** → no external drift; proceed to the next phase.
   - **`HEAD` != recorded** → reconcile (below).

Inspect the delta with:

```
git diff --stat <recorded>..HEAD      # which files changed, how much
git log  --oneline <recorded>..HEAD   # commit subjects — intent of the external work
```

Read the actual diff for any file that maps onto open work before deciding.

## Graceful degradation

The sync check **never blocks a phase** on git state.

- **Not a git repo / no `.git`** → record `none`, skip, proceed.
- **No commits yet** (`git rev-parse HEAD` fails) → record `none`, skip, proceed.
- **Shallow clone / recorded base unreachable** (`recorded..HEAD` errors) → can't compute the delta;
  surface that the check was inconclusive, re-record `HEAD`, proceed (don't fabricate reconciliation).

## The sync gate

On real drift, hold a gate like any other — surface the **decision**, never "looks good?":

> External commits `<recorded>..HEAD` changed `<files>`. These may resolve `[TASK-…]` and invalidate
> the design assumption in `[REQ-…]`. Which open work do you want to mark resolved, re-confirm, or
> re-open — and what re-enters the loop?

In the headless `loop.sh` loop, this gate holds like every other safety-floor gate: it always writes
`halt` — no auto-advance past unresolved drift, whatever the `gatePolicy`.

## Reconciliation routing

Reconciliation **reuses existing in-place re-entry** — it introduces no new mechanism.

| External change implies | Route |
|---|---|
| A task is already done in the code | Mark the `[TASK-*]` done; confirm via `implement`→`review` if behavior is unverified |
| A slice's behavior changed but is sound | Re-enter `design` to update `[REQ-*.DESIGN]` in place |
| A requirement's premise no longer holds | Re-enter `specify`/`clarify` to update `[SPEC]`/`[REQ-*]` in place |
| Pure refactor, no open work affected | No re-entry; just re-record `HEAD` |

After the operator's decision is applied, set `Last synced commit = HEAD`.

## Worked example

Recorded `5818f37`; `HEAD` is `2afb020`.

```
$ git log --oneline 5818f37..HEAD
2afb020 Add SDLC skillset with brownfield orientation and local-files-canonical storage
$ git diff --stat 5818f37..HEAD
 skills/... | ...
```

Driver reads the subjects and diff, maps them to open work: the changes implement `[REQ-02.TASK-03]`
end-to-end. It holds the sync gate proposing to mark `TASK-03` resolved and re-confirm via `review`.
Operator approves; driver marks the task done in `index.md`, queues `review`, and sets
`Last synced commit = 2afb020`. Next run, `HEAD` == recorded → fast path.
