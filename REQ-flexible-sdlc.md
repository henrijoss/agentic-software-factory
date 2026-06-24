# REQ — Flexible, requirement-centric, git-backed SDLC skillset

**As a** solo operator driving this skillset **I want** to navigate phases freely by
intent, treat specs as living documents, and let git be the durable record of
ephemeral design/task work **so that** the system stops forcing a rigid forward march
and bends to how I actually work.

**Status:** complete · implementation requirement (this file is the source of truth for the
rework; work each acceptance criterion below one by one, in order). **All ACs (AC-1…AC-9) and the
cross-cutting checks (CC-1…CC-4) done & verified.**

---

## Context / why

Today `continue` is a graph sequencer locked to
`constitution → specify → … → deploy → maintain`, gated at every arrow, tuned by a large
`gatePolicy`/`gateOverrides`/`traversal`/`milestones` apparatus. Requirements pass
through `clarify` once; `design.md` and `tasks/` persist forever; `deploy`/`maintain`
sit on the mainline even with nothing deployed. The rework replaces the **enforced
graph** with **intent + a smart suggestion**, makes specs **living**, makes
design/tasks **ephemeral (git = record)**, collapses the gate apparatus to **one `auto`
switch**, and commits **semantically per implementation step**. The valuable invariants
stay: single artifact tree, `index.md` entry point, in-place update, pure-transform
skills, fresh-context loop, gate-*validation* (correctness checks).

## Out of scope

- Any swappable storage backend (local files + git remain the only store).
- Unattended/headless sentinel orchestration (removed, not reworked).
- Changing the posture skills' internal mechanics (`interview`, `doubt`, `incremental`).

## Glossary

- **Living spec** — `constitution.md`, `spec.md`, `requirement.md`: durable, re-editable
  any time (before/after implementation), updated in place, never "closed".
- **Ephemeral scaffolding** — `design.md`, `tasks/`, `sessions/`: working files removed
  once a requirement's slice is finished; recoverable from git.
- **Suggestion** — the smart, context-fitting "what to do next" `continue` proposes from
  `index.md`; advisory, never forced.
- **`auto`** — the single switch (settings default + per-invocation override) that makes
  skills skip their end-of-step questions and the driver auto-take the suggestion.

---

## Acceptance criteria

> Implement and verify these **in order**. Each is independently checkable. Do not mark
> one done until its verification passes.

### AC-1 — Driver: intent router + suggester (no enforced graph)
Files: `skills/continue/SKILL.md`, `skills/continue/references/phase-graph.md`

- [x] **AC-1.1** `continue`'s Process "determine next step" is rewritten so that, given
      explicit user intent (e.g. "refine REQ-2's design"), it routes **directly** to that
      phase on that artifact and updates it **in place** — no intervening forced graph
      step.
- [x] **AC-1.2** With **no** explicit intent, `continue` reads `index.md`'s
      *last-worked + suggested-next* and **proposes** the suggested step plus 1–2
      alternatives for the operator to pick; it never auto-marches a fixed sequence
      (unless `auto`, per AC-2).
- [x] **AC-1.3** `phase-graph.md` is demoted to an **advisory "what usually follows next"**
      reference. All of the following are **removed** from it: "every `→` is a human
      gate", the milestone (`★`) column/concept, the safety-floor (`⚠`) gate table framing
      tied to `gatePolicy`, and all `traversal`/`depth-first`/`requirements-first` content.
- [x] **AC-1.4** `deploy`, `maintain`, and `verify`/`test` are documented as **opt-in** —
      suggested only when applicable (a deployment/release/observable behavior exists),
      never as mandatory mainline steps.
- [x] **AC-1.5** Retained and still documented in `continue`: tree-root discovery, the
      four structural invariants, **gate-validation** (dangling / duplicate / orphan /
      unreachable still runs as a correctness check), and the git **sync check**.
- [x] **Verify:** In a project with ≥2 REQs, `/continue` + "refine REQ-2's design" routes
      to `design` on REQ-2 in place; `/continue` with no intent proposes a step +
      alternatives; `deploy`/`maintain` are absent from suggestions when nothing is
      deployed.

### AC-2 — Settings collapsed to one `auto` switch
Files: `skills/continue/SKILL.md` (Settings), `skills/setup/SKILL.md`

- [x] **AC-2.1** `settings.json` `execution` block is exactly:
      `{ "maxSteps": <int>, "auto": false, "reviewLoops": 1, "commitPerStep": true }`.
- [x] **AC-2.2** `gatePolicy`, `gateOverrides`, `traversal`, and `verifyMode` are removed
      from the schema **and** from every prose mention across all skills/references
      (grep-clean: no remaining occurrences except possibly a changelog note).
