# dev-team contract

Human-only reference. **The single source of truth for what `dev-toolbox`
assumes about the external [`dev-team`](https://github.com/bdfinst/agentic-dev-team)
plugin.** Every version-specific fact about dev-team lives here and nowhere else —
other files point at this one instead of restating it. When a dev-team upgrade
changes the shape of what we depend on, this is the only file to edit.

Sibling references: `delegation-map.md` (which plugin entry handles each intent),
`../CLAUDE.md` (runtime contract for consumers).

## Target version

**`dev-team >= v10.13.0`** — the release that settled the orchestrator into an
agent (see below).

Claude Code plugins have **no dependency-enforcement mechanism**: dev-team is a
separately-installed plugin, and nothing at install time checks its version
against this target. The pin is therefore **documentary** — a maintainer
anchor for "is our assumption still true?", enforced by the upgrade checklist
below, not by tooling.

## The functional contract we rely on

These are the only *hard* seams — the places where dev-toolbox invokes dev-team
by name. Everything else is a soft pointer (see "Everything else").

### Orchestrator (the entry point)

- Substantive engineering work delegates to the **`dev-team:orchestrator`
  agent**, invoked via the Agent tool with `subagent_type: dev-team:orchestrator`.
- It is an **agent, not a slash command** — there is no `/dev-team:orchestrator`.
- The local `/orchestrator` command is a thin alias that delegates to it. The
  substantive-vs-trivial threshold lives in the `generic-orchestrator-routing`
  skill.

### Workflow skills we wire to by name

The orchestrator coordinates these as slash commands; dev-toolbox references
them directly (e.g. from `generic-gate-pipeline`):

- `/dev-team:plan`
- `/dev-team:build`
- `/dev-team:pr`
- `/dev-team:code-review`
- `/dev-team:specs`
- `/dev-team:feature-file-validation`

### Everything else

dev-team ships ~90 skills and ~40 agents. **Do not restate the catalogue** —
it drifts. `/dev-team:help` (or the plugin's `knowledge/skills-registry.md`) is
authoritative. If an intent isn't in the wired list above, assume the plugin
covers it and route there rather than hand-rolling a local equivalent.

## Upgrade checklist

When bumping the target version above:

1. Re-verify the orchestrator invocation shape (still an agent? still that
   `subagent_type`?).
2. Re-verify the wired workflow-skill names still exist and are still
   slash commands.
3. Update the target version and any changed facts **in this file only** — the
   seams elsewhere point here, so they don't need touching.
4. Note the bump in `CHANGELOG.md`.
