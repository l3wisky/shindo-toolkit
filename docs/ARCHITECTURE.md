# Architecture

Shindo Toolkit keeps the source modular for review and publishes it as one Luau artifact for stable use.

## Runtime flow

1. `loader.luau` downloads the latest published `shindo-toolkit.luau` asset and executes it.
2. `build/entry.luau` provides a static module map to `src/init.luau`; darklua replaces those requires during build.
3. `init` waits for the local player, creates the platform adapter and session, then downloads and compiles the
   versioned Rayfield asset.
4. A replacement window is built before the existing session is unloaded.
5. Feature modules receive one `app` context containing configuration, storage, translations, value state,
   diagnostics, and UI helpers.

The dev loader follows the same `init` contract but resolves source modules from `dev` and marks the session as a
development channel.

## Module responsibilities

| Module | Responsibility |
| --- | --- |
| `config` | Version, URLs, checksums, timeouts, place constants, themes, and icons |
| `platform` | Executor globals and fallible HTTP/filesystem/clipboard operations |
| `storage` | Versioned settings decode, validation, persistence, and reset |
| `value_state` | Target lookup, first-original capture, protected apply, and restore |
| `diagnostics` | Privacy-safe capability and target snapshot |
| `i18n` | English/Russian strings and Rayfield locale mapping |
| `kg_changer`, `rcgenkai`, `misc` | UI composition and feature-specific behavior |
| `init` | Lifecycle, dependency staging, connection cleanup, rebuild, and teardown |

## Failure boundaries

- Release or Rayfield download/compile failure is fatal before replacing a running session.
- A missing game target or remote is local to the selected operation.
- Filesystem and clipboard absence are capabilities, not startup failures.
- Date operations are serialized and release their lock after success, handled failure, or exception.
- All temporary connections are disconnected on rebuild/unload.

## Supply chain

`rokit.toml` pins the build tools. CI compiles and tests source, bundles it, verifies the Rayfield SHA-256, and
uploads the candidate. The release workflow repeats the same gate on `main`, creates a draft, requests an OIDC
identity for provenance, uploads the bundle/checksum, and publishes only after those steps succeed.

Third-party Actions use full commit SHAs. Dependabot targets `dev`; actionlint and zizmor independently validate
workflow structure and security posture.
