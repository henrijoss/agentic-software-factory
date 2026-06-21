---
name: incremental
description: Per-session execution discipline — build in thin vertical slices that each leave the system working, instead of writing a whole feature in one pass. The posture `implement` runs while turning tasks into code. Use when a change touches more than one file, when a task feels too big to land in one step, or any time you're tempted to write a large amount of code before testing. Skip for single-function changes whose scope is already minimal.
---

# Incremental

## Overview

Build in **thin vertical slices**: implement one complete piece, verify it, commit, then expand.
Each increment leaves the system in a working, testable state. This is the execution discipline that
makes large work manageable — it does not decide *what* to build (`specify`/`to-tasks`) or design
*how* (`design`); it governs the *rhythm* of landing code.

`incremental` is a **posture**: it owns no artifact and has no slot in the loop. `implement` runs it
while turning tasks into code; it returns nothing but a cleaner, safer execution path.

## When to Use

- Implementing any multi-file change or a feature from a task breakdown.
- A task feels too big to land in one step.
- You're about to write more than ~100 lines before testing.
- Refactoring existing code.

**When NOT to use:**

- Single-file, single-function changes where scope is already minimal.
- Pure reads, summaries, or mechanical operations.

## Inputs / Outputs (abstract)

- **Input:** a Task (or small set) to execute, plus the **Constitution** `[CONST]` for the project's
  build/test commands and boundaries (resolve commands there — never hardcode them here).
- **Output:** none of its own. It shapes how `implement` produces code; verification of each slice
  routes through the `verify`/`test` skills.

## The increment cycle

For each slice: **Implement → Verify → Commit → Next.**

1. **Implement** the smallest complete piece of functionality.
2. **Verify** it works — run `verify`/`test` per the task (tests pass, build succeeds, behavior
   confirmed). Use the project's commands from `[CONST]`.
3. **Commit** with a descriptive message once the slice is green.
4. **Next slice** — carry forward, don't restart.

Run a verification command after a change that could affect it; don't re-run on unchanged code —
that adds no information.

## Slicing strategies

- **Vertical (preferred):** one complete path through the stack per slice (e.g. create → list →
  edit → delete), each delivering working end-to-end functionality.
- **Contract-first:** when front/back develop in parallel — define the contract, build each side
  against it, then integrate.
- **Risk-first:** tackle the most uncertain piece first (e.g. prove the connection works) so a dead
  end is found before investing in the rest.

See `references/slicing.md` for worked sequences.

## Implementation rules

- **Simplicity first.** Build the naive, obviously-correct version; don't abstract before a third
  use case demands it. Three similar lines beat a premature abstraction.
- **Scope discipline.** Touch only what the task requires. Don't "clean up while here", modernize
  files you're only reading, or add unrequested features. Note out-of-scope finds, don't fix them:
  *"NOTICED BUT NOT TOUCHING: … — want tasks for these?"*
- **One thing at a time.** Each increment changes one logical thing; don't mix a feature with a
  refactor and a config change in one commit.
- **Keep it compilable.** After every increment the project builds and existing tests pass — never
  leave the tree broken between slices. Gate incomplete user-facing work behind a flag if you must
  merge mid-feature.
- **Rollback-friendly.** Each increment is independently revertable; prefer additive changes, keep
  modifications focused, pair migrations with rollbacks.

Depth, code examples, and the simplicity/scope checks live in `references/rules.md`.

## Red Flags

- More than ~100 lines written without verifying.
- Multiple unrelated changes in one increment ("let me quickly add this too").
- Skipping verify to move faster; build/tests broken between increments.
- Large uncommitted changes accumulating.
- Abstracting before the third use case; new utility files for one-time operations.
- Touching files outside task scope "while I'm here".
- Re-running the same build/test command with no intervening code change.

## Verification

- [ ] Work was landed as thin slices, each independently verified and committed.
- [ ] The tree built and existing tests passed after every increment (never broken between slices).
- [ ] Each increment did one logical thing; refactors kept separate from features.
- [ ] Simplest-thing-that-works chosen; no abstraction added before a third use case.
- [ ] Scope held to the task; out-of-scope finds noted, not fixed.
- [ ] Build/test commands came from `[CONST]`, not hardcoded here.