- [x] **AC-2.3** `auto` is overridable per invocation — documented form `/continue --auto`
      and the driver passing `auto` down to a skill it runs.
- [x] **AC-2.4** `auto: true` semantics documented: skills skip their end-of-step
      questions and the driver auto-takes the suggested next step; `auto: false` (default)
      keeps the interactive hand-off (AC-5).
- [x] **AC-2.5** `setup` writes the new `execution` defaults; the gate-autonomy precedence
      prose (safety floor → overrides → policy) is deleted from `continue` and
      `fresh-context.md`.
- [x] **Verify:** `grep -ri 'gatepolicy\|gateoverrides\|traversal\|verifymode\|depth-first\|requirements-first\|milestone'` over `skills/` and `README.md` returns nothing (outside an explicit changelog line). `settings.json` example matches AC-2.1.

### AC-3 — Living specs
Files: `skills/specify/SKILL.md`, `skills/clarify/SKILL.md`, `skills/continue/references/artifact-io.md`

- [x] **AC-3.1** `specify` and `clarify` explicitly state `spec.md` / `requirement.md` are
      **living specs**: re-entered freely before *and* after implementation, always
      updated in place, never "closed/done".
- [x] **AC-3.2** `clarify`'s one-way "draft → ready" framing is removed; a requirement can
      be re-clarified at any point, including mid/post-implementation when code teaches
      something new.
- [x] **AC-3.3** `artifact-io.md` lists `spec.md` and `requirement.md` as durable
      (in-place, never deleted) and contrasts them with the ephemeral set (AC-4).
- [x] **Verify:** clarify a REQ → implement it → re-enter `clarify` to update it post-impl;
      `requirement.md` updates in place with no fork and no "already ready, cannot
      re-open" friction.

### AC-4 — Ephemeral design/tasks; git is the record
Files: `skills/continue/SKILL.md`, `skills/continue/references/{artifact-io,handoff}.md`,
`skills/design/SKILL.md`, `skills/to-tasks/SKILL.md`, `skills/implement/SKILL.md`

- [x] **AC-4.1** `design`, `to-tasks`, `implement`, and the `continue` system overview each
      state that `design.md` + `tasks/` are **working scaffolding**, removed when the
      requirement's slice is finished, and that the durable history (why something was
      built, prior approaches to reuse) lives in **git commits/tree**.
- [x] **AC-4.2** `continue` defines the cleanup: when a requirement is marked finished, the
      driver **deletes** `requirements/REQ-n/design.md` and `requirements/REQ-n/tasks/`,
      **removes their IDs** from `index.md` (registry + tree map), and **keeps**
      `requirement.md`.
- [x] **AC-4.3** "Finished" is defined explicitly: a requirement is finished when its
      implementation work is committed and the operator (or `auto`) confirms no further
      work is queued on it — at which point AC-4.2 cleanup runs.
- [x] **AC-4.4** `artifact-io.md` includes a recovery pointer: how to retrieve a removed
      design/task from git (`git log -- <path>` / `git show <sha>:<path>`).
- [x] **Verify:** finish a REQ → `design.md` and `tasks/` are gone, their IDs gone from
      `index.md`, `requirement.md` remains; `git show <sha>:docs/sdlc/requirements/REQ-n/design.md`
      still recovers the old design.

### AC-5 — Interactive loop-by-default + rich end-of-step hand-off
Files: `skills/clarify/SKILL.md`, `skills/design/SKILL.md`,
`skills/continue/references/presentation.md`

- [x] **AC-5.1** `clarify` and `design` **loop by default**: every iteration **writes** the
      artifact in place before the hand-off.
- [x] **AC-5.2** The end-of-step hand-off contract (replacing the heavy
      banner/phase-map/`── GATE ──` format) is defined as, in order:
      (1) surface **critical open topics** still needing discussion;
      (2) if none are critical, offer **related topics + concrete examples** worth exploring;
      (3) present the choice **Progress to next phase · Continue with a topic · Stop here**.
- [x] **AC-5.3** `presentation.md` is rewritten to this lighter conversational contract;
      the `━━━ PHASE N/11 ━━━` banner, vertical phase map, milestone/`⚠` markers, and the
      headless `<sdlc-*>` sentinel section are removed.
- [x] **AC-5.4** Under `auto`, the hand-off questions are skipped and the suggested next
      step is taken automatically.
- [x] **Verify:** a `clarify`/`design` step writes the artifact, then surfaces
      critical/related topics + the 3-way choice; "Continue with a topic" re-runs in place;
      with `--auto` the step writes and advances with no questions.

### AC-6 — Commit-per-step + new `commit` skill
Files: new `skills/commit/SKILL.md`; `skills/implement/SKILL.md`;
`skills/continue/loop.sh`

