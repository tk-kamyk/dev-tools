---
name: create-pr
description: Create a pull request for the current branch. Auto-detects GitHub vs Azure DevOps from the git remote and uses the matching MCP server (gh CLI fallback for GitHub). Prefer MCP over CLI.
argument-hint: "[target-branch]"
user-invocable: true
---

Create a pull request for the current branch. Detect the git host from the
remote, then drive the matching MCP server. Self-contained — this command does
NOT route through the orchestrator.

`$ARGUMENTS`, if present, is the target branch to merge into (default `main`).

## Steps

1. **Detect the host** from the remote:
   ```bash
   git remote get-url origin 2>/dev/null || git remote get-url "$(git rev-parse --abbrev-ref --symbolic-full-name @{u} 2>/dev/null | cut -d/ -f1)"
   ```
   Classify the URL:
   - contains `github.com` → **GitHub**
   - contains `dev.azure.com` or `.visualstudio.com` → **Azure DevOps**
   - neither → print the detected URL, explain that only GitHub and Azure DevOps
     are supported, and stop.

   Parse the coordinates (handle both https and ssh forms):
   - **GitHub** → `owner`, `repo` from
     `github.com/{owner}/{repo}(.git)` or `git@github.com:{owner}/{repo}.git`.
   - **Azure DevOps** → `org`, `project`, `repo` from
     `dev.azure.com/{org}/{project}/_git/{repo}`,
     `git@ssh.dev.azure.com:v3/{org}/{project}/{repo}`, or the legacy
     `{org}.visualstudio.com/{project}/_git/{repo}`.

2. **Verify branch state**
   - Current branch: `git rev-parse --abbrev-ref HEAD` (must not be the target).
   - `git log <target>..HEAD --oneline` — commits to ship.
   - `git diff <target>...HEAD --stat` — file stats.
   - Confirm the branch is pushed and up to date with its upstream
     (`git status -sb`). If it isn't pushed, push it first (ask if unsure).

3. **Detect the work item / issue**
   - From the branch name (`feat/76106-my-feature` → `76106`) or commit messages
     (`#12345`, `AB#12345`).
   - **Azure** → verify with `mcp__azure-devops__wit_get_work_item`.
   - **GitHub** → treat `#123` as an issue to close; add `Closes #123` to the body.
   - If none is found, ask the user (they may not have one).

4. **Build the description from a template** — read the first that exists:
   - **Azure**: `.azuredevops/pull_request_templates/*.md` (prefer
     `claude-code.md` if present), else `.azuredevops/pull_request_template.md`.
   - **GitHub**: `.github/pull_request_template.md`,
     `.github/PULL_REQUEST_TEMPLATE.md`, `.github/PULL_REQUEST_TEMPLATE/*.md`,
     or `docs/PULL_REQUEST_TEMPLATE.md`.

   If no template exists, use a minimal built-in shape: one-line summary, a
   bulleted list of changes, and the work-item/issue reference at the bottom.
   Include file references with line numbers where relevant. Use **real
   newlines**, never literal `\n`. For Azure, keep the description under **4000
   characters** (ADO limit).

5. **Title** — `type(topic): Description`
   - `type` — `feat` | `fix` | `chore` | `refactor` | `docs` | `test`.
   - `topic` — kebab-case feature area.
   - `Description` — sentence case (starts with a capital), no trailing period.
   - At most 72 characters.

   This contract is enforced by the `guard-pr-format.sh` PreToolUse hook for
   both the Azure and GitHub PR-create MCP tools — a non-conforming title is
   blocked with `exit 2`. Don't try to bypass it; fix the title.

6. **Create the PR**
   - **Azure DevOps** → `mcp__azure-devops__repo_create_pull_request` with:
     - `repository`: the parsed repo
     - `project`: the parsed project
     - `sourceRefName`: `refs/heads/<current-branch>`
     - `targetRefName`: `refs/heads/<target>`
     - `title`, `description`

     If a work item was found, link it after creation with
     `mcp__azure-devops__wit_link_work_item_to_pull_request`. Note: work items
     may live in a **different project** than the repo (cross-project linking) —
     don't assume a layout; ask the user for the work item's project if the
     link fails.
   - **GitHub** → prefer `mcp__github__create_pull_request` with:
     - `owner`, `repo`
     - `title`, `body`
     - `head`: current branch
     - `base`: target branch

     If the GitHub MCP tools aren't configured/available, fall back to:
     ```bash
     gh pr create --base <target> --head <current-branch> --title "<title>" --body "<body>"
     ```

7. **Report**
   - PR URL + ID.
   - Work-item / issue link status.
   - Ask before changing any work item's state.

## Notes

- Prefer MCP tools over CLI for all operations; `gh` is only the GitHub fallback.
- Run `/check` before opening a PR.
- This command is a verb/utility — it does not spawn agents or route through the
  orchestrator.
- The Azure DevOps path requires the `azure-devops` MCP server (and
  `ADO_MCP_ORG` set); the GitHub path requires the `github` MCP server or the
  `gh` CLI. See the plugin README's MCP prerequisites.
