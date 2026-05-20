#!/bin/bash
# Enforce underscore prefix for non-route folders in Next.js App Router.
# Triggers for any Next.js app root reachable from the `nextjs` stack root
# declared in the CLAUDE.md manifest.

INPUT=$(cat)

FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path // empty')
[ -z "$FILE_PATH" ] && exit 0

# Need a nextjs stack in the manifest to know where Next apps live.
REPO_ROOT="$(git rev-parse --show-toplevel 2>/dev/null)"
[ -z "$REPO_ROOT" ] && exit 0
[ -f "$REPO_ROOT/CLAUDE.md" ] || exit 0

# Extract nextjs.root from the fenced ```yaml # stack-manifest block.
# Works with the inline-object form: nextjs: { enabled: true, root: <path>, ... }.
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

# Match either /<root>/app/... or /<root>/apps/<x>/app/... — the two common layouts.
if [[ "$FILE_PATH" == *"/$NEXTJS_ROOT/app/"* ]]; then
  APP_PATH="${FILE_PATH##*/$NEXTJS_ROOT/app/}"
elif [[ "$FILE_PATH" == *"/$NEXTJS_ROOT/apps/"*"/app/"* ]]; then
  APP_PATH="${FILE_PATH##*/app/}"
else
  exit 0
fi

# Non-route folder names that must use underscore prefix.
NON_ROUTE="^(components|hooks|utils|lib|services|helpers|types|constants|schemas|contexts|providers|actions|queries|mutations|styles|fixtures|mocks|test|tests)$"

IFS='/' read -ra SEGMENTS <<< "$APP_PATH"
for segment in "${SEGMENTS[@]}"; do
  # Skip filenames (contain a dot)
  [[ "$segment" == *.* ]] && continue

  if echo "$segment" | grep -qE "$NON_ROUTE"; then
    echo "BLOCKED: Folder '$segment' inside app/ must use underscore prefix: '_$segment'" >&2
    echo "Without the prefix, Next.js treats it as a route segment." >&2
    exit 2
  fi
done

exit 0
