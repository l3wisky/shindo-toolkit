#!/usr/bin/env bash
set -euo pipefail

project_root="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$project_root"

luau_bin="$project_root/.tools/luau-0.733"
shellcheck_bin="$project_root/.tools/shellcheck-0.11.0"
if [[ -d "$luau_bin" ]]; then
    export PATH="$luau_bin:$PATH"
fi
if [[ -d "$shellcheck_bin" ]]; then
    export PATH="$shellcheck_bin:$PATH"
fi

for executable in stylua selene darklua luau luau-analyze luau-compile shellcheck; do
    if ! command -v "$executable" > /dev/null 2>&1; then
        printf 'Missing required tool %s; run scripts/setup.sh first.\n' "$executable" >&2
        exit 1
    fi
done

mapfile -d '' luau_files < <(
    find loader.luau loader.dev.luau src build scripts tests -type f -name '*.luau' -print0 \
        | LC_ALL=C sort -z
)

stylua --check .
selene "${luau_files[@]}"
luau-analyze "${luau_files[@]}"
luau tests/run.luau
bash -n scripts/*.sh
shellcheck scripts/*.sh

for file in "${luau_files[@]}"; do
    luau-compile "$file" > /dev/null
done

scripts/build.sh
luau-compile dist/shindo-toolkit.luau > /dev/null
scripts/verify-release.sh
git diff --check
git diff --cached --check
git show --check --format= --no-renames HEAD
