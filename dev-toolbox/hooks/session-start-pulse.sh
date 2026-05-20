#!/bin/bash
# Project Pulse — session-start context driven by the CLAUDE.md stack manifest.
# Iterates enabled stacks (with a root: value) and prints a one-line heartbeat each.
#
# Works with or without PyYAML — falls back to awk-driven parsing of the
# fenced YAML block (inline-object form per stack).

cd "$(git rev-parse --show-toplevel 2>/dev/null)" || exit 0

echo "=== Project Pulse ==="
echo ""

BRANCH=$(git branch --show-current 2>/dev/null)
echo "Branch: $BRANCH"

git fetch origin main --quiet 2>/dev/null
AHEAD=$(git rev-list origin/main..HEAD --count 2>/dev/null)
BEHIND=$(git rev-list HEAD..origin/main --count 2>/dev/null)
echo "vs main: ${AHEAD:-0} ahead, ${BEHIND:-0} behind"

CHANGES=$(git status --porcelain 2>/dev/null | wc -l | tr -d ' ')
if [ "$CHANGES" -gt 0 ]; then
  echo "Uncommitted changes: $CHANGES files"
  git status --porcelain 2>/dev/null | head -10
else
  echo "Working tree: clean"
fi

echo ""
echo "Last commit:"
git log -1 --oneline 2>/dev/null

[ -f CLAUDE.md ] || exit 0

# Extract the fenced ```yaml block tagged "# stack-manifest".
MANIFEST_YAML=$(awk '
  /^```yaml[[:space:]]*$/ { in_fence=1; buf=""; next }
  in_fence && /^```[[:space:]]*$/ { if (has_marker) { print buf } in_fence=0; has_marker=0; next }
  in_fence {
    if ($0 ~ /^#[[:space:]]*stack-manifest/) has_marker=1
    buf = buf $0 ORS
  }
' CLAUDE.md)

[ -z "$MANIFEST_YAML" ] && exit 0

# Parse stack entries of the form:
#   <name>: { enabled: true, root: <path>, ... }
# Print "<root>\t<name>" for each enabled stack that has a root: value.
STACKS_OUT=$(awk '
  /enabled:[[:space:]]*true/ {
    line=$0
    # Extract name (leading "  <name>:")
    if (match(line, /^[[:space:]]+[a-zA-Z0-9_-]+:/)) {
      name=substr(line, RSTART, RLENGTH)
      sub(/^[[:space:]]+/, "", name)
      sub(/:$/, "", name)
    } else next
    # Extract root: value (up to next comma or closing brace)
    if (match(line, /root:[[:space:]]*[^,}]+/)) {
      root=substr(line, RSTART, RLENGTH)
      sub(/root:[[:space:]]*/, "", root)
      sub(/[[:space:]]+$/, "", root)
      sub(/\/$/, "", root)
      print root "\t" name
    }
  }
' <<< "$MANIFEST_YAML")

if [ -n "$STACKS_OUT" ]; then
  echo ""
  echo "Stacks:"
  while IFS=$'\t' read -r ROOT NAME; do
    [ -z "$ROOT" ] && continue
    [ -d "$ROOT" ] || continue
    case "$NAME" in
      dotnet)
        if command -v dotnet >/dev/null 2>&1; then
          DETAIL="dotnet $(dotnet --version 2>/dev/null)"
        else
          DETAIL="dotnet (not installed)"
        fi
        ;;
      nextjs)
        DETAIL="Next.js + Turborepo (pnpm)"
        ;;
      expo)
        SDK_VER=$(grep -oE '"expo"[[:space:]]*:[[:space:]]*"[^"]+"' "$ROOT/package.json" 2>/dev/null | head -1 | sed -E 's/.*"([^"]+)"$/\1/')
        DETAIL="Expo ${SDK_VER:-?}"
        ;;
      *)
        DETAIL="$NAME"
        ;;
    esac
    printf "  %-14s %s\n" "$ROOT/" "$DETAIL"
  done <<< "$STACKS_OUT"

  # Env staleness — for nextjs/expo, warn if <root>/.env (or apps/frontend/.env) is older than 24h.
  while IFS=$'\t' read -r ROOT NAME; do
    [ -z "$ROOT" ] && continue
    case "$NAME" in nextjs|expo) ;; *) continue ;; esac
    for ENV_FILE in "$ROOT/apps/frontend/.env" "$ROOT/.env"; do
      if [ -f "$ENV_FILE" ]; then
        ENV_MOD=$(stat -f %m "$ENV_FILE" 2>/dev/null || stat -c %Y "$ENV_FILE" 2>/dev/null || echo 0)
        NOW=$(date +%s)
        ENV_AGE=$(( (NOW - ENV_MOD) / 3600 ))
        if [ "$ENV_AGE" -gt 24 ]; then
          echo ""
          echo "WARNING: $ENV_FILE is ${ENV_AGE}h old. Consider: pnpm env:pull"
        fi
        break
      fi
    done
  done <<< "$STACKS_OUT"
fi