- [x] **AC-6.1** A new pure-transform **`commit`** skill exists with `SKILL.md`
      frontmatter (`name: commit`, description) following the repo's skill conventions; it
      takes a finished change and produces a **semantic** commit
      (`type(scope): subject`, e.g. `feat`/`fix`/`refactor`/`docs`) on `main`.
- [x] **AC-6.2** `commit` is system-agnostic (no tree/ID/storage knowledge) like the other
      phase skills, and documents the conventional-commit type set it uses.
- [x] **AC-6.3** `implement` calls `commit` at the end of each task (clean, granular
      history), unless an `auto`/loop run defers committing to the loop (AC-7.2).
- [x] **Verify:** an `implement` task ends with one semantic commit on `main`;
      `git log --oneline` shows clean per-task history.

### AC-7 — `loop.sh`: simpler, commit-driven implementation loop
Files: `skills/continue/loop.sh`, `skills/continue/references/fresh-context.md`

- [x] **AC-7.1** Each iteration passes the fresh step: the **last 5 commits**
      (`git log -5`), the **next task**, and a **short "bigger picture" note** sourced from
      `index.md` (so the session understands intent that influences code structure).
- [x] **AC-7.2** The loop commits after each task (semantic, via the `commit` skill
      behavior).
- [x] **AC-7.3** The headless `<sdlc-done>`/`<sdlc-gate>` sentinel contract and the
      `gatePolicy=auto` warning are removed from `loop.sh` and `fresh-context.md`;
      unattended runs use the `auto` param instead.
- [x] **AC-7.4** The fresh-process-per-step core and the `MAX_STEPS`/`execution.maxSteps`
      cap are retained.
- [x] **Verify:** `loop.sh` runs an implementation step with last-5-commits + next-task +
      context in the prompt, commits after the task, and contains no `<sdlc-*>` sentinel
      logic; `MAX_STEPS` still bounds the run.

### AC-8 — `index.md` handoff; drop `sessions/`
Files: `skills/continue/SKILL.md`, `skills/continue/references/artifact-io.md`,
`skills/implement/SKILL.md`

- [x] **AC-8.1** `index.md`'s status section is redefined as **Last worked:** … /
      **Suggested next:** … / **Last synced commit:** … — the cross-step memory the driver
      reads in AC-1.2.
- [x] **AC-8.2** The per-slice `sessions/summary.md` handoff is **removed**: the
      `sessions/` tree level and the `[REQ-n.SESSION]` ID are deleted from the tree diagram,
      `artifact-io.md`, and `implement`'s references; its role is carried by `index.md` +
      last-5-commits.
- [x] **Verify:** the tree diagrams in `continue`, `README.md`, and `artifact-io.md` no
      longer show `sessions/` or `[REQ-n.SESSION]`; `index.md`'s status uses the
      Last-worked/Suggested-next/Last-synced shape.

### AC-9 — Docs
Files: `README.md`

- [x] **AC-9.1** "The loop" section reframed: advisory graph + free navigation + opt-in
      deploy/maintain (no "every `→` is a human gate").
- [x] **AC-9.2** "Resume, jump, and refine" updated for intent routing + the AC-5
      end-of-step hand-off + `auto`.
- [x] **AC-9.3** "Storage" + the generated file tree updated: living specs vs. ephemeral
      design/tasks (git = record), no `sessions/`, new `settings.json` schema, the `commit`
      skill added to the skills table.
- [x] **AC-9.4** Settings/skillset-version prose updated to the new `execution` schema.
- [x] **Verify:** `README.md` describes the new model end-to-end and contains none of the
      removed concepts (AC-2.2 grep clean).

---

## Cross-cutting consistency check (run after all ACs)

- [x] **CC-1** Repo-wide grep for removed terms (AC-2.2 list + `sessions/`, `SESSION`,
      `<sdlc-`, `gate picker`, `milestone gate`) returns nothing stray.
- [x] **CC-2** Every tree diagram across `continue`, `README.md`, `artifact-io.md`,
      `phase-graph.md` is identical and reflects: living `spec.md`/`requirement.md`,
      ephemeral `design.md`/`tasks/`, no `sessions/`, `commit` skill present. *(phase-graph.md
      holds the advisory phase-flow graph, not an artifact tree — the three artifact-tree
      diagrams are consistent.)*
- [x] **CC-3** The skills table in `README.md` lists `commit` and no longer implies a
      forced graph or gate-policy tuning.
- [x] **CC-4** `SDLC_SKILLSET_VERSION` is bumped (0.1.0 → 0.2.0)
      and `setup`'s default `settings.json` matches AC-2.1.
