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
IFS=$'\t' read -r version rayfield_version _ < <(luau scripts/metadata.luau)

{
    printf '%s\n' "-- Shindo Toolkit v${version}"
    printf '%s\n' "-- Required Notice: Copyright 2026 l3wisky."
    printf '%s\n' "-- Shindo Toolkit is licensed under PolyForm Noncommercial 1.0.0:"
    printf '%s\n' "-- https://polyformproject.org/licenses/noncommercial/1.0.0"
    printf '%s\n' "-- Includes unmodified Rayfield Gen2 ${rayfield_version} under MPL-2.0."
    printf '%s\n' "-- Dependency source and notices: https://github.com/l3wisky/shindo-toolkit"
    printf '%s\n\n' "-- Source: https://github.com/l3wisky/shindo-toolkit"
    cat "$bundle_temp"
} > "$artifact_temp"

mv "$artifact_temp" dist/shindo-toolkit.luau
