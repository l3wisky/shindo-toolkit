#!/usr/bin/env bash
set -euo pipefail

project_root="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$project_root"

stylua --check .
selene loader.luau loader.dev.luau src build scripts tests
luau-analyze loader.luau loader.dev.luau src/*.luau build/*.luau scripts/*.luau tests/*.luau
luau tests/unit.luau

while IFS= read -r file; do
    luau-compile "$file" > /dev/null
done < <(rg --files -g '*.luau' -g '!dist/**' | sort)

scripts/build.sh
luau-compile dist/shindo-toolkit.luau > /dev/null
scripts/verify-release.sh
git diff --check
git diff --cached --check
git show --check --format= --no-renames HEAD
