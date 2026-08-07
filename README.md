# Shindo Toolkit

[Русская версия](README.ru.md)

[![CI](https://github.com/l3wisky/shindo-toolkit/actions/workflows/ci.yml/badge.svg?branch=main)](https://github.com/l3wisky/shindo-toolkit/actions/workflows/ci.yml)
[![Actions Security](https://github.com/l3wisky/shindo-toolkit/actions/workflows/actions-security.yml/badge.svg?branch=main)](https://github.com/l3wisky/shindo-toolkit/actions/workflows/actions-security.yml)
[![Release](https://img.shields.io/github/v/release/l3wisky/shindo-toolkit)](https://github.com/l3wisky/shindo-toolkit/releases/latest)

Shindo Toolkit is a small, bilingual Luau toolkit for stable QOL and FUN workflows. It deliberately excludes
combat automation, farming, and PVP features. The project is unofficial and is not affiliated with RELL World,
Roblox Corporation, or Sirius Software.

Version 1.0.0 turns the original collection of remotely loaded modules into a reproducible release: one project
bundle, deterministic tooling, explicit failure boundaries, privacy-safe diagnostics, and a hardened GitHub
Actions supply chain.

## Stable loader

```luau
loadstring(game:HttpGet("https://raw.githubusercontent.com/l3wisky/shindo-toolkit/main/loader.luau"))()
```

The stable loader downloads the single-file asset from the latest published GitHub release. A release also
contains `SHA256SUMS` and a GitHub artifact provenance attestation. It does not execute code from `dev`.

## Dev loader

```luau
loadstring(game:HttpGet("https://raw.githubusercontent.com/l3wisky/shindo-toolkit/dev/loader.dev.luau"))()
```

The dev loader resolves individual modules from the moving `dev` branch. It uses separate local settings and is
intended only for testing unreleased changes.

## Features

- Bloodline and Kenjutsu apply/restore flows with original-value capture per server session.
- RCGenkai override with the same safe restore semantics.
- Outfit loading, home teleport, rejoin, and confirmed date rollback/restore.
- Player data viewer with optional clipboard support.
- English and Russian UI, six Rayfield themes, notification preferences, and local settings.
- Runtime diagnostics for executor capabilities and currently available game targets. The report contains no
  username, user ID, job ID, private-server code, or saved setting values.
- Reload-safe startup: dependency or UI bootstrap failure leaves the previous working session intact.

Game-specific targets can change upstream. A missing target disables the affected action and produces a useful
error; it no longer prevents the rest of the UI from starting.

## Runtime requirements and trust boundary

The loader requires `game:HttpGet` and `loadstring`. Filesystem and clipboard APIs are optional; the toolkit stays
usable without them, but settings may not persist and copy buttons will report that the capability is unavailable.

At runtime, the project downloads only:

1. the Shindo Toolkit release bundle (or raw `dev` modules when explicitly using the dev loader); and
2. the versioned Rayfield Gen2 1.1.0 release asset documented in [NOTICE](NOTICE).

There is no telemetry or analytics. The build verifies the Rayfield asset against its recorded SHA-256 before a
release can be published. Not every executor behaves identically; use Diagnostics when reporting compatibility
problems and never include private-server codes or account secrets.

## Development

[Rokit](https://github.com/rojo-rbx/rokit) installs StyLua, Selene, and darklua. The setup script also downloads
the official Luau 0.733 archive and verifies its platform-specific SHA-256 so that all three CLI programs are
available:

```bash
scripts/setup.sh
scripts/ci.sh
```

The same command used by CI formats-checks the source, runs Selene and the official Luau analyzer, executes
unit/invariant tests, compiles every Luau file, builds the release bundle, verifies release metadata and the
Rayfield checksum, and checks Git whitespace errors. Build only with `scripts/build.sh`; generated files live in
`dist/` and are not committed.

The release lifecycle is intentionally narrow:

1. changes enter `dev` through a reviewed, green pull request;
2. a promotion pull request moves the tested `dev` commit to `main`;
3. the release workflow rebuilds from `main`, creates a draft, attests and uploads the assets, then publishes it.

See [CONTRIBUTING.md](CONTRIBUTING.md), [architecture](docs/ARCHITECTURE.md), and the
[release checklist](docs/RELEASE_CHECKLIST.md) before changing runtime or release behavior.

## Support and security

For ordinary bugs, use the structured bug-report form and attach the Diagnostics output. For a vulnerability in
the loader, workflow, or release chain, follow [SECURITY.md](SECURITY.md) instead of opening a public issue.

## License

Source code is available under the [PolyForm Noncommercial License 1.0.0](LICENSE). Third-party notices are in
[NOTICE](NOTICE).
