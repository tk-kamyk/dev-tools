---
name: learn
description: Capture a deliberate correction, preference, or new convention. Classifies the input via the generic-feedback-capture routing table, previews the destination + diff, applies on approval, logs to metrics/config-changelog.jsonl.
argument-hint: "<thing-to-learn>"
user-invocable: true
---

Capture the feedback in `$ARGUMENTS` and route it to the right destination in the toolbox.

This command is for **deliberate** capture moments — "I want this written down somewhere durable." Passive corrections during chat are picked up automatically by `dev-team:feedback-learning`'s keyword detection without needing `/learn`.

## Steps

1. **Input.** Take `$ARGUMENTS` as the feedback. If empty, ask the user what they want captured.
2. **Classify.** Invoke the `generic-feedback-capture` skill against the input. It matches the feedback against the destination table (skill / rule / glossary / stack manifest / auto-memory / decisions.md / new-skill proposal) and picks one destination.
3. **Preview.** Show the proposed change as a diff: which file, which section, content before vs after. For a new-skill proposal, show the draft frontmatter + first paragraph at the suggested path.
4. **Confirm.** Wait for explicit user approval. On reject, log nothing and bail.
5. **Apply.** Write the edit (or create the new skill).
6. **Log.** Append to `metrics/config-changelog.jsonl` using the schema in the `generic-feedback-capture` skill — `type: "learn"`, `trigger: "user"`, `approved_by: "user"`.
7. **Verify.** Read back the modified section and confirm to the user that it landed.

## Keyword pass-through

If `$ARGUMENTS` explicitly uses one of the plugin's keywords (`amend`, `learn`, `remember`, `forget`), also invoke `dev-team:feedback-learning` after step 6 — the plugin's tooling is the source of truth for those keywords (rollback machinery, recurring-correction detection). The local skill provides the destination; the plugin owns the registry.

## Examples

```
/learn the BFF proxy must never strip the Authorization header
```
→ Classifies as a project-local `vendor-*-bff` skill update (or `nextjs-frontend-standards` if no vendor-bff skill exists). Proposes appending to the existing "Hard rules" section. Diff shown. On approval, applies and logs.

```
/learn from now on, prefer IReadOnlyList<T> over List<T> for repository return types
```
→ Classifies as `dotnet-coding-patterns` update. Proposes appending to the anti-patterns section (it's negative guidance about `List<T>`). Diff shown.

```
/learn we should document the order-fulfilment state machine explicitly
```
→ No existing skill is a clean fit. Proposes a new project-local skill (e.g. `vendor-order-state-machine`) with draft frontmatter + first paragraph. Waits for approval. Does not auto-create.

```
/learn user prefers branch-per-feature for refactors
```
→ Classifies as user preference. Routes to user-level auto-memory at `~/.claude/projects/<slug>/memory/`.

## When NOT to use

- For one-off comments that won't recur ("oh, ignore that one"). The diff-preview-and-log flow is overhead for ephemeral feedback.
- For routine code changes within a feature — those happen via the gate pipeline, not `/learn`.
- For stack-manifest edits with side effects. Edit `CLAUDE.md` directly; `guard-stack-manifest.sh` will validate.

## Notes

- `/learn` does not invoke the orchestrator. It's a direct-answer command that operates on the local toolbox.
- The routing skill (`generic-feedback-capture`) is the load-bearing piece. This command is a thin entry point.
- Audit trail lives at `metrics/config-changelog.jsonl` (append-only). The plugin's rollback skill can reverse entries created by this command.
