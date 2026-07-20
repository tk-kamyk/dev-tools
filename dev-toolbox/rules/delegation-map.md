# Delegation map

Human-only reference. Names which `dev-team` plugin entry handles the intents
this toolbox actually wires to. Read this when extending the toolbox or
wondering "is there already a plugin entry for this before I write a local one?"

For the version target and invocation shape of these entries, see the sibling
[`dev-team-contract.md`](./dev-team-contract.md).

## Entries we wire to by name

These are the only dev-team entries dev-toolbox references directly (from its
commands, routing, and the gate pipeline). Everything else is deliberately not
restated here — see below.

| Intent | Plugin entry |
|---|---|
| Start a feature (route + multi-phase) | `dev-team:orchestrator` **agent** (via Agent tool — not a slash command) |
| Draft an implementation plan | `/dev-team:plan` |
| Execute an approved plan with TDD | `/dev-team:build` |
| Finalise + merge a feature branch | `/dev-team:pr` |
| Full review of changed files | `/dev-team:code-review --changed` |
| Produce the four spec artifacts | `/dev-team:specs` |
| Validate Gherkin feature files | `/dev-team:feature-file-validation` |

## Everything else: assume the plugin covers it

dev-team ships ~90 skills and ~40 agents; the table above is only the slice this
toolbox invokes directly. **Do not maintain a fuller mirror here — it drifts.**
If an intent isn't listed above (domain modelling, threat modelling, Docker,
triage, CI debugging, mutation testing, …), assume the plugin already covers it:
check `/dev-team:help` or the plugin's `knowledge/skills-registry.md`, and route
there rather than reinventing a local equivalent.

## What local skills add

Plugin agents don't know your project. Project-local skills (under
`.claude/skills/`) carry the project-specific details: domain glossary, vendor-*
skills for third-party integrations, project-specific naming. When a plugin
agent runs, it loads the matching plugin-shipped + project-local skills via
stack-tag filtering — see the stack manifest in your project's `CLAUDE.md`.

## When to write a local entry vs use the plugin

- **Use the plugin** if it already covers the intent. Don't wrap it.
- **Write a local skill** if you have project-specific knowledge that should load
  when working in a particular area (file paths, frontmatter triggers, stack-tag
  intersect).
- **Write a local slash command** if you want a verb that delegates with project
  context pre-loaded (e.g. `/check` runs the per-stack matrix from the manifest).
- **Don't write a local agent** unless there's a real persona gap the plugin
  doesn't fill. Wrappers drift on plugin upgrades.
