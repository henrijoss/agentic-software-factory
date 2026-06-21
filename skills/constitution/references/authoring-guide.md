# Constitution — Authoring Guide (depth)

Loaded on demand by the `constitution` skill. The SKILL.md core stays lean; the elaboration,
template, tests, and a worked example live here.

## What a constitution is for

It answers, once, the questions every phase would otherwise re-ask:

- What does "good" mean here? (quality bars, taste)
- What can't change? (tech constraints, non-negotiables)
- What needs a human before it happens? (boundaries)
- When two reasonable values conflict, which wins? (trade-off defaults)

Spec Kit calls this the "governing principles" layer and makes it phase zero. The reason it comes
first: every later artifact (spec, design, tasks, code) inherits it, so getting it wrong is the most
expensive mistake to make late.

## The single hard rule: ruthless leanness

Every phase reads the constitution, so every line is paid for on **every** run against the model's
~150–200 standing-instruction budget. A 60-line constitution silently taxes specify, design,
implement, review — all of them. This is why the budget test is non-negotiable:

> **For each candidate line: would a later phase change its behavior because of it?**
> If you can't name the phase and the changed behavior, cut the line.

Target ~5–12 principles total. If it reads like documentation, it is too big.

## Principle vs. not — quick tests

| Looks like a principle | Actually it's… | Where it belongs |
|---|---|---|
| "Use PostgreSQL" | a tech constraint | Constraints — but only if it's truly fixed; else the spec |
| "The login form should validate email" | a feature requirement | the spec / requirement |
| "Prefer the simplest thing that works" | a trade-off default | Trade-off defaults |
| "We use pnpm, not npm" | already in CLAUDE.md | **Reference it**, don't copy |
| "Be nice to users" | unactionable platitude | cut it |
| "Never commit secrets" | a real boundary | Boundaries → Never |

The discriminator is always the budget test: a principle is something a downstream phase **acts on**.

## Harvesting checklist (Step 1–2)

Read, in this order, before writing or asking anything:

- [ ] `CLAUDE.md` (root + any nested) — usually the richest source of standing rules.
- [ ] `README` — project intent, stack, conventions.
- [ ] `docs/adr/` or equivalent — past decisions that are now constraints.
- [ ] Memory files — durable preferences and project constraints.
- [ ] Existing config that encodes rules (linter config, CI) — reference, don't transcribe.

For each rule found: does it have an authoritative home already? If yes → **reference** it. If no →
it's a candidate for the constitution body.

## Full template with section guidance

```markdown
# Constitution — [project name]

## Principles
<!-- 3–8 durable values the project commits to. Each: the principle + why, one line.
     These are the lines phases consult when no more specific rule applies. -->
- [principle] — [why it matters]

## Constraints (non-negotiable)
<!-- Hard technical/process facts that are FIXED for this project. Omit if none are truly fixed —
     don't invent constraints to fill the section. -->
- [constraint]

## Boundaries
<!-- The always/ask-first/never tiers. Keep each list short and genuinely load-bearing. -->
- Always: [action that must happen every time]
- Ask first: [action requiring a human gate]
- Never: [action that is forbidden]

## Trade-off defaults
<!-- The recurring tensions and which side wins by default. This is where the constitution
     earns its keep: it stops the same argument from recurring at every phase. -->
- When [X] and [Y] conflict, prefer [Z] because [reason].

## References
<!-- Rules that live authoritatively elsewhere. Single source of truth: link, never copy. -->
- [topic] → see `path/to/source` ([what it governs])
```

Sections are **optional**. A small project may have only Principles + References. Empty sections are
deleted, not left as headers — a blank "Constraints" still costs a reader's attention.

## Worked example — this repo (photography portfolio)

Demonstrates reference-don't-duplicate: the tooling/structure rules already live in `CLAUDE.md`, so
the constitution references them and adds only what has no other home.

```markdown
# Constitution — @loop/photography

## Principles
- Build UI only from @loop/ui components; never hand-roll controls — consistency over local convenience.
- Self-explanatory code over comments; comment only the non-obvious why.
- Generated artifacts are derived, never hand-edited (photos.ts, routeTree.gen.ts, grid.db reads).

## Constraints (non-negotiable)
- pnpm workspace; the app consumes @loop/ui's built dist/, never its src.

## Boundaries
- Always: run `pnpm check` before a commit.
- Ask first: adding a dependency, adding a shadcn/Base UI component to @loop/ui.
- Never: edit generated files by hand; commit secrets.

## Trade-off defaults
- When simplicity and flexibility conflict, prefer simplicity until a third use case demands the abstraction.

## References
- Tooling, commands, monorepo layout, image pipeline → see `CLAUDE.md` (authoritative).
- GitHub issue editing discipline → see `CLAUDE.md` + `github-issue-sync` skill.
```

Note the size: ~12 lines of actual law. Everything mechanical stays in `CLAUDE.md`; the constitution
adds only durable principles, the few fixed constraints, boundaries, and one trade-off default.

## Re-entry (anti-staleness)

When values harden or a constraint changes, re-run `constitution` — it **overwrites
`constitution.md` in place**. Never create `constitution-v2.md` or a parallel section; git history is
the versioning. After amending, the gate-validation at the next gate confirms no reference went
stale.

## Anti-patterns (expanded)

- **The kitchen sink.** Auto-generating an everything-included constitution from the codebase. This
  is a documented failure mode: past ~150–200 standing instructions, compliance degrades, so a fat
  constitution makes *every* phase follow rules *less* reliably.
- **Spec smuggling.** Feature requirements dressed as principles ("the dashboard must load in 2s").
  Those are spec/requirement content; they change per feature and don't belong in standing law.
- **Duplication.** Restating CLAUDE.md rules. Now there are two sources; one will drift.
- **Platitudes.** "Write clean code," "be user-focused." Unactionable → no phase changes behavior →
  cut.
- **Padding.** Filling every template section because it's there. Sections are optional; delete what
  doesn't apply.
