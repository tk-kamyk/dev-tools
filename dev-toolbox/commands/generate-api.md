---
name: generate-api
description: Regenerate the Orval-based API client (and MSW mocks) in the Next.js frontend, then verify type checks. Skips if nextjs stack absent.
user-invocable: true
---

Regenerate API types and MSW mocks, then verify frontend / mobile alignment.

## Pre-check

Read the CLAUDE.md stack manifest. If `nextjs` is not enabled, print:

```
nextjs stack not enabled in manifest — skipping /generate-api.
```

and exit. Use each enabled stack's `root` from the manifest to locate the frontend (and mobile) roots.

## Steps

1. **Run API generation** for the frontend:
   ```bash
   cd <frontend-root> && pnpm run -F @repo/api generate
   ```
   Requires the upstream API running OR a committed `openapi/v1.json` snapshot in the repo.

2. **Check for type errors in frontend consumers**:
   ```bash
   cd <frontend-root> && pnpm check-types
   ```

3. **If `expo` is enabled, regenerate and verify the mobile app too** (if it consumes the same OpenAPI client — confirm with the user first):
   ```bash
   cd <mobile-root> && pnpm <equivalent-generate>
   cd <mobile-root> && pnpm check-types
   ```

4. **Report results**:
   - If types pass everywhere: confirm API types are in sync.
   - If type errors found: list each error with file path and line number.
   - Flag any **breaking changes**: removed/renamed types, changed signatures, deleted fields.
   - Suggest fixes for each breaking change, but do NOT auto-fix — let the user decide impact first.

## Notes

- Run after backend API changes to catch frontend misalignment early.
- Type errors after generation indicate the frontend uses types/fields that changed upstream.
- The `customInstance` mutator must continue to point at the BFF proxy path (`/api/proxy/…`) — never let regeneration change that. Detail in a project-local `vendor-*-bff` skill if you ship one.
- Files in `packages/api/src/generated/` are output; never edit by hand.
