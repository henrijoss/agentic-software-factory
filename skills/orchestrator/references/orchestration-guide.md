# Orchestrator — Auto-Advance Semantics (depth)

Loaded on demand by the `orchestrator` skill. Covers what the orchestrator adds over the `continue`
base skill: **auto-advance semantics** and a worked example.

The phase graph, gate-decision table, entry modes, and tree-root bootstrap are **owned by the
`continue` base skill** — see `continue`'s `references/phase-graph.md` (graph + gates + entry modes)
and `references/artifact-io.md` (storage + bootstrap). The orchestrator does not restate them; it
walks them and auto-advances.

## Auto-advance semantics

- Advance **only** on explicit approval (a real "yes", not silence or a vague nod).
- Before advancing, run **gate-validation**; a failure blocks the advance and is surfaced.
- On rejection: route per the phase — rework re-enters the **same** phase; a *legitimate divergence*
  (code/learning outran an upstream artifact) re-enters `specify`/`design` for an **in-place** update,
  never a fork. Do not advance past an unresolved gate.
- `deploy` carries an extra, inverted gate *before* its action (explicit ship authorization); honor it
  even within a driven session — review approval ≠ ship approval.
- Keep `index.md` status current at each step so a later **resume** (via `continue`) is accurate.
- The difference from `continue`: `continue` stops after one phase; the orchestrator loops back to the
  next phase automatically after each approved gate.

## Worked example — fresh project, first slice

```
Entry: full project. index.md absent → bootstrap minimal root (base skill).
Start phase: constitution (no [CONST] yet).

constitution → gate "commit these standing principles?" → yes; index.md: CONST registered.
specify       → gate "objective/scope/success right, ready to fan out?" → yes; SPEC registered.
to-requirements → fan out 3 REQs + stakeholders; gate "right use-cases? which first?" → REQ-01 first.
clarify (REQ-01) → gate "unambiguous enough to design?" → yes.
design  (REQ-01) → invokes doubt; gate "approach/risks acceptable?" → yes; REQ-01.DESIGN.
to-tasks(REQ-01) → 3 tasks + dep graph; gate "sized/ordered/graph correct?" → yes.
implement → fresh-context loop + incremental; gate "does slice do what task claims? which verify?" → test+verify.
verify/test → green; gate "behavior confirmed, ready for review?" → yes.
review → invokes doubt; 1 blocker → re-enter implement → re-review → clean; gate "findings resolved?" → yes.
deploy → checklist ok; AUTHORIZATION gate "ship REQ-01 v0.1.0, rollback known?" → yes; ship; [DEPLOY] appended.
maintain → 1 incident triaged; closing gate "which work re-enters, priority?" → MAINT-01 next slice.
→ specify (slice 2): updates SPEC in place. Loop closed.
```

Each `→` is one phase loaded, run, gated, and (on yes) auto-advanced — one phase in context at a time.
Running this one step at a time instead (stopping after each gate) is exactly the `continue` base
skill.
