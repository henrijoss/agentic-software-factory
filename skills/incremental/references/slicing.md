# Incremental — Slicing Strategies (depth)

Loaded on demand by the `incremental` skill. Worked sequences for the three slicing strategies.

## Vertical slices (preferred)

One complete path through the stack per slice — each delivers demonstrable end-to-end value.

```
Slice 1: Create a task   (DB + API + basic UI) → user can create a task via the UI
Slice 2: List tasks      (query + API + UI)    → user can see their tasks
Slice 3: Edit a task     (update + API + UI)   → user can modify a task
Slice 4: Delete a task   (delete + API + UI + confirm) → full CRUD complete
```

Each slice is narrow but full-depth, so the system is always usable and each step is independently
verifiable. This mirrors the loop's vertical-slice unit of iteration.

## Contract-first slicing

When backend and frontend must progress in parallel, pin the contract first so both sides have a
stable target:

```
Slice 0:  Define the contract (types, interfaces, OpenAPI)
Slice 1a: Backend against the contract + API tests
Slice 1b: Frontend against mock data matching the contract
Slice 2:  Integrate and test end to end
```

## Risk-first slicing

Tackle the most uncertain piece first so a dead end surfaces before you invest in the rest:

```
Slice 1: Prove the WebSocket connection works  (highest risk)
Slice 2: Real-time updates on the proven connection
Slice 3: Offline support and reconnection
```

If Slice 1 fails, you learn it before building Slices 2–3 on a bad assumption. Pairs naturally with
the `doubt` posture: the riskiest slice is exactly where an adversarial fresh-context review pays off.

## Directing the work explicitly

Be explicit about what is in and out of scope for each increment:

```
Implement Task 3. Start with just the schema change and the API endpoint.
Don't touch the UI yet — next increment. Verify per the task before moving on.
```
