# CLAUDE.md — maintainer guide for `dev-tools`

This file is loaded when working **on this repo** — editing skills, hooks,
or commands; bumping versions; cutting a release. It is the maintainer
view.

For the file Claude reads in **consuming projects** when the plugin is
enabled (stack-manifest schema, hook catalog, runtime contract), see
[`dev-toolbox/CLAUDE.md`](./dev-toolbox/CLAUDE.md). That file is
authoritative for runtime behaviour; this one is authoritative for repo
mechanics. Don't duplicate content between them.

## Repo orientation

```
dev-tools/
├── .claude-plugin/marketplace.json     # marketplace manifest (name: tk-kamyk)
├── README.md                            # public-facing entry point
├── LICENSE                              # MIT
├── CLAUDE.md                            # you are here (maintainer guide)
├── CHANGELOG.md                         # plugin version history
├── dev-toolbox/                         # the editable plugin surface
│   ├── .claude-plugin/plugin.json       # plugin manifest (version lives here too)
│   ├── CLAUDE.md                        # runtime contract — authoritative for consumers
│   ├── README.md                        # plugin docs
│   ├── settings.json                    # hook wiring via ${CLAUDE_PLUGIN_ROOT}
│   ├── commands/                        # /toolbox, /check, /learn, /orchestrator, …
│   ├── skills/                          # generic-* + framework knowledge
│   ├── hooks/                           # guard-* + session pulse + stop reminder
│   ├── rules/                           # delegation-map
│   └── scripts/                         # detect-stacks, validate-manifest
```

## Editing the plugin

- **Skills** are Markdown files with frontmatter. Filtering keys —
  `metadata.stack`, `metadata.required` — drive when each skill loads.
  Use existing skills (`dev-toolbox/skills/generic-*`,
  `dev-toolbox/skills/dotnet-*`, etc.) as the pattern; the catalogue in
  [`dev-toolbox/CLAUDE.md`](./dev-toolbox/CLAUDE.md) lists what's there
  and what each prefix means.
- **Hooks** are Bash scripts under `dev-toolbox/hooks/`. Every hook reads
  the consuming project's stack manifest and exits 0 silently when its
  target stack isn't enabled. Wiring lives in `dev-toolbox/settings.json`
  and uses `${CLAUDE_PLUGIN_ROOT}` for paths. Editing wiring needs a
  Claude Code restart to pick up.
- **Commands** are Markdown files with `argument-hint` / `description`
  frontmatter. The full catalogue is in
  [`dev-toolbox/CLAUDE.md`](./dev-toolbox/CLAUDE.md).

## Local testing

Install from a local path while iterating:

```
/plugin marketplace add /absolute/path/to/dev-tools
/plugin install dev-toolbox@tk-kamyk
```

After edits, refresh the marketplace:

```
/plugin marketplace update tk-kamyk
```

Restart Claude Code when changing `settings.json` (hook wiring is read on
session start).

## Versioning and release

The release contract is short.

1. Bump version in **both** files together:
   - `.claude-plugin/marketplace.json` → `plugins[0].version`
   - `dev-toolbox/.claude-plugin/plugin.json` → `version`
2. Add a [CHANGELOG.md](./CHANGELOG.md) entry under a new heading with
   today's date. Follow the Keep-a-Changelog conventions already in the
   file.
3. Commit with a [Conventional Commits](https://www.conventionalcommits.org/)
   prefix — `feat:`, `fix:`, `feat!:` for breaking changes.
4. Push to `main`. Consumers pull updates with
   `/plugin marketplace update tk-kamyk`.

SemVer applies — bump minor for additive skills/hooks, patch for fixes,
major for changes to the stack-manifest schema or removal of a
skill/hook.

## What lives where (and what doesn't)

- **In `dev-toolbox/` (the plugin):** generic + framework skills, guard
  hooks, marketplace mechanics, scripts, slash commands.
- **Not in this repo at all:** project glossaries, vendor adapters,
  project-specific Azure layout, agent personas. Agent personas come from
  [`dev-team`](https://github.com/bdfinst/agentic-dev-team).

## Routing to dev-team

This plugin (`dev-toolbox`) defines **no agents**. `/orchestrator` is a local
alias that delegates to the `dev-team:orchestrator` **agent** (invoked via the
Agent tool — in dev-team v10 the orchestrator is an agent, not a slash command);
substantive engineering work delegates there. The substantive-vs-trivial
threshold lives in the `generic-orchestrator-routing` skill.

If you find yourself reaching for an agent persona while editing this
repo, that's a signal to add it to `dev-team` instead — not
here.

## Don't break

- Don't rename `tk-kamyk` (the marketplace `name:` field in
  `marketplace.json`) without updating every install snippet in
  [README.md](./README.md). The slug is also referenced as
  `dev-toolbox@tk-kamyk` in install commands.
- Don't add a `.claude/settings.json` at the root of this repo. A local
  Claude Code session installing the plugin via local path would then
  double-wire the hooks (see the coexistence section in
  [README.md](./README.md)).
- Don't duplicate the stack-manifest schema or hook catalog here.
  [`dev-toolbox/CLAUDE.md`](./dev-toolbox/CLAUDE.md) is the single
  source of truth for runtime contracts; this file is the maintainer
  view only.
