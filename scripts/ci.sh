#!/usr/bin/env bash
set -euo pipefail

project_root="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$project_root"

luau_bin="$project_root/.tools/luau-0.733"
if [[ -d "$luau_bin" ]]; then
    export PATH="$luau_bin:$PATH"
fi

for executable in stylua selene darklua luau luau-analyze luau-compile; do
    if ! command -v "$executable" > /dev/null 2>&1; then
        printf 'Missing required tool %s; run scripts/setup.sh first.\n' "$executable" >&2
        exit 1
    fi
done

stylua --check .
selene loader.luau loader.dev.luau src build scripts tests
luau-analyze loader.luau loader.dev.luau src/*.luau build/*.luau scripts/*.luau tests/*.luau
luau tests/unit.luau

find loader.luau loader.dev.luau src build scripts tests -type f -name '*.luau' -print0 \
    | LC_ALL=C sort -z \
    | while IFS= read -r -d '' file; do
        luau-compile "$file" > /dev/null
    done

scripts/build.sh
luau-compile dist/shindo-toolkit.luau > /dev/null
scripts/verify-release.sh
git diff --check
git diff --cached --check
git show --check --format= --no-renames HEAD
