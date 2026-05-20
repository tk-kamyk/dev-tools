# dev-tools

Personal developer tools — a Claude Code plugin (`dev-toolbox`).

## What's in the box

This repo bundles two independent assets.

**`dev-toolbox/`** is a [Claude Code](https://docs.claude.com/claude-code)
plugin. The repo doubles as a local Claude Code marketplace (`tk-kamyk`) that
ships it. The plugin is knowledge-only — skills, hooks, slash commands. It
defines no agent personas; substantive engineering work delegates to
[`agentic-dev-team`](https://github.com/bdfinst/agentic-dev-team) via
`/agentic-dev-team:orchestrator` (a bare `/orchestrator` is a local alias to
the same). Stack-manifest-driven: each consuming project declares which
stacks are enabled (`.NET`, `Next.js`, `Expo`, `Turborepo`, `Azure`, …) and
the plugin filters skills and hooks accordingly. See
[`dev-toolbox/README.md`](./dev-toolbox/README.md) for the full surface.

## Quick start (`dev-toolbox`)

Two commands, both run **inside Claude Code**:

```
/plugin marketplace add https://github.com/tk-kamyk/dev-tools
/plugin install dev-toolbox@tk-kamyk
```

Verify with `/toolbox` — it prints the live inventory of commands, skills,
and hooks.

## Repo layout

```
dev-tools/
├── .claude-plugin/
│   └── marketplace.json     # marketplace manifest (name: tk-kamyk)
├── README.md                 # you are here
├── LICENSE                   # MIT
├── CLAUDE.md                 # maintainer guide for this repo
├── CHANGELOG.md              # plugin version history
├── dev-toolbox/              # the Claude Code plugin
│   ├── .claude-plugin/plugin.json
│   ├── CLAUDE.md             # loaded into context when the plugin is active
│   ├── README.md             # plugin docs
│   ├── settings.json         # hook wiring
│   ├── commands/             # /toolbox, /check, /learn, /orchestrator, …
│   ├── skills/               # generic-* + framework knowledge (dotnet, nextjs, expo, …)
│   ├── hooks/                # guard-* + session pulse + stop reminder
│   ├── rules/                # delegation-map
│   ├── scripts/              # detect-stacks, validate-manifest
│   ├── templates/            # (reserved)
│   └── prompts/              # (reserved)
```

---

## Installing `dev-toolbox`

The plugin ships from this repo's local marketplace at the root. Installation
is a two-step Claude Code flow: add the marketplace, then install the plugin.

### Prerequisites

- Claude Code (CLI, IDE extension, or desktop app) recent enough to support
  plugins. If `/plugin` doesn't autocomplete, your build is too old —
  upgrade first.
- The consuming project must have a `CLAUDE.md` with a `# stack-manifest`
  fenced YAML block (see [`dev-toolbox/CLAUDE.md`](./dev-toolbox/CLAUDE.md)
  for the schema). The plugin is harmless without one, but the stack-aware
  hooks and `/check` only do useful work when the manifest is present.

> All steps run **inside Claude Code**, not in your shell.

### 1. Add the marketplace

From the public repo:

```
/plugin marketplace add https://github.com/tk-kamyk/dev-tools
```

Or from a local checkout during development:

```
/plugin marketplace add /absolute/path/to/dev-tools
```

This registers the marketplace under the name `tk-kamyk`. Verify with:

```
/plugin marketplace list
```

### 2. Install the plugin

```
/plugin install dev-toolbox@tk-kamyk
```

Project scope by default. Pick user scope explicitly to enable it everywhere:

```
/plugin install dev-toolbox@tk-kamyk --scope user
```

### 3. Restart / reload

Some hooks only register on session start. Restart Claude Code, or run
`/plugin reload` if your build supports it.

### 4. Verify

In a project where the stack manifest is configured:

```
/plugin list      # dev-toolbox@tk-kamyk should appear as enabled
/toolbox          # live inventory of commands, skills, hooks
/check            # per-stack test/lint matrix from your manifest
```

Trigger any guard hook to confirm wiring — e.g. write a file under a Next.js
App Router with a non-route folder name and watch for the underscore-prefix
block. (Only fires if your project has `nextjs` enabled in the manifest.)

## Updating

```
/plugin marketplace update tk-kamyk
```

When a new version is published, this command pulls it. See
[CHANGELOG.md](./CHANGELOG.md) for what shipped.

## Uninstalling

```
/plugin uninstall dev-toolbox@tk-kamyk
/plugin marketplace remove tk-kamyk   # optional
```

## Coexistence with a project's existing `.claude/`

If the consuming project already wires the same hooks via
`.claude/settings.json` (e.g. it was using an earlier copy-paste version of
this toolbox), be aware of overlap:

- **Hooks:** the plugin uses `${CLAUDE_PLUGIN_ROOT}/hooks/…`; `.claude/settings.json`
  uses local paths. **If both are wired**, hooks will fire twice. To run only
  one, comment out the hook entries in either `.claude/settings.json` or
  `dev-toolbox/settings.json`.
- **Skills:** skills with the same `name:` collide. Claude Code's behaviour
  on collision is undefined — keep one canonical copy.
- **Commands:** command names of identical slug collide the same way. The
  plugin intentionally **drops** `sync-toolbox`, `create-pr`, and
  `work-status` so they only exist in `.claude/` if a project wants them.

Once the plugin path is the canonical one for your project, slim down
`.claude/` accordingly.

## Troubleshooting

| Symptom | Likely cause |
|---|---|
| `/plugin marketplace add` fails with "not a marketplace" | Wrong path; aim at the repo root, not `dev-toolbox/` |
| `/plugin install` says "no plugin named …" | Marketplace not added, or `marketplace.json` couldn't be parsed |
| Hooks fire twice for the same event | Both `.claude/settings.json` and the plugin are wiring the hook — pick one |
| Hooks don't fire at all | Restart Claude Code; verify `/plugin list` shows the plugin as enabled |
| `/check` reports "no enabled stacks" | The project's `CLAUDE.md` has no `# stack-manifest` block, or it's wrapped in the wrong fence syntax |
| `session-start-pulse.sh` prints nothing under "Stacks" | The manifest is missing `root:` values for stacks (the hook uses `root:` to detect presence) |

---

## Development

Working on the plugin itself? See [CLAUDE.md](./CLAUDE.md) for the
maintainer guide, [dev-toolbox/README.md](./dev-toolbox/README.md) for the
plugin's public surface, and [dev-toolbox/CLAUDE.md](./dev-toolbox/CLAUDE.md)
for the runtime contract that loads in consuming projects.

## License

MIT — see [LICENSE](./LICENSE).
