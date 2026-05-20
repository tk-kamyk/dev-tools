---
name: check
description: Run the per-stack validation matrix derived from the CLAUDE.md stack manifest. Stops on first failure per stack but reports results for every enabled stack.
user-invocable: true
---

Run the validation suite for every stack enabled in the CLAUDE.md stack manifest. Each enabled stack runs its `test_cmd` from the manifest; report results per stack at the end.

## Steps

1. **Read the manifest** from CLAUDE.md. Build the list of enabled stacks and their `test_cmd` entries.

2. **For each enabled code-bearing stack**, run its test command in sequence. Capture pass/fail and brief output. Code-bearing stacks: `dotnet`, `nextjs`, `expo`.

   Typical commands (the manifest is authoritative; these are the expected shapes):
   - **dotnet**: `dotnet test <api-root>/<solution>.slnx`
   - **nextjs**: `cd <frontend-root> && pnpm check-types && pnpm lint && pnpm test`
   - **expo**: `cd <mobile-root> && pnpm lint && pnpm test`

3. **Skip stacks not in the manifest** — print a single-line note per skip.

4. **Report results**, one line per stack:
   ```
   dotnet: PASS (412 tests)
   nextjs: FAIL (typecheck: 3 errors)
   expo:   PASS (56 tests)
   ```
   For any FAIL, print the first 20 lines of stderr/stdout that explain the failure. Do NOT auto-fix.

5. **Exit code**: non-zero if any stack failed.

## Arguments (passed through as `$ARGUMENTS`)

- No args: run every enabled code-bearing stack.
- `dotnet` / `nextjs` / `expo` / etc.: run only the named stack, even if others are enabled.
- `--quick`: skip lint and `check-types` for the frontend stack, run tests only. Useful in dev loops.

## Notes

- Do NOT auto-fix lint errors or type errors. Report and let the user decide.
- This command does NOT route through the orchestrator — it's a status / verification verb.
- Failing this command is the user's signal to fix before opening a PR.
