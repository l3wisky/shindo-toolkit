#!/usr/bin/env bash
set -euo pipefail

project_root="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$project_root"

mkdir -p dist
bundle_temp="$(mktemp "${TMPDIR:-/tmp}/shindo-toolkit-bundle.XXXXXX.luau")"
artifact_temp="$(mktemp "dist/.shindo-toolkit.XXXXXX.luau")"
cleanup() {
    rm -f "$bundle_temp" "$artifact_temp"
}
trap cleanup EXIT

darklua process build/entry.luau "$bundle_temp"
IFS=$'\t' read -r version _ < <(luau scripts/metadata.luau)

{
    printf '%s\n' "-- Shindo Toolkit v${version}"
    printf '%s\n' "-- Required Notice: Copyright 2026 l3wisky."
    printf '%s\n' "-- Licensed under PolyForm Noncommercial 1.0.0: https://polyformproject.org/licenses/noncommercial/1.0.0"
    printf '%s\n\n' "-- Source: https://github.com/l3wisky/shindo-toolkit"
    cat "$bundle_temp"
} > "$artifact_temp"

mv "$artifact_temp" dist/shindo-toolkit.luau
