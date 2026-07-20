# Delegation map

Human-only reference. Names which `dev-team` plugin agent, skill, or command handles each kind of intent. Read this when extending the toolbox or wondering "is there already a plugin entry for this before I write a local one?"

## Phase work

| Intent | Plugin entry |
|---|---|
| Start a feature (route + multi-phase) | `dev-team:orchestrator` **agent** (via Agent tool — not a slash command) |
| Draft an implementation plan | `/dev-team:plan` |
| Execute an approved plan with TDD | `/dev-team:build` |
| Produce the four spec artifacts | `/dev-team:specs` |
| Write a design doc before planning | `/dev-team:design-doc` |
| Finalise + merge a feature branch | `/dev-team:branch-workflow` |
| Resume in-progress work | `/dev-team:continue` |
| Triage a bug into an issue | `/dev-team:triage` |
| Root-cause investigation | `/dev-team:systematic-debugging` |
| CI failure diagnosis | `/dev-team:ci-debugging` |

## Reviews

| Intent | Plugin entry |
|---|---|
| Full review of changed files | `/dev-team:code-review --changed` |
| Single review agent (e.g. security) | `/dev-team:review-agent <name>` |
| Static analysis pre-pass | `/dev-team:semgrep-analyze` |
| Mutation testing | `/dev-team:mutation-testing` |
| Apply correction prompts | `/dev-team:apply-fixes` |

## Design

| Intent | Plugin entry |
|---|---|
| Strategic DDD (bounded contexts) | `/dev-team:domain-driven-design` |
| Domain health assessment | `/dev-team:domain-analysis` |
| Hexagonal architecture | `/dev-team:hexagonal-architecture` |
| Contract-first API design | `/dev-team:api-design` |
| Threat modeling (STRIDE) | `/dev-team:threat-modeling` |
| Stress-test a plan | `/dev-team:design-interrogation` |

## Infra

| Intent | Plugin entry |
|---|---|
| Generate a Dockerfile | `/dev-team:docker-image-create` |
| Audit a Docker image | `/dev-team:docker-image-audit` |
| Bootstrap a project / install toolchain | `/dev-team:project-init` (and `/dev-team:setup` for repo config) |
| Upgrade plugins | `/dev-team:upgrade` |

## What local skills add

Plugin agents don't know your project. Project-local skills (under `.claude/skills/`) carry the project-specific details: domain glossary, vendor-* skills for third-party integrations, project-specific naming. When a plugin agent runs, it loads the matching plugin-shipped + project-local skills via stack-tag filtering — see the stack manifest in your project's `CLAUDE.md`.

## When to write a local entry vs use the plugin

> **This map is a curated shortlist, not the full catalogue.** dev-team v10 ships
> ~90 skills and ~40 agents; the tables above only sample the common ones. If an
> intent isn't listed here, **assume the plugin covers it** — check `/dev-team:help`
> or the plugin's `knowledge/skills-registry.md` first, and route to the plugin
> rather than reinventing a local equivalent.

- **Use the plugin** if it already covers the intent. Don't wrap it.
- **Write a local skill** if you have project-specific knowledge that should load when working in a particular area (file paths, frontmatter triggers, stack-tag intersect).
- **Write a local slash command** if you want a verb that delegates with project context pre-loaded (e.g. `/check` runs the per-stack matrix from the manifest).
- **Don't write a local agent** unless there's a real persona gap the plugin doesn't fill. Wrappers drift on plugin upgrades.
