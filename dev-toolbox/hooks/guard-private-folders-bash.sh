#!/bin/bash
# Enforce underscore prefix for non-route folders — Bash variant.
# Catches mkdir commands that create non-prefixed folders inside a Next.js app/ tree.

INPUT=$(cat)

COMMAND=$(echo "$INPUT" | jq -r '.tool_input.command // empty')
[ -z "$COMMAND" ] && exit 0
[[ "$COMMAND" != *"mkdir"* ]] && exit 0

REPO_ROOT="$(git rev-parse --show-toplevel 2>/dev/null)"
[ -z "$REPO_ROOT" ] && exit 0
[ -f "$REPO_ROOT/CLAUDE.md" ] || exit 0

NEXTJS_ROOT=$(awk '
  /^```yaml[[:space:]]*$/ { in_fence=1; next }
  in_fence && /^```[[:space:]]*$/ { in_fence=0; next }
  in_fence && /^[[:space:]]+nextjs:[[:space:]]*\{/ && /enabled:[[:space:]]*true/ {
    if (match($0, /root:[[:space:]]*[^,}]+/)) {
      root=substr($0, RSTART, RLENGTH)
      sub(/root:[[:space:]]*/, "", root)
      sub(/[[:space:]]+$/, "", root)
      sub(/\/$/, "", root)
      print root
      exit
    }
  }
' "$REPO_ROOT/CLAUDE.md")
[ -z "$NEXTJS_ROOT" ] && exit 0

# Only consider mkdirs that mention the nextjs root.
if [[ "$COMMAND" != *"$NEXTJS_ROOT/"* ]]; then
  exit 0
fi

# Non-route folder names that must use underscore prefix
NON_ROUTE="(components|hooks|utils|lib|services|helpers|types|constants|schemas|contexts|providers|actions|queries|mutations|styles|fixtures|mocks|test|tests)"

# Check if any non-route folder name appears as a path segment (not prefixed with _) under app/
if echo "$COMMAND" | grep -qE "app/[^\"']*/($NON_ROUTE)(/|$|\"|')"; then
  MATCH=$(echo "$COMMAND" | grep -oE "($NON_ROUTE)(/|$)" | head -1 | sed 's|/$||')
  echo "BLOCKED: mkdir would create non-route folder '$MATCH' inside app/ without underscore prefix." >&2
  echo "Use '_$MATCH' instead. Without the prefix, Next.js treats it as a route segment." >&2
  exit 2
fi

exit 0
