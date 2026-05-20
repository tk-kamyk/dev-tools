#!/bin/bash
# Block direct process.env usage in Next.js frontend files.
# Enforces: import { env } from '@/lib/env'
# Triggers for files under the `nextjs` stack root declared in CLAUDE.md.

INPUT=$(cat)

FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path // empty')
TOOL_NAME=$(echo "$INPUT" | jq -r '.tool_name // empty')
[ -z "$FILE_PATH" ] && exit 0

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

# Only check files under the nextjs stack root.
[[ "$FILE_PATH" != *"/$NEXTJS_ROOT/"* ]] && exit 0

# Allow the env validation layer itself
[[ "$FILE_PATH" == *"lib/env.ts"* ]] && exit 0
[[ "$FILE_PATH" == *"lib/env/"* ]] && exit 0

# Allow config files that legitimately need process.env
[[ "$FILE_PATH" == *".env"* ]] && exit 0
[[ "$FILE_PATH" == *"next.config"* ]] && exit 0
[[ "$FILE_PATH" == *"sentry."*".config"* ]] && exit 0
[[ "$FILE_PATH" == *"instrumentation"* ]] && exit 0

# Allow documentation files (may contain code examples)
[[ "$FILE_PATH" == *.md ]] && exit 0

# Extract content to check based on tool
if [[ "$TOOL_NAME" == "Write" ]]; then
  CONTENT=$(echo "$INPUT" | jq -r '.tool_input.content // empty')
elif [[ "$TOOL_NAME" == "Edit" ]]; then
  CONTENT=$(echo "$INPUT" | jq -r '.tool_input.new_string // empty')
else
  exit 0
fi

if echo "$CONTENT" | grep -q 'process\.env\.'; then
  echo "BLOCKED: Direct process.env access in $FILE_PATH" >&2
  echo "Use: import { env } from '@/lib/env'" >&2
  echo "See the nextjs-frontend-standards / nextjs-env-var skills for the source-mapped pattern." >&2
  exit 2
fi

exit 0
