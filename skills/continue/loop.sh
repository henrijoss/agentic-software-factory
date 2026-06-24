#!/usr/bin/env bash
#
# Fresh-context implementation loop for the SDLC skillset (Ralph-style).
#
# Each iteration launches a BRAND-NEW `claude` session that runs ONE step. Because
# every step is a fresh process, context never grows across steps; index.md and the
# git history are the only memory carried forward.
#
# Each step's prompt is assembled fresh from three things, so the cold session has
# exactly the context it needs and nothing stale:
#   - the last 5 commits (git log -5) — what just happened in the code;
#   - the next task — taken from index.md's "Suggested next";
#   - a short "bigger picture" note from index.md — the intent that shapes how the
#     code should be structured.
# The step implements that task and ends with ONE semantic commit (the `commit` skill
# behavior), so history stays clean and granular, one commit per task.
#
# `auto` decides whether the run is interactive or unattended (no text sentinels):
#   - auto:false (default) — after each step the loop asks whether to run the next.
#   - auto:true            — the loop auto-advances every step until MAX_STEPS; the
#                            step runs `claude -p` (auto-exits) and `--auto` is passed
#                            so it skips its end-of-step questions too. Correctness
#                            checks inside the step still halt it.
# Turn it on with the `--auto` flag, the AUTO=1 env var, or settings.execution.auto.
#
# Usage:
#   skills/continue/loop.sh                 # interactive, drive /continue, up to MAX_STEPS
#   skills/continue/loop.sh "/some-prompt"  # any prompt/skill
#   skills/continue/loop.sh --auto          # unattended: auto-advance every step
#   MAX_STEPS=100 skills/continue/loop.sh   # env overrides the settings.json default
#
# The step cap defaults to docs/<root>/settings.json's execution.maxSteps (read via
# jq), falling back to 50; the MAX_STEPS env var always overrides.
#
# Run from the project root (where the docs/<root>/ tree lives).
set -euo pipefail

AUTO="${AUTO:-}"
ARGS=()
for arg in "$@"; do
  case "$arg" in
    --auto) AUTO=1 ;;
    *) ARGS+=("$arg") ;;
  esac
done

PROMPT="${ARGS[0]:-/continue}"

# Locate the SDLC tree (docs/<root>/) via its settings.json; index.md sits beside it.
SETTINGS_FILE="$(ls docs/*/settings.json 2>/dev/null | head -n1 || true)"
INDEX_FILE=""
[[ -n "$SETTINGS_FILE" ]] && INDEX_FILE="$(dirname "$SETTINGS_FILE")/index.md"

# Read a value from settings.json; fails quietly if jq/file/value is missing.
settings_value() {
  command -v jq >/dev/null 2>&1 || return 1
  [[ -n "$SETTINGS_FILE" ]] || return 1
  jq -er "$1" "$SETTINGS_FILE" 2>/dev/null
}

# Default step cap from settings.execution.maxSteps; MAX_STEPS env always overrides.
# Falls back to 50 if the file, jq, or the value is missing/invalid.
if [[ -z "${MAX_STEPS:-}" ]]; then
  MAX_STEPS="$(settings_value '.execution.maxSteps' || true)"
  [[ "$MAX_STEPS" =~ ^[0-9]+$ ]] || MAX_STEPS=50
fi

# settings.execution.auto also turns on unattended advance (the --auto flag/env override).
if [[ -z "$AUTO" ]] && [[ "$(settings_value '.execution.auto' || true)" == "true" ]]; then
  AUTO=1
fi

# Assemble the fresh step's context: last 5 commits + index.md's Status section
# (Suggested-next is the next task; the note there is the bigger picture). Seeded into
# the cold session so it understands what just happened and what to do next.
build_context() {
  printf 'Fresh implementation step — context for this step only.\n\n'
  printf 'Last 5 commits (git log -5):\n'
  git log -5 --oneline 2>/dev/null || printf '(no commits yet)\n'
  if [[ -n "$INDEX_FILE" && -f "$INDEX_FILE" ]]; then
    printf '\nWhere the project stands (index.md — next task + bigger picture):\n'
    awk '/^## Status/{f=1;print;next} f&&/^## /{exit} f{print}' "$INDEX_FILE"
  fi
  printf '\nImplement the Suggested-next task, keeping the above intent in mind (it shapes how the code is structured), then end with ONE semantic commit (the `commit` skill).\n'
}

step=0
while (( step < MAX_STEPS )); do
  step=$(( step + 1 ))
  printf '── step %d ─────────────────────────────────────────────\n' "$step"

  STEP_PROMPT="$PROMPT"
  # Under auto, pass --auto so the step skips its end-of-step questions (unless the
  # caller already put it in the prompt).
  if [[ -n "$AUTO" && "$STEP_PROMPT" != *--auto* ]]; then
    STEP_PROMPT="$STEP_PROMPT --auto"
  fi
  STEP_PROMPT="$STEP_PROMPT"$'\n\n'"$(build_context)"

  if [[ -n "$AUTO" ]]; then
    # Unattended: `claude -p` runs the step and auto-exits; the loop auto-advances.
    # No text sentinels — correctness checks inside the step halt it if needed.
    claude -p --dangerously-skip-permissions "$STEP_PROMPT" || true
    sleep 1
    continue
  fi

  # Interactive session: full TUI, normal permissions/picker. `|| true` so the loop's
  # own prompt — not claude's exit code — decides whether to continue.
  claude --dangerously-skip-permissions "$STEP_PROMPT" || true

  printf '\n'
  if ! read -r -p "loop: run the next step? [Y/n] " ans; then
    ans="n"  # no TTY / EOF -> stop cleanly
  fi
  case "$ans" in
    n|N|no|NO|q|Q|quit|QUIT)
      echo "loop: stopped after step $step."
      exit 0
      ;;
    *)
      : # advance to the next step
      ;;
  esac
done

echo "loop: reached MAX_STEPS=$MAX_STEPS. Stopping (raise MAX_STEPS to go further)."
