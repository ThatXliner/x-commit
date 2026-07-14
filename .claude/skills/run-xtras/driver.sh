#!/usr/bin/env bash
# Eval driver for the xtras plugin skills.
#
# Runs a skill headlessly (claude -p) against fixture inputs in a throwaway
# workspace, then grades the result with deterministic checks. This is the
# red-green loop for skill development: add a case, watch it fail, edit the
# skill's SKILL.md, re-run until green.
#
# Usage:
#   .claude/skills/run-xtras/driver.sh                    # run every case
#   .claude/skills/run-xtras/driver.sh x-humanizer        # one skill
#   .claude/skills/run-xtras/driver.sh x-humanizer rhythm # one case
#
# Env:
#   MODEL=sonnet   model passed to claude -p (default: sonnet)
#   KEEP_WS=1      keep workspaces on pass too (always kept on fail)
set -u

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
EVALS="$REPO/.claude/skills/run-xtras/evals"
MODEL="${MODEL:-sonnet}"
FILTER_SKILL="${1:-}"
FILTER_CASE="${2:-}"

pass=0; fail=0; failed_cases=()

run_claude() { # $1=workspace $2=prompt $3=allowedTools
  ( cd "$1" && claude -p "$2" \
      --model "$MODEL" \
      --allowedTools "$3" \
      --settings '{"disableAllHooks": true}' \
      > claude-output.txt 2>&1 )
}

report() { # $1=skill $2=case $3=0|1 $4=workspace
  if [ "$3" -eq 0 ]; then
    echo "PASS  $1/$2"
    pass=$((pass+1))
    [ "${KEEP_WS:-0}" = "1" ] || rm -rf "$4"
  else
    echo "FAIL  $1/$2   (workspace kept: $4)"
    fail=$((fail+1)); failed_cases+=("$1/$2")
  fi
}

run_case() { # $1=skill-name $2=case-dir
  local skill="$1" case_dir="$2" case_name ws
  case_name="$(basename "$case_dir")"
  [ -n "$FILTER_CASE" ] && [ "$case_name" != "$FILTER_CASE" ] && return

  ws="$(mktemp -d "${TMPDIR:-/tmp}/xtras-eval-$skill-$case_name-XXXXXX")"
  mkdir -p "$ws/.claude/skills"
  ln -s "$REPO/skills/$skill" "$ws/.claude/skills/$skill"

  local prompt allowed
  if [ "$skill" = "x-humanizer" ]; then
    cp "$case_dir/input.md" "$ws/input.md"
    prompt="Use the x-humanizer skill to rewrite input.md in place. Do not ask questions; just rewrite the file."
    allowed="Skill,Read,Write,Edit"
  else
    cp -R "$case_dir/fixture/." "$ws/"
    prompt="$(cat "$case_dir/prompt.txt")"
    allowed="Skill,Read,Write,Edit,Bash"
  fi

  echo "----- $skill/$case_name  (ws: $ws)"
  if ! run_claude "$ws" "$prompt" "$allowed"; then
    echo "  claude -p exited non-zero; output:"
    sed 's/^/  | /' "$ws/claude-output.txt" | tail -20
    report "$skill" "$case_name" 1 "$ws"
    return
  fi

  local rc=0
  if [ "$skill" = "x-humanizer" ]; then
    node "$EVALS/x-humanizer/check.mjs" "$ws/input.md" || rc=1
  else
    ( cd "$ws" && bash "$case_dir/check.sh" ) || rc=1
  fi
  report "$skill" "$case_name" "$rc" "$ws"
}

for skill_dir in "$EVALS"/*/; do
  skill="$(basename "$skill_dir")"
  [ -n "$FILTER_SKILL" ] && [ "$skill" != "$FILTER_SKILL" ] && continue
  for case_dir in "$skill_dir"cases/*/; do
    run_case "$skill" "$case_dir"
  done
done

echo
echo "== $pass passed, $fail failed"
[ "$fail" -gt 0 ] && printf '   red: %s\n' "${failed_cases[@]}"
exit "$fail"
