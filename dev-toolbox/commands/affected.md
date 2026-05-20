---
name: affected
description: Show which Turborepo packages in spa/ are affected by current changes compared to main. Skips if turborepo stack is not enabled.
user-invocable: true
---

Show which spa/ packages are affected by current changes versus `main`.

## Pre-check

Read the CLAUDE.md stack manifest. If `turborepo` is not enabled, print:

```
turborepo stack not enabled in manifest — skipping /affected.
```

and exit. Otherwise:

## Steps

1. **Show affected packages**:
   ```bash
   cd spa && pnpm turbo run build --dry --filter=...[origin/main...HEAD] 2>&1
   ```

2. **Show changed files by package**:
   ```bash
   git diff origin/main...HEAD --stat
   ```

3. **Summarise**:
   - List affected packages and why (direct changes vs dependency cascade).
   - Suggest test commands for affected packages:
     - `cd spa && pnpm run -F <package> test` for each affected package with tests.
   - Flag if shared packages (`@repo/ui`, `@repo/hooks`, `@repo/utils`, `@repo/api`, `@repo/env`) were modified — those cascade to downstream consumers.

## Notes

- Only covers spa/. The api/ and mobile-app/ stacks have their own change-detection needs (e.g. `dotnet test` always runs the full solution).
- For a full per-stack validation run, use `/check`.
