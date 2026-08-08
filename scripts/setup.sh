#!/usr/bin/env bash
set -euo pipefail

project_root="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$project_root"

rokit install
bash scripts/install-luau-cli.sh
bash scripts/install-shellcheck.sh
