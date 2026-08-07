# Release checklist

## Automated gates

- [ ] StyLua check passes.
- [ ] Selene reports zero warnings and errors.
- [ ] The official Luau analyzer reports no type or lint errors for the declared runtime environment.
- [ ] Unit/invariant tests pass.
- [ ] Every source and generated Luau file compiles.
- [ ] Stable/dev loader references and release metadata agree.
- [ ] Rayfield release artifact matches the recorded SHA-256 and compiles.
- [ ] actionlint and pedantic zizmor pass.
- [ ] Release bundle and `SHA256SUMS` are generated from a clean commit.

## Live runtime acceptance

- [ ] Stable loader opens the expected version and does not use `dev` settings.
- [ ] Dev loader shows the `DEV` tag and does not overwrite stable settings.
- [ ] English/Russian locale and all themes rebuild cleanly.
- [ ] Bloodline, Kenjutsu, and RCGenkai capture once, apply repeatedly, and restore the first original.
- [ ] Outfit, home, rejoin, rollback, restore, and rollback + rejoin produce accurate success/failure feedback.
- [ ] Missing `startevent`, stat values, and `RCGENKAI.item1` do not prevent unrelated tabs from opening.
- [ ] Re-running the loader replaces the old UI without duplicate callbacks.
- [ ] Diagnostics contains no username, user ID, Job ID, private-server code, or saved values.
- [ ] Filesystem- and clipboard-disabled environments degrade as documented.

## Promotion

- [ ] `dev` CI and Actions Security checks are green at the promotion commit.
- [ ] `src/config.luau`, changelog, and release title use the same SemVer.
- [ ] `release/vX.Y.Z` starts at the current `main` and contains only reviewed, unreleased `dev` commits.
- [ ] The focused release PR contains only the intended release delta.
- [ ] Release workflow publishes `shindo-toolkit.luau`, `SHA256SUMS`, and provenance for the main commit.
- [ ] Stable loader resolves and executes the published asset.

Static and CI checks do not substitute for the live runtime section. Any unchecked item must be recorded as an
explicit release risk rather than silently treated as verified.
