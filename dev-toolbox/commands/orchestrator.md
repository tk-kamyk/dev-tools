---
name: orchestrator
description: >-
  Project-local alias to the dev-team orchestrator. Required because CLAUDE.md
  names the plugin orchestrator as the entry point for all substantive work, and we
  want typed `/orchestrator` to route deterministically instead of being interpreted
  by the model as freeform text.
argument-hint: "<request>"
user-invocable: true
---

Delegate immediately to the `dev-team:orchestrator` **agent** via the Agent (Task) tool, passing the arguments below as its task. Do not search the repo, do not answer inline, do not spawn any other agent first — the plugin orchestrator is the authoritative entry point per CLAUDE.md.

> Note: the orchestrator is an **agent**, not a slash command — invoke it as a subagent (`subagent_type: dev-team:orchestrator`). The workflow *skills* it coordinates remain slash commands. For the full contract (target version, invocation shape, wired skill names) see [`rules/dev-team-contract.md`](../rules/dev-team-contract.md).

Arguments: $ARGUMENTS
