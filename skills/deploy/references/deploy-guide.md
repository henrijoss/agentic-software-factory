# Deploy — Authoring Guide (depth)

Loaded on demand by the `deploy` skill. Why deploy's gate is shaped differently, the pre-ship
checklist rationale, the append-only log, staying mechanism-agnostic, and a worked example.

## Why deploy's gate is inverted (authorization *before* the action)

Every other phase gate sits *after* the work: produce an artifact, then ask "is this right?". Deploy
can't — its work is the irreversible act itself. Publishing puts content where it can be cached,
indexed, or depended on; "undo" is rollback, not deletion, and is never guaranteed clean. So deploy
splits the gate:

- **Pre-ship authorization gate (step 3)** — the load-bearing one. Forces an explicit decision to
  perform an outward-facing, hard-to-reverse action, with the rollback plan visible. This mirrors the
  harness rule: confirm before irreversible/outward actions, and approval in one context (review)
  does not extend to the next (ship).
- **Post-ship handoff gate (step 6)** — lighter: confirm it landed and record what's now live, then
  hand to `maintain`.

A review "yes" is not a ship "yes." Ask at step 3 every time, even mid-driven-session.

## The pre-ship checklist — why each item

| Item | Failure it prevents |
|---|---|
| Review gate passed, no unresolved blockers | Shipping a known-broken slice |
| Tree structurally valid (the driver gate-validates at the gate) | Shipping with a stale/dangling artifact tree (the top failure mode) |
| Build/checks green per the **Constitution** | Publishing an artifact that doesn't build |
| Rollback known | Discovering at incident time that there's no way back |

"Rollback known" means *written down before shipping* — a command, a previous version handle, or a
revert sha. Deciding how to undo while the site is broken is too late.

## Append-only Deploy log — why not overwrite

Most artifacts are updated in place on re-entry (anti-staleness). The Deploy log is the deliberate
exception: it is a **chronological record of events**, not a single current-state artifact. Each ship
is a new fact; overwriting would erase the history you need to answer "what went live when, and how do
we roll back which release?". So `deploy` emits a log *entry* and the driver **appends** it — never
overwriting prior entries. The driver-maintained status still reflects the *current* operational
state; the log carries the timeline.

## Stay mechanism-agnostic (like `review` did with tooling)

`deploy` describes *what* shipping requires (authorization, checklist, log, rollback), never *which*
commands. Projects differ wildly — static prerender + CDN push, container deploy, npm publish, app
store submit, a `git push` to a deploy branch, a `/deploy` command. All of that resolves from the
**Constitution**:

- the **Constitution** declares the **ship commands** and their order/environments.
- the **Constitution** declares the **boundaries**: ask-first steps, never-without-X rules (e.g.
  "never deploy to prod on a Friday", "staging must pass before prod", "tag a release first").

If the **Constitution** is silent on how to ship, that's a gap — stop and ask, then consider whether the answer
belongs in the constitution so the next ship doesn't re-ask. Do not hardcode a procedure here.

## Partial-ship failures

If a multi-step ship fails midway (e.g. staging succeeded, prod push errored), do **not** continue or
retry blindly into an unknown half-shipped state. Stop, invoke the rollback plan, and report the
state plainly. Record the attempt in the log too — a failed/rolled-back ship is a fact worth keeping.

## Worked example — saved-search alerts → prod

```
Read the Constitution: ship = `npm run build && npm run deploy:prod`; boundary = "staging green before prod".

Pre-ship checklist:
- review gate: passed, 0 blockers, 1 trade-off documented        ✓
- tree structurally valid (driver gate-validated)                ✓
- build: green; staging deploy green                             ✓
- rollback: `npm run deploy:rollback v1.3.4` / revert abc123     ✓

Authorization gate:
  "About to ship the saved-search alerts slice to PROD as v1.4.0 via deploy:prod.
   Rollback: deploy:rollback v1.3.4. Authorize ship?"  → user: yes

Ship: build ✓ → deploy:prod ✓

Emit Deploy log entry (driver appends it):
  ## 2026-06-20 — saved-search alerts
  - Shipped: the saved-search alerts slice  | prod, v1.4.0
  - Commands: npm run build && npm run deploy:prod
  - Outcome: success
  - Rollback: npm run deploy:rollback v1.3.4 / revert abc123
Driver updates status: saved-search alerts → deployed (v1.4.0).

Handoff gate: "Shipped cleanly as v1.4.0; alerts live in prod. On to maintain?" → yes
```

Note: the authorization gate names the **target, version, commands, and rollback** — enough for a
real go/no-go decision, not "ready to deploy?".
