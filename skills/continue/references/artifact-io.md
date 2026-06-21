# Artifact I/O Binding (depth)

Loaded on demand by the `continue` base skill. The single place that maps **abstract artifacts** used
by the SDLC skillset to concrete **storage operations**. Skills reference artifacts abstractly ("read
the Requirement", "write N Tasks") and resolve *how* to store/retrieve them here — not in the individual
skills. The artifact tree, invariants, and bootstrap are summarized in the `continue` `SKILL.md`; this
file carries the storage binding for the canonical **local-files** store, plus the **optional GitHub edge
integrations**.

## Abstract artifacts

| Artifact | ID | Produced by | Consumed by | Description |
|---|---|---|---|---|
| **Constitution** | `CONST` | `constitution` | every phase | Standing principles/constraints; the project's non-negotiables |
| **Specification** | `SPEC` | `specify` | `to-requirements` | What we're building and why; objective, scope, success criteria |
| **Stakeholder** | `STK-<n>` | `to-requirements` | `clarify`, `review` | Who cares about the outcome and what they need |
| **Requirement** (Use-case) | `REQ-<n>` | `to-requirements` | `clarify` → `design` | One unit of desired behavior/value |
| **Plan** (design) | `REQ-<n>.DESIGN` | `design` | `to-tasks` | Implementation approach, architecture, risks for one Requirement |
| **Task** | `REQ-<n>.TASK-<m>` | `to-tasks` | `implement` | Small, verifiable unit of work with acceptance criteria |
| **SessionSummary** | `REQ-<n>.SESSION` | `implement` | `implement` (next), `review` | Fresh-context handoff: what's done, what's next, open issues |
| **Deploy log** | `DEPLOY` | `deploy` | `maintain` | Record of what shipped and when |
| **Maintenance queue** | `MAINT` | `maintain` | `specify` | Triaged live issues fed back into the loop |

## Structural invariants (the tree)

The artifact tree MUST satisfy these — they are the contract, not implementation detail:

1. **Single entry point.** Exactly one root object per project; every artifact is reachable from it.
2. **Single tree.** Artifacts form one tree; no second root, no detached subgraph.
3. **ID registry.** The root maps every stable artifact ID → its location. References target IDs,
   never raw paths buried in prose. IDs are rename-safe.
4. **Gate validation.** A validation step runs at every gate and FAILS on: a dangling ID, a
   duplicate ID, an unregistered/orphan artifact, or any artifact unreachable from the root.

These invariants — plus the in-place-update rule (re-entering a phase updates its artifact, never
forks a duplicate) — are what keep spec and code from silently diverging.

## Storage: local files (canonical, git-versioned)

Local files are the **single canonical store** — there is no swappable backend. Filesystem artifacts
under the repo, versioned with code. One tree per project, rooted at
`docs/<root>/index.md` — the root name is chosen at `setup`, **default `sdlc`** (`docs/sdlc/`). The
tables and paths below use `docs/sdlc/` as that default; resolve the actual root by discovery (see
"Resolve the tree root" in the `continue` base skill).

```
docs/<root>/          ← root chosen at `setup`; default `docs/sdlc/`
  index.md            ← SINGLE ENTRY POINT: tree map + ID registry + live phase/gate status
  constitution.md     ← [CONST]
  spec.md             ← [SPEC]
  requirements/
    REQ-01/
      requirement.md  ← [REQ-01]   (Stakeholders referenced by ID)
      design.md       ← [REQ-01.DESIGN]
      tasks/
        TASK-01.md    ← [REQ-01.TASK-01]
      sessions/
        summary.md    ← [REQ-01.SESSION]
    REQ-02/ …
  deploy/log.md       ← [DEPLOY]      (optional — appears when deploy runs)
  maintenance/queue.md← [MAINT]       (optional — appears when maintain runs)
```

**`index.md` — the root object** plays three roles simultaneously:
- **Tree map:** the navigable structure (which artifacts exist and how they nest).
- **ID registry:** a table of ID → path for every artifact (the lookup that resolves references).
- **Status dashboard:** each artifact's current phase/gate state, so the driver knows where the
  project stands and updates it as phases advance.

| Artifact | Storage | Read | Write |
|---|---|---|---|
| Constitution | `docs/sdlc/constitution.md` | read file | write file (in place) |
| Specification | `docs/sdlc/spec.md` | read file | write file (in place) |
| Stakeholders | section within `spec.md` (or `requirements/` refs) | read section | write file (in place) |
| Requirement | `docs/sdlc/requirements/REQ-<n>/requirement.md` | read file | create dir + file; register in `index.md` |
| Plan (design) | `requirements/REQ-<n>/design.md` | read file | write file (in place) |
| Task | `requirements/REQ-<n>/tasks/TASK-<m>.md` | read file | create file; register in `index.md` |
| SessionSummary | `requirements/REQ-<n>/sessions/summary.md` | read file | write file (in place) |
| Deploy log | `docs/sdlc/deploy/log.md` | read file | append entry |
| Maintenance queue | `docs/sdlc/maintenance/queue.md` | read file | append/triage entry |

**Optional levels.** Directories materialize only when their producing skill runs. A one-off
`implement` may create just `index.md` + `spec.md` + one task file — no `requirements/` layer. The
single-entry-point invariant still holds.

**In-place update.** Re-entering a phase overwrites that phase's artifact file; it never creates a
parallel copy. Git history carries the versioning — and this is *why* files are canonical: one commit
changes an artifact and the code it governs **atomically**, a feature branch carries that slice's whole
artifact state, and the in-place overwrite shows up as a reviewable diff (the reconciliation record).
No remote tracker offers those, which is what makes files the source of truth.

**Tree-root resolution & bootstrap.** The single entry point `docs/<root>/index.md` must exist before
any artifact is written. The root is **discovered** (the one SDLC `index.md`, default location
`docs/sdlc/`); creation is **idempotent** and owned as follows:

1. **`setup` is the explicit init.** It picks the root name (default `sdlc`) and scaffolds the minimal
   `index.md`. Run once at project start.
2. **A driver resolves/falls back.** At session start the `continue` base skill (or `orchestrator`)
   discovers the single `index.md`; if none exists (no `setup` run), it creates the **default**
   `docs/sdlc/` minimal root. Idempotent — an existing tree is left untouched, never forked.
3. **Phase skills are the last-resort fallback.** A phase skill run standalone resolves the root the
   same way before writing its first artifact (e.g. `constitution`).

So the entry point is guaranteed whether the project starts fresh, mid-loop, or from a single skill,
and the root location is configurable — keeping the four invariants satisfiable from the very first
write. Minimal root:

```markdown
# SDLC Index — [project]
## Tree map
(empty — artifacts register here as phases run)
## ID registry
| ID | Path | Status |
|----|------|--------|
## Status
Project: bootstrapped — no phases run yet.
```

(Brownfield projects read `bootstrapped (brownfield: <stack>) — no phases run yet` — a one-line signal
from `setup`, never a code inventory.)

## GitHub issues — optional edge integrations (not a backend)

GitHub issues are **not** a storage backend for the tree. The artifact tree never lives in issues: it
would forfeit atomic spec+code commits, branch-per-slice, and the diff-as-reconciliation record (see
*In-place update* above) — the exact properties that make the tree the source of truth. The canonical
truth always stays in `docs/<root>/`, versioned. Issues integrate only at the **edges**:

- **Inbound → `maintain`.** Issues are one *live-signal source*, not storage. `maintain` already
  resolves its signal sources from `[CONST]` (trackers, monitoring, support) and triages them into the
  `[MAINT]` queue. A GitHub-issues tracker is just one such source declared in `[CONST]`; nothing in
  the tree moves into issues.
- **Outbound (optional) → mirror.** Requirements/Tasks may be projected **one-way** to issues for
  assignment, notifications, and stakeholder visibility. This is a **derived view**, never the source
  of truth: regenerated from the files, and on any drift the files win. Mirroring tooling is out of
  scope here — this names the seam, it does not implement it.
