---
name: commit
description: Turns one finished change into a single semantic commit on `main` — a conventional-commit `type(scope): subject` that records what changed and why, so the git history stays clean and granular. Use at the end of a task or any self-contained change to capture it as one well-formed commit. Distinct from `implement` (which writes the code): this only records it. Not for deciding what to build or splitting work.
---

# Commit

## Overview

`commit` takes a **finished change** already present in the working tree and records it as **one
semantic commit** on `main`. Its whole job is the commit: stage the change, write a conventional-commit
message that says *what* changed and *why*, and commit it. Clean, granular history is the durable record
the rest of the system leans on — it is where the reasoning behind a change, and the prior approaches
worth reusing, actually live once the ephemeral scaffolding is gone.

This is a **pure transform**: working tree in, one commit out. It does not write code (that's
`implement`), decide the approach (`design`), or split work (`to-tasks`). It assumes the change is
already complete and verified — `commit` does not fix, finish, or test it.

## When to Use

- At the **end of a task** in `implement`, to capture that task as one commit.
- After any **self-contained change** that should stand as its own entry in history.
- Whenever the working tree holds finished work that hasn't been recorded yet.

**When NOT to use:**

- The change isn't finished or hasn't passed `verify`/`test` — commit records, it doesn't complete.
- You want many unrelated changes in one commit — split them into one `commit` per logical change.
- An `auto`/loop run that **defers** committing to the loop — the loop commits per task instead (see
  the loop's per-task commit behavior); don't double-commit.

## Inputs / Outputs (abstract)

- **Input:** a **finished change** in the working tree, provided by the caller, plus enough context to
  name *why* it was made (the task/intent it satisfies). The caller may pass a suggested **type** and
  **scope**; otherwise infer them from the change.
- **Output:** exactly **one commit on `main`** with a conventional-commit message. The skill touches
  only git — it resolves no SDLC storage, assigns no IDs, and does not read or write the artifact
  tree/`index.md`.

## Process

### 1. Read the change

Inspect the working tree (`git status`, `git diff`) to see exactly what changed. Confirm it is a single
logical change; if it spans several unrelated changes, commit them separately, one `commit` per logical
unit.

### 2. Choose type and scope

Pick the conventional-commit **type** that fits the change (table below) and an optional **scope** —
the area touched (a module, component, or subsystem). Use the caller's suggested type/scope when given.

### 3. Write the message

Compose `type(scope): subject` — imperative, lower-case, no trailing period, the subject naming *what*
changed. When the *why* isn't obvious from the subject, add a short body explaining the reasoning,
constraints, or trade-off (the part git history exists to preserve).

### 4. Stage and commit

Stage the change and create the commit on `main`. One change → one commit. Do not amend or squash prior
commits; each finished change earns its own entry.

## Commit message shape

```
type(scope): subject

[optional body — why the change was made; constraints, trade-offs, context]
```

**Conventional-commit type set:**

| Type       | Use for                                                        |
|------------|---------------------------------------------------------------|
| `feat`     | a new capability or user-visible behavior                     |
| `fix`      | a bug fix                                                      |
| `refactor` | restructuring with no behavior change                         |
| `docs`     | documentation only                                            |
| `test`     | adding or correcting tests                                    |
| `chore`    | tooling, deps, config, or other non-source housekeeping       |
| `perf`     | a performance improvement                                     |
| `style`    | formatting/whitespace with no semantic change                 |

## Composability (big↔small)

A tiny fix is one `commit` with a one-line subject and no body. A larger task still produces **one**
commit, but earns a body explaining why. Never batch several tasks into one commit to "save history" —
granularity is the point.

## Red Flags

- Committing unfinished or unverified work — `commit` records finished changes only.
- Bundling unrelated changes into one commit instead of one commit per logical change.
- Vague subjects ("update", "fix stuff", "wip") that don't say what changed.
- Wrong type (`feat` for a refactor, `fix` for a new feature).
- Amending/squashing earlier commits instead of adding a new one.
- Double-committing when an `auto`/loop run already commits per task.
- Reading or writing the artifact tree/`index.md` — `commit` touches only git.

## Verification

- [ ] Exactly **one commit** created on `main` for one logical change.
- [ ] Message is `type(scope): subject`, imperative and concise, with the type chosen from the set above.
- [ ] The *why* is captured (in the subject, or a body when not obvious).
- [ ] The committed change was already finished and verified — `commit` didn't complete it.
- [ ] No SDLC storage touched (no tree/`index.md`/ID work).
