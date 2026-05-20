#!/bin/bash
# Remind to run tests when implementation files were modified this session.
# Uses the CLAUDE.md stack manifest to map modified paths to stacks and surface
# each stack's test_cmd as the suggested follow-up.

cd "$(git rev-parse --show-toplevel 2>/dev/null)" || exit 0

# All modified implementation files (exclude tests, mocks, generated).
MODIFIED=$(git diff --name-only 2>/dev/null \
  | grep -E '\.(cs|ts|tsx)$' \
  | grep -vE '\.(test|spec|e2e)\.(ts|tsx)$' \
  | grep -vE 'Tests?/.*\.cs$' \
  | grep -v '__tests__' \
  | grep -v '__mocks__' \
  | grep -v 'src/generated/')

[ -z "$MODIFIED" ] && exit 0
[ -f CLAUDE.md ] || exit 0

# Extract enabled stacks with root: and test_cmd: from the fenced manifest block.
# Output: "<name>\t<root>\t<test_cmd>" per line.
STACKS=$(awk '
  /^```yaml[[:space:]]*$/ { in_fence=1; next }
  in_fence && /^```[[:space:]]*$/ { in_fence=0; next }
  in_fence && /enabled:[[:space:]]*true/ {
    line=$0
    name=""; root=""; cmd=""
    if (match(line, /^[[:space:]]+[a-zA-Z0-9_-]+:/)) {
      name=substr(line, RSTART, RLENGTH); sub(/^[[:space:]]+/, "", name); sub(/:$/, "", name)
    }
    if (match(line, /root:[[:space:]]*[^,}]+/)) {
      root=substr(line, RSTART, RLENGTH); sub(/root:[[:space:]]*/, "", root)
      sub(/[[:space:]]+$/, "", root); sub(/\/$/, "", root)
    }
    if (match(line, /test_cmd:[[:space:]]*"[^"]*"/)) {
      cmd=substr(line, RSTART, RLENGTH); sub(/test_cmd:[[:space:]]*"/, "", cmd); sub(/"$/, "", cmd)
    }
    if (name != "" && root != "") print name "\t" root "\t" cmd
  }
' CLAUDE.md)

[ -z "$STACKS" ] && exit 0

# Find which enabled stacks have modified files under their root.
HIT_NAMES=""
HIT_LINES=""
while IFS=$'\t' read -r NAME ROOT CMD; do
  [ -z "$ROOT" ] && continue
  if echo "$MODIFIED" | grep -q "^$ROOT/"; then
    HIT_NAMES="$HIT_NAMES $ROOT($NAME)"
    if [ -n "$CMD" ]; then
      HIT_LINES="${HIT_LINES}      $ROOT/  $CMD\n"
    fi
  fi
done <<< "$STACKS"

if [ -n "$HIT_NAMES" ]; then
  echo "Tip: Implementation files were modified. Consider running tests for:$HIT_NAMES"
  [ -n "$HIT_LINES" ] && printf "$HIT_LINES"
fi

exit 0
