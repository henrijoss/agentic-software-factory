# Incremental — Implementation Rules (depth)

Loaded on demand by the `incremental` skill. The SKILL.md states each rule in one line; the
elaboration, checks, and examples live here.

## Rule 0 — Simplicity first

Before writing code, ask: *"What is the simplest thing that could work?"* After writing it, review
against:

- Can this be done in fewer lines?
- Are these abstractions earning their complexity?
- Would a staff engineer say "why didn't you just…"?
- Am I building for hypothetical future requirements, or the current task?

```
✗ Generic EventBus with middleware pipeline for one notification   → ✓ a function call
✗ Abstract factory for two similar components                      → ✓ two components + shared util
✗ Config-driven form builder for three forms                       → ✓ three form components
```

Implement the naive, obviously-correct version first; optimize only after correctness is proven.
Three similar lines beat a premature abstraction. (This is the constitution's simplicity trade-off
default made operational at the keystroke level — if `[CONST]` sets a different default, follow it.)

## Rule 0.5 — Scope discipline

Touch only what the task requires. Do **not**: clean up adjacent code, refactor imports in files
you're not modifying, remove comments you don't understand, add unrequested "useful" features, or
modernize syntax in files you're only reading.

Note out-of-scope finds instead of fixing them:

```
NOTICED BUT NOT TOUCHING:
- src/utils/format.ts has an unused import (unrelated to this task)
- auth middleware error messages could be clearer (separate task)
→ Want me to create tasks for these?
```

## Rule 1 — One thing at a time

Each increment changes one logical thing.

- **Bad:** one commit that adds a component, refactors another, and updates the build config.
- **Good:** three separate commits, one per change.

## Rule 2 — Keep it compilable

After each increment the project builds and existing tests pass. Never leave the tree broken between
slices. For incomplete user-facing work you still want to merge, gate it behind a flag:

```ts
const ENABLE_TASK_SHARING = process.env.FEATURE_TASK_SHARING === 'true';
if (ENABLE_TASK_SHARING) { /* new sharing UI */ }
```

## Rule 3 — Safe defaults

New code defaults to conservative behavior — opt-in, not opt-out:

```ts
export function createTask(data: TaskInput, options?: { notify?: boolean }) {
  const shouldNotify = options?.notify ?? false;
}
```

## Rule 4 — Rollback-friendly

Each increment is independently revertable: prefer additive changes (new files/functions), keep
modifications minimal and focused, pair DB migrations with rollback migrations, and don't delete and
replace in the same commit — separate them.

## Common rationalizations

| Rationalization | Reality |
|---|---|
| "I'll test it all at the end" | Bugs compound — a bug in Slice 1 makes 2–5 wrong. Verify each slice. |
| "It's faster all at once" | Feels faster until something breaks and you can't find which of 500 lines did it. |
| "Too small to commit separately" | Small commits are free; large commits hide bugs and make rollback painful. |
| "I'll add the flag later" | If the feature isn't complete, it shouldn't be user-visible. Flag it now. |
| "This refactor is small enough to include" | Refactors mixed with features make both harder to review and debug. Separate. |
| "Let me run the build again to be sure" | After a green run, repeating with no code change adds nothing. Re-run after edits, not for reassurance. |
