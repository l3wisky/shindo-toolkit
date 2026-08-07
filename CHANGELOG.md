# Changelog

All notable project changes are documented here. This project follows [Semantic Versioning](https://semver.org/).

## [1.0.0] - 2026-08-07

### Added

- Reproducible single-file release bundle with `SHA256SUMS` and provenance attestation.
- Rokit-managed Luau, StyLua, Selene, and darklua toolchain.
- Unit and invariant tests for translations, data catalogs, release metadata, and value restoration.
- Privacy-safe runtime Diagnostics view and copyable support report.
- Capability adapter for HTTP, compilation, clipboard, and persistent settings.
- Structured issue forms, contribution guidance, architecture notes, and a release checklist.

### Changed

- Stable loader now executes one published release asset instead of six moving source modules.
- Runtime startup stages Rayfield and the replacement UI before unloading an existing session.
- Missing game remotes or targets now disable only the affected operation.
- Dev and stable settings use separate folders.
- GitHub Actions are split into CI, Actions security, and draft-first release workflows.
- Third-party Actions are pinned to full commit SHAs and updated by Dependabot through `dev`.

### Fixed

- Date-operation lock is always released when a callback fails.
- Settings persistence failures are no longer silently ignored.
- Apply/restore behavior now preserves the first original value and handles read/write failures consistently.
- Failed Rayfield download, compilation, or startup no longer destroys the previous working session.

### Security

- Release builds verify the immutable Rayfield 1.1.0 asset by SHA-256.
- actionlint and zizmor audit workflow syntax, permissions, pinning, and common injection hazards.
- Release publication uses minimal write permissions and OIDC-backed artifact provenance.

[1.0.0]: https://github.com/l3wisky/shindo-toolkit/releases/tag/v1.0.0
