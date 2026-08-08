# Rayfield Gen2 vendor snapshot

This directory contains the unmodified official single-file Rayfield Gen2 runtime used by Shindo Toolkit.

- Version: 1.1.0
- Upstream commit: `84e39394069be81b0e4ad60d70821f45e061f2e1`
- Artifact: <https://github.com/SiriusSoftwareLtd/rayfield-gen2/releases/download/1.1.0/bundled.luau>
- SHA-256: `e3c337e969e6c4c0de91a77156201094568be55fdfe2669368c48c1d8169d0a6`
- License: Mozilla Public License 2.0; see [LICENSE](LICENSE)

The snapshot is bundled into stable releases so an already published Shindo Toolkit version does not depend on a second runtime download. Update the pinned metadata in `src/config.luau`, then run:

```bash
bash scripts/vendor-rayfield.sh
scripts/ci.sh
```

Do not reformat or edit `bundled.luau`. Any upstream update should arrive as a separately reviewable dependency commit with a verified checksum.
