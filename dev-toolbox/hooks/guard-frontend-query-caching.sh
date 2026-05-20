#!/bin/bash
# Block per-query staleTime/gcTime/cacheTime overrides in the Next.js frontend.
# Backend handles caching; global defaults live in react-query-provider.tsx.
# Triggers for files under the `nextjs` stack root declared in CLAUDE.md.

INPUT=$(cat)

FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path // empty')
TOOL=$(echo "$INPUT" | jq -r '.tool_name // empty')
[ -z "$FILE_PATH" ] && exit 0
[[ "$FILE_PATH" != *.ts && "$FILE_PATH" != *.tsx ]] && exit 0

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

# Exempt the global config file
[[ "$FILE_PATH" == *"react-query-provider.tsx" ]] && exit 0

# Pull added content based on tool
if [[ "$TOOL" == "Write" ]]; then
  CONTENT=$(echo "$INPUT" | jq -r '.tool_input.content // empty')
elif [[ "$TOOL" == "Edit" ]]; then
  CONTENT=$(echo "$INPUT" | jq -r '.tool_input.new_string // empty')
else
  exit 0
fi

# Match `staleTime:`, `gcTime:`, `cacheTime:` as object keys
if echo "$CONTENT" | grep -qE '\b(staleTime|gcTime|cacheTime)\s*:'; then
  echo "BLOCKED: Do not set staleTime/gcTime/cacheTime on individual queries." >&2
  echo "Backend handles response caching; frontend should refetch on mount." >&2
  echo "Global defaults live in react-query-provider.tsx. Only refetchInterval is OK per-query." >&2
  exit 2
fi

exit 0
