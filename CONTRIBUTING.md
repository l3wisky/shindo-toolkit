# Contributing

Contributions should make the toolkit smaller, clearer, or more reliable in a demonstrated user scenario. New
abstractions and compatibility branches need a concrete reason; speculative executor support is not enough.

## Workflow

1. Branch from `dev` and keep the change focused.
2. Install the pinned tools with `scripts/setup.sh`.
3. Run `scripts/ci.sh` before opening a pull request.
4. Target the pull request at `dev`, complete the template, and include live-game evidence for runtime changes.
5. Do not edit generated `dist/` files or publish tags/releases manually.

## Runtime changes

- Keep executor-specific globals inside `src/platform.luau`.
- Treat game instances and remotes as optional, mutable dependencies.
- Preserve original values before the first write and make restoration explicit.
- Keep user-facing strings in both locales; tests enforce key and placeholder parity.
- Avoid telemetry, hidden network requests, combat automation, farming, and PVP behavior.
- Never include usernames, IDs, private-server codes, Job IDs, or saved values in diagnostics.

## Definition of done

A green build is necessary but not sufficient. The pull request must also explain the real scenario, failure mode,
compatibility impact, and why the chosen solution is the simplest correct one. Reviewers should actively look for
duplicate state, magic values, swallowed errors, stale callbacks, irreversible actions, and misleading success
messages.

Runtime changes should complete the relevant items in `docs/RELEASE_CHECKLIST.md`. If live verification is not
possible, say so explicitly; do not imply that static checks prove game behavior.
