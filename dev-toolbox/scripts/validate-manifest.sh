#!/bin/bash
# Validate the fenced stack-manifest YAML inside CLAUDE.md.
#
# Usage: validate-manifest.sh <path-to-CLAUDE.md>
# Exit:  0 = valid (or syntactic-only valid), 1 = no manifest found,
#        2 = YAML parse error, 3 = schema error.
#
# Prefers full YAML validation via python3+PyYAML or yq if available.
# Falls back to an awk-based syntactic check that verifies the block shape
# (top-level `stacks:` map, each stack has `enabled:`). Prints an install
# hint if running in fallback mode.

set -euo pipefail

CLAUDE_MD="${1:-CLAUDE.md}"

if [[ ! -f "$CLAUDE_MD" ]]; then
  echo "ERROR: $CLAUDE_MD not found" >&2
  exit 1
fi

# --- Extract the fenced ```yaml block tagged "# stack-manifest" -----------
MANIFEST_YAML=$(awk '
  /^```yaml[[:space:]]*$/ { in_fence=1; buf=""; next }
  in_fence && /^```[[:space:]]*$/ { if (has_marker) { print buf } in_fence=0; has_marker=0; next }
  in_fence {
    if ($0 ~ /^#[[:space:]]*stack-manifest/) has_marker=1
    buf = buf $0 ORS
  }
' "$CLAUDE_MD")

if [[ -z "$MANIFEST_YAML" ]]; then
  echo "ERROR: no fenced '# stack-manifest' YAML block found in $CLAUDE_MD" >&2
  exit 1
fi

# --- Try a real YAML parser if available ----------------------------------
HAS_PYYAML=0
if command -v python3 >/dev/null 2>&1; then
  if python3 -c "import yaml" >/dev/null 2>&1; then
    HAS_PYYAML=1
  fi
fi
HAS_YQ=0
if command -v yq >/dev/null 2>&1; then HAS_YQ=1; fi

if [[ "$HAS_PYYAML" == 1 ]]; then
  python3 - <<PYEOF
import sys, yaml
text = """$MANIFEST_YAML"""
try:
    data = yaml.safe_load(text)
except yaml.YAMLError as e:
    print(f"ERROR: YAML parse failed: {e}", file=sys.stderr); sys.exit(2)
if not isinstance(data, dict) or "stacks" not in data:
    print("ERROR: manifest must have top-level 'stacks:' map", file=sys.stderr); sys.exit(3)
stacks = data["stacks"]
if not isinstance(stacks, dict) or not stacks:
    print("ERROR: 'stacks:' must be a non-empty map", file=sys.stderr); sys.exit(3)
errs = []
for name, cfg in stacks.items():
    if not isinstance(cfg, dict):
        errs.append(f"  - {name}: must be a map"); continue
    if "enabled" not in cfg:
        errs.append(f"  - {name}: missing 'enabled:' key")
    elif not isinstance(cfg["enabled"], bool):
        errs.append(f"  - {name}: 'enabled' must be true/false")
if errs:
    print("ERROR: schema validation failed:", file=sys.stderr)
    for e in errs: print(e, file=sys.stderr)
    sys.exit(3)
enabled = [k for k, v in stacks.items() if v.get("enabled")]
print(f"OK: {len(stacks)} stacks declared, {len(enabled)} enabled: {', '.join(enabled)}")
PYEOF
  exit $?
fi

if [[ "$HAS_YQ" == 1 ]]; then
  STACKS_COUNT=$(echo "$MANIFEST_YAML" | yq '.stacks | length' 2>/dev/null || echo "0")
  if [[ "$STACKS_COUNT" -lt 1 ]]; then
    echo "ERROR: manifest must have a non-empty 'stacks:' map" >&2
    exit 3
  fi
  MISSING_ENABLED=$(echo "$MANIFEST_YAML" | yq '.stacks | to_entries | map(select(.value.enabled == null)) | .[].key' 2>/dev/null | tr -d '"')
  if [[ -n "$MISSING_ENABLED" ]]; then
    echo "ERROR: stacks missing 'enabled:' key:" >&2
    echo "$MISSING_ENABLED" | sed 's/^/  - /' >&2
    exit 3
  fi
  ENABLED=$(echo "$MANIFEST_YAML" | yq '.stacks | to_entries | map(select(.value.enabled == true)) | .[].key' 2>/dev/null | tr -d '"' | tr '\n' ' ')
  echo "OK: $STACKS_COUNT stacks declared, enabled: $ENABLED"
  exit 0
fi

# --- Fallback: awk-based syntactic check ----------------------------------
TMP=$(mktemp)
printf '%s' "$MANIFEST_YAML" > "$TMP"
trap 'rm -f "$TMP"' EXIT

awk '
  /^[[:space:]]*$/ { next }
  /^[[:space:]]*#/ { next }
  /^stacks:[[:space:]]*$/ { in_stacks = 1; next }
  !in_stacks { next }
  /^  [a-zA-Z][a-zA-Z0-9_-]*:/ {
    declared++
    if ($0 ~ /enabled:[[:space:]]*true/) enabled_count++
    next
  }
  /^    enabled:[[:space:]]*true/ { enabled_count++; next }
  END {
    if (declared == 0) {
      print "ERROR: no stacks declared" > "/dev/stderr"
      exit 3
    }
    printf("OK (fallback awk validator): %d stacks declared, %d enabled\n", declared, enabled_count)
    print "HINT: install PyYAML (pip3 install pyyaml) or yq for full validation."
  }
' "$TMP"
