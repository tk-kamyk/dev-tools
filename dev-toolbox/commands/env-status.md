---
name: env-status
description: Check the health of local .env files across all enabled stacks. Reports freshness, drift from .env.example, and (for nextjs) schema mismatches with lib/env.ts.
user-invocable: true
---

Check environment-file health for every stack enabled in the manifest. Read CLAUDE.md and only run checks for enabled stacks. Use each stack's `root` from the manifest to locate `.env` files.

## For each enabled stack

### nextjs (frontend root from manifest)

1. **Freshness**:
   ```bash
   stat -f "Last pulled: %Sm" <frontend-root>/.env 2>/dev/null || echo "No .env file found — run: cd <frontend-root> && pnpm env:pull"
   ```
   If older than 24 hours, warn and suggest `cd <frontend-root> && pnpm env:pull`.

2. **Compare `.env` against `.env.example`**:
   - Read both `<frontend-root>/.env` and `<frontend-root>/.env.example`.
   - List variables in `.env.example` missing from `.env`.
   - List variables in `.env` NOT in `.env.example` (potentially stale).

3. **Cross-check with Zod schema** in `<frontend-root>/lib/env.ts` (if present):
   - List variables in the Zod schema missing from `.env.example` (docs gap).
   - List variables in `.env.example` NOT in the Zod schema (unused).

### dotnet (api root from manifest)

1. Check for `<api-root>/src/<Solution>.Api/appsettings.Development.json` and any user-secrets (`dotnet user-secrets list --project <api-root>/src/<Solution>.Api/`).
2. List which sections appear in `appsettings.json` as TBD placeholders that should be set in user-secrets or environment variables.
3. Flag any secrets that look like real values in `appsettings.Development.json` (should be moved to user-secrets).

### expo (mobile root from manifest)

1. **Freshness**:
   ```bash
   stat -f "Last pulled: %Sm" <mobile-root>/.env 2>/dev/null || echo "No .env file found for mobile"
   ```
2. **Compare against `.env.example`** if present.

## Report

- Freshness status per stack.
- Missing / extra variables with recommended actions.
- Cross-schema mismatches.
- If everything is in sync for a stack, confirm healthy.
- If a stack is not enabled, skip silently.

## Notes

- Do NOT print actual values for any env var — just names and presence.
- Do NOT auto-fix. Tell the user what needs attention.
