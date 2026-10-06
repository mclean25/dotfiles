---
name: remote-browser-smoke-test
description: >-
  Run a remote browser smoke test by starting this repo's per-worktree local dev
  stack on the development host and verifying a changed user flow in full
  headless Chromium. Use when the user asks to test frontend behavior through
  the remote dev server, reproduce a UI issue in the running app, or confirm a
  change by performing its real workflow. Do not use for Vitest-only or
  browser-contract-only tests that need no app login.
---
# Remote browser smoke test

Exercise the observable behavior the user cares about through the real local app.
The result is evidence only when the browser reaches the changed surface and the
expected state transition completes.

## Start the isolated stack

Run `pnpm dev` in a persistent terminal session and wait for all three positive
signals:

- `Local Supabase demo data is ready.`
- Vite reports its `Local:` URL.
- The Edge Functions runtime reports that it is serving functions.

The app port belongs to the current worktree's claimed ten-port block. Read the
URL from this run; do not assume port 8080 or reuse another worktree's server.
Starting the stack may need permission to update `/home/alex/.cozee/` and use
Docker. Keep the session alive throughout the browser test.

The startup output prints the deterministic local demo accounts and password.
Use one of those accounts. The test must target the printed localhost URL and
its local Supabase stack; hosted staging and production are outside this skill's
write scope.

## Drive full headless Chromium

Use the repo's Playwright dependency and the full Chromium build already held in
the user-wide Playwright cache. That cache is shared by every worktree and only
needs another browser download when the pinned Playwright revision changes or
the cache is removed.

For an existing E2E spec, select the full build with:

```bash
E2E_CHANNEL=chromium E2E_EMAIL='<local account>' E2E_PASSWORD='<local password>' \
  pnpm exec playwright test <spec> --project=chromium --reporter=list
```

For a flow not covered faithfully by an existing spec, use a one-off Node script
that imports `chromium` from `@playwright/test` and launches with:

```js
await chromium.launch({
  headless: true,
  executablePath: chromium.executablePath(),
  args: ["--disable-dev-shm-usage"],
});
```

Prefer role, label, and existing `data-*` selectors from the rendered product.
Use deterministic IDs only when the local seed explicitly owns them and the UI
route requires one. Keep one-off scripts outside the working tree unless the
user asked to add permanent E2E coverage.

The lightweight Playwright headless shell has crashed while rendering `/chats`
on this server. A page crash is an inconclusive instrument failure. Retry the
same flow with the full Chromium build above; do not interpret a selector miss,
catch-to-false, or skipped test after a crash as product evidence.

## Prove the behavior

Assert the postcondition that distinguishes success from a click that merely
occurred. For a write flow, wait until the optimistic state settles, confirm the
persisted/rendered result, and check any relevant cleared or navigated state.
Capture the exact input and observed output without exposing credentials.

A skipped test is not a pass. Read its reason and verify that its discovery
selector actually covers the seeded data shape. For example, the local chat seed
contains channels; a test that searches only for a conversation can skip without
ever exercising message sending.

If the dev stack produces a negative during startup, follow the repository's
positive-instrument rule in `AGENTS.md`: first show that the instrument can
produce an expected positive after the stack has warmed up.

## Finish

Stop the persistent `pnpm dev` session. Report:

- the browser and local URL used;
- the user flow performed;
- the observable postcondition and whether it passed;
- skips, renderer crashes, console errors, or coverage gaps separately;
- whether the test created local-only data or changed repository files.
