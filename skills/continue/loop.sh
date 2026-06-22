#!/usr/bin/env bash
#
# Fresh-context step loop for the SDLC skillset (Ralph-style).
#
# Two modes:
#
# INTERACTIVE (default). Each iteration launches a BRAND-NEW interactive `claude`
# session running one step (default `/continue`). You see the real app TUI, and it
# has full, normal access — permission prompts and the gate picker work exactly as in
# a hand-run session. An interactive session does not auto-exit, so you end it (Ctrl-D
# or /exit) when the step is done; the loop then asks whether to run the next step —
# Enter/y to continue, n/q to stop. That between-step prompt is the loop's only stop
# control (it replaces the old `.sdlc/loop-control` file contract).
#
# HEADLESS (`--headless` / `-p`, or HEADLESS=1). Each step runs `claude -p`, which
# auto-exits when the step is done, and the loop AUTO-ADVANCES to the next step with no
# operator prompt — a true unattended Ralph loop. Headless has no interactive picker, so
# the driver signals the loop with text sentinels on its last line (see the headless
# sentinel contract in references/fresh-context.md):
#   <sdlc-done>COMPLETE</sdlc-done>     → project complete; loop exits 0.
#   <sdlc-gate>PAUSE: <reason></sdlc-gate> → a gate needs a human; loop prints it & stops.
#   (no sentinel)                        → routine advance; loop runs the next step.
# Pair headless with `gatePolicy: auto` so only safety-floor / pause gates interrupt;
# the loop warns if gatePolicy is anything else.
#
# Because each step is a fresh process, context never grows across steps in either mode;
# index.md is the only memory carried forward. No stream-json, no sandbox: the step can
# install/build/test like normal.
#
# Usage:
#   skills/continue/loop.sh                 # interactive, drive /continue, up to MAX_STEPS
#   skills/continue/loop.sh "/some-prompt"  # any prompt/skill
#   skills/continue/loop.sh --headless      # unattended; auto-exit + auto-advance per step
#   skills/continue/loop.sh --headless "/some-prompt"
#   MAX_STEPS=100 skills/continue/loop.sh   # env overrides the settings.json default
#
# The step cap defaults to docs/<root>/settings.json's execution.maxSteps (read via
# jq), falling back to 50; the MAX_STEPS env var always overrides.
#
# Run from the project root (where the docs/<root>/ tree lives).
set -euo pipefail

HEADLESS="${HEADLESS:-}"
ARGS=()
for arg in "$@"; do
  case "$arg" in
    --headless|-p) HEADLESS=1 ;;
    *) ARGS+=("$arg") ;;
  esac
done

PROMPT="${ARGS[0]:-/continue}"

# Default step cap comes from settings.json (execution.maxSteps) beside the tree's
# index.md; the MAX_STEPS env var always overrides. Falls back to 50 if the file,
# jq, or the value is missing/invalid — defensive, never blocks the loop.
settings_value() {
  command -v jq >/dev/null 2>&1 || return 1
  local f
  f=$(ls docs/*/settings.json 2>/dev/null | head -n1)
  [[ -n "$f" ]] || return 1
  jq -er "$1" "$f" 2>/dev/null
}

if [[ -z "${MAX_STEPS:-}" ]]; then
  MAX_STEPS="$(settings_value '.execution.maxSteps' || true)"
  [[ "$MAX_STEPS" =~ ^[0-9]+$ ]] || MAX_STEPS=50
fi

# Headless auto-advances past routine gates, so it only behaves under gatePolicy auto.
# Warn (never block) if it isn't — non-auto gates will keep tripping the pause sentinel.
if [[ -n "$HEADLESS" ]]; then
  GATE_POLICY="$(settings_value '.execution.gatePolicy' || true)"
  if [[ -n "$GATE_POLICY" && "$GATE_POLICY" != "auto" ]]; then
    printf 'loop: WARNING — headless with gatePolicy=%s; non-auto gates will pause the run. Set execution.gatePolicy=auto for unattended runs.\n' "$GATE_POLICY" >&2
  fi
fi

# Directive appended to the step prompt in headless mode so the driver follows the
# sentinel contract (references/fresh-context.md) instead of an interactive picker.
HEADLESS_DIRECTIVE='Headless run: no interactive picker is available — do not call AskUserQuestion. Follow the headless sentinel contract in the continue skill: at an advance gate end on the saved confirmation; if a safety-floor or pause gate needs a human, emit a final line `<sdlc-gate>PAUSE: <reason></sdlc-gate>` and stop; when no next step remains, emit a final line `<sdlc-done>COMPLETE</sdlc-done>`.'

step=0
while (( step < MAX_STEPS )); do
  step=$(( step + 1 ))
  printf '── step %d ─────────────────────────────────────────────\n' "$step"

  if [[ -n "$HEADLESS" ]]; then
    # Headless: `claude -p` runs the step and auto-exits. Capture its output (still
    # shown live) so we can read the sentinels that decide whether to advance/stop.
    OUTPUT=$(claude -p --dangerously-skip-permissions "$PROMPT"$'\n\n'"$HEADLESS_DIRECTIVE" 2>&1 | tee /dev/stderr) || true

    if grep -q '<sdlc-done>' <<<"$OUTPUT"; then
      echo "loop: project complete (<sdlc-done>). Stopped after step $step."
      exit 0
    fi
    if grep -q '<sdlc-gate>PAUSE' <<<"$OUTPUT"; then
      printf 'loop: a gate needs a human after step %d — %s\n' "$step" \
        "$(grep -o '<sdlc-gate>PAUSE[^<]*' <<<"$OUTPUT" | head -n1)"
      echo "loop: inspect, then rerun to resume (state is in index.md)."
      exit 1
    fi
    sleep 1  # advance to the next step automatically
    continue
  fi

  # Interactive session: full TUI, normal permissions/picker. `|| true` so the
  # loop's own prompt — not claude's exit code — decides whether to continue.
  claude --dangerously-skip-permissions "$PROMPT" || true

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
