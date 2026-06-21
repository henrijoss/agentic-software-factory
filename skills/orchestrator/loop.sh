#!/usr/bin/env bash
#
# Fresh-context step loop for the SDLC skillset (Ralph-style).
#
# Each iteration is a BRAND-NEW `claude` process. It reads index.md cold, runs
# exactly one phase via the prompt (default `/continue`), writes the result to
# the artifact tree + index.md, and exits. The process then dies — so context is
# fully reset between steps. index.md is the only memory carried across steps.
#
# This is the fresh-process variant of `orchestrator`: orchestrator auto-advances
# the loop inside ONE session (context grows); this trades that for a cold process
# per step (context never grows).
#
# Driving the loop: a non-interactive `/continue` cannot pause for a human, so it
# writes its gate decision to `.sdlc/loop-control` (see continue/SKILL.md and
# continue/references/fresh-context.md). This script reads that file after each
# step:
#   continue     -> run the next step
#   done         -> the slice/loop is complete; stop cleanly
#   halt: <why>  -> a human is needed (ambiguous gate, sync drift, deploy/
#                   irreversible authorization, failed validation); stop and surface
#   (missing)    -> the step never reached its gate; stop (needs attention)
#
# Usage:
#   skills/orchestrator/loop.sh                 # drives /continue, up to MAX_STEPS
#   skills/orchestrator/loop.sh "/orchestrator" # any prompt/skill
#   MAX_STEPS=100 skills/orchestrator/loop.sh   # env overrides the settings.json default
#
# The step cap defaults to docs/<root>/settings.json's execution.maxSteps (read via
# jq), falling back to 50; the MAX_STEPS env var always overrides.
#
# Run from the project root (where `.sdlc/` and the docs/<root>/ tree live).
set -euo pipefail

CONTROL_FILE=".sdlc/loop-control"
PERMISSION_MODE="${PERMISSION_MODE:-acceptEdits}"
PROMPT="${1:-/continue}"

# Default step cap comes from settings.json (execution.maxSteps) beside the tree's
# index.md; the MAX_STEPS env var always overrides. Falls back to 50 if the file,
# jq, or the value is missing/invalid — defensive, never blocks the loop.
settings_max_steps() {
  command -v jq >/dev/null 2>&1 || return 1
  local f v
  f=$(ls docs/*/settings.json 2>/dev/null | head -n1)
  [[ -n "$f" ]] || return 1
  v=$(jq -e '.execution.maxSteps' "$f" 2>/dev/null) || return 1
  [[ "$v" =~ ^[0-9]+$ ]] || return 1
  printf '%s' "$v"
}

if [[ -z "${MAX_STEPS:-}" ]]; then
  MAX_STEPS="$(settings_max_steps || true)"
  MAX_STEPS="${MAX_STEPS:-50}"
fi

mkdir -p "$(dirname "$CONTROL_FILE")"

step=0
while (( step < MAX_STEPS )); do
  step=$(( step + 1 ))
  printf '── step %d ─────────────────────────────────────────────\n' "$step"

  rm -f "$CONTROL_FILE"

  claude -p "$PROMPT" --permission-mode "$PERMISSION_MODE"

  if [[ ! -f "$CONTROL_FILE" ]]; then
    echo "loop: no $CONTROL_FILE written — step did not reach its gate. Stopping." >&2
    exit 1
  fi

  state="$(tr -d '[:space:]' < "$CONTROL_FILE" | cut -c1-200)"
  case "$state" in
    done*)
      echo "loop: done — $(cat "$CONTROL_FILE")"
      exit 0
      ;;
    halt*)
      echo "loop: halted for a human — $(cat "$CONTROL_FILE")" >&2
      exit 0
      ;;
    continue*)
      : # advance to the next step
      ;;
    *)
      echo "loop: unknown control value '$state'. Stopping." >&2
      exit 1
      ;;
  esac
done

echo "loop: reached MAX_STEPS=$MAX_STEPS without 'done'. Stopping (raise MAX_STEPS to go further)."
