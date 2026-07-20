# Changelog

All notable changes to `dev-toolbox` (the plugin shipped from this folder).

The format roughly follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/).
Versioning follows [SemVer](https://semver.org/spec/v2.0.0.html).

## [0.2.0] — 2026-07-17

### Added

- `/create-pr` slash command — creates a pull request for the current branch,
  auto-detecting GitHub vs Azure DevOps from the git remote and driving the
  matching MCP server (falls back to the `gh` CLI for GitHub). Generic: parses
  org/project/repo from the remote, never hardcodes them.
- Bundled `dev-toolbox/.mcp.json` registering a `github` (hosted HTTP) and an
  `azure-devops` (`npx @azure-devops/mcp ${ADO_MCP_ORG}`) MCP server, so
  installing the plugin wires them up.

### Changed

- `guard-pr-format.sh` now also fires on `mcp__github__create_pull_request`
  (reads GitHub's `body` field alongside Azure's `description`), so the
  `type(topic): Description` title contract applies to GitHub PRs too.
  `settings.json` matcher extended to match the GitHub PR-create tool.
- `create-pr` is no longer "intentionally dropped" from the plugin — it ships
  as a generic command. Docs (`README.md`, `dev-toolbox/README.md`,
  `dev-toolbox/CLAUDE.md`) updated with MCP prerequisites and coexistence notes.
- **Migrated all references from the `agentic-dev-team` namespace to `dev-team`**
  to match upstream, which renamed the plugin (`agentic-dev-team` →
  `dev-team`, marketplace `bfinster`). Every `/agentic-dev-team:*` command,
  skill reference, alias, and the plugin-cache path (`cache/bfinster/dev-team/`)
  now uses `dev-team`. The GitHub repo URL is unchanged (the repo is still
  `bdfinst/agentic-dev-team`).
- Documented the `dev-team` plugin as a **required prerequisite** in the repo
  README, with install commands (`/plugin marketplace add
  bdfinst/agentic-dev-team`; `/plugin install dev-team@bfinster`).
- Verified every `dev-team:*` reference against the installed plugin
  (v10.13.0) and corrected the drift: the orchestrator is now an **agent**
  (invoked via the Agent tool), not a `/dev-team:orchestrator` slash command —
  the `/orchestrator` alias, `generic-orchestrator-routing`, and the docs now
  delegate to the `dev-team:orchestrator` agent. Renamed `js-project-init` →
  `project-init`; dropped `root-why` (folded into `systematic-debugging`),
  `add-plugin`, `finalize`, and `agent-skill-authoring` (no longer shipped —
  authoring validation now points to `/dev-team:agent-audit`).

## [0.1.0] — 2026-05-20

Initial extraction from the project-local `.claude/` toolbox.

### Added

- Local marketplace at `plugin/.claude-plugin/marketplace.json` (name: `tk-kamyk`).
- Plugin manifest at `plugin/dev-toolbox/.claude-plugin/plugin.json`.
- Plugin `CLAUDE.md` and `README.md`.
- Plugin `settings.json` wiring hooks via `${CLAUDE_PLUGIN_ROOT}`.
- 8 `generic-*` skills (gate-pipeline, orchestrator-routing, code-quality,
  docs-standards, spec-authoring, memory-policy, claudemd-authoring,
  feedback-capture).
- 6 `dotnet-*` skills (clean-architecture, api-design, vendor-adapters,
  coding-patterns, data-access, build-and-runtime), genericised
- 6 `nextjs-*` skills (frontend-standards, ui-implementation,
  vercel-react-best-practices, sentry, env-var, verify-chrome), genericised.
- 8 `expo-*` skills (verbatim — already generic).
- 1 `turborepo-*` skill (verbatim).
- 1 `azure-*` skill (devops-pr-format, genericised examples).
- 8 hooks (session-start-pulse, stop-test-reminder, guard-stack-manifest,
  guard-pr-format, guard-private-folders + bash variant, guard-process-env,
  guard-frontend-query-caching). Frontend guards now read the `nextjs` stack
  root from the project's CLAUDE.md instead of hardcoding `spa/apps/frontend/`.
- 7 slash commands (orchestrator, toolbox, check, affected, generate-api,
  env-status, learn).
- `rules/delegation-map.md` rule (generic).
- 2 helper scripts (detect-stacks, validate-manifest).

### Notes

- See `INSTALL.md` for install steps.
