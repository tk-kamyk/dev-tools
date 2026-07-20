#!/bin/bash
# Validate Azure DevOps PR title and description format on create/update.
# Title:  type(topic): Description — conventional commits with kebab-case topic, sentence case, no trailing period, <= 72 chars.
# Body:   no literal '\n' escape sequences (use real newlines).

INPUT=$(cat)

TOOL=$(echo "$INPUT" | jq -r '.tool_name // empty')
case "$TOOL" in
  mcp__azure-devops__repo_create_pull_request|mcp__azure-devops__repo_update_pull_request|mcp__github__create_pull_request) ;;
  *) exit 0 ;;
esac

TITLE=$(echo "$INPUT" | jq -r '.tool_input.title // empty')
# Azure DevOps uses `description`; GitHub uses `body`.
DESCRIPTION=$(echo "$INPUT" | jq -r '.tool_input.description // .tool_input.body // empty')

if [[ -n "$TITLE" ]]; then
  if ! [[ "$TITLE" =~ ^(feat|fix|chore|refactor|docs|test)\([a-z][a-z0-9-]*\):\ [A-Z] ]]; then
    echo "BLOCKED: PR title must follow 'type(topic): Description' format." >&2
    echo "  type:        feat | fix | chore | refactor | docs | test" >&2
    echo "  topic:       kebab-case feature area (e.g. 'expense-allocations')" >&2
    echo "  description: sentence-case (starts with capital), no trailing period" >&2
    echo "Got: $TITLE" >&2
    exit 2
  fi

  if (( ${#TITLE} > 72 )); then
    echo "BLOCKED: PR title is ${#TITLE} chars; must be <= 72." >&2
    exit 2
  fi

  if [[ "$TITLE" == *. ]]; then
    echo "BLOCKED: PR title must not end with a period." >&2
    exit 2
  fi
fi

if [[ -n "$DESCRIPTION" && "$DESCRIPTION" == *'\n'* ]]; then
  echo "BLOCKED: PR description contains literal '\\n' escape sequences." >&2
  echo "Use real newlines (multi-line strings), not '\\n'." >&2
  exit 2
fi

exit 0
