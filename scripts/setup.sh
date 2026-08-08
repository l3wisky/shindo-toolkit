#!/usr/bin/env bash
set -euo pipefail

project_root="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$project_root"

source scripts/tool-versions.sh
bash scripts/install-rokit.sh
rokit_executable=".tools/rokit-$ROKIT_VERSION/rokit"
if [[ -x "${rokit_executable}.exe" ]]; then
    rokit_executable="${rokit_executable}.exe"
fi
"$rokit_executable" install
bash scripts/install-luau-cli.sh
bash scripts/install-shellcheck.sh
