# Changelog

All notable changes to `dev-toolbox` (the plugin shipped from this folder).

The format roughly follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/).
Versioning follows [SemVer](https://semver.org/spec/v2.0.0.html).

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
