#!/usr/bin/env bash
set -euo pipefail

project_root="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$project_root"

mkdir -p dist
bundle_temp="$(mktemp "${TMPDIR:-/tmp}/shindo-toolkit-bundle.XXXXXX.luau")"
artifact_temp="$(mktemp "dist/.shindo-toolkit.XXXXXX.luau")"
notices_temp="$(mktemp "dist/.third-party-notices.XXXXXX.txt")"
cleanup() {
    rm -f "$bundle_temp" "$artifact_temp" "$notices_temp"
}
trap cleanup EXIT

darklua process build/entry.luau "$bundle_temp"
metadata="$(luau scripts/metadata.luau)"
version=""
rayfield_version=""
IFS=$'\t' read -r version rayfield_version _ <<< "$metadata"
if [[ -z "$version" || -z "$rayfield_version" ]]; then
    printf 'Release metadata is incomplete.\n' >&2
    exit 1
fi

{
    printf '%s\n' "-- Shindo Toolkit v${version}"
    printf '%s\n' "-- Required Notice: Copyright 2026 l3wisky."
    printf '%s\n' "-- Shindo Toolkit is licensed under PolyForm Noncommercial 1.0.0:"
    printf '%s\n' "-- https://polyformproject.org/licenses/noncommercial/1.0.0"
    printf '%s\n' "-- Bundled dependency: Rayfield Gen2 ${rayfield_version} source under MPL-2.0:"
    printf '%s\n' "-- https://www.mozilla.org/MPL/2.0/"
    printf '%s\n' "-- Vendored source and notices:"
    printf '%s\n' "-- https://github.com/l3wisky/shindo-toolkit/tree/main/vendor/rayfield-gen2"
    printf '%s\n\n' "-- Source: https://github.com/l3wisky/shindo-toolkit"
    cat "$bundle_temp"
} > "$artifact_temp"

{
    cat NOTICE
    printf '\n\nFull Mozilla Public License 2.0 text for Rayfield Gen2 follows.\n\n'
    cat vendor/rayfield-gen2/LICENSE
} > "$notices_temp"

mv "$artifact_temp" dist/shindo-toolkit.luau
mv "$notices_temp" dist/THIRD_PARTY_NOTICES.txt
