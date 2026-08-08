#!/usr/bin/env bash
set -euo pipefail

project_root="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$project_root"

luau_bin="$project_root/.tools/luau-0.733"
if [[ -d "$luau_bin" ]]; then
    export PATH="$luau_bin:$PATH"
fi
for executable in luau luau-compile curl; do
    if ! command -v "$executable" > /dev/null 2>&1; then
        printf 'Missing required tool %s; run scripts/setup.sh first.\n' "$executable" >&2
        exit 1
    fi
done

IFS=
if [[ -z "$rayfield_url" || -z "$rayfield_sha" ]]; then
    printf 'Rayfield metadata is incomplete.\n' >&2
    exit 1
fi

destination="$project_root/vendor/rayfield-gen2/bundled.luau"
mkdir -p "$(dirname -- "$destination")"
download="$(mktemp "${TMPDIR:-/tmp}/rayfield-gen2.XXXXXX.luau")"
cleanup() {
    rm -f "$download"
}
trap cleanup EXIT

curl \
    --connect-timeout 15 \
    --fail \
    --location \
    --max-time 120 \
    --retry 3 \
    --retry-all-errors \
    --silent \
    --show-error \
    "$rayfield_url" \
    --output "$download"

if command -v sha256sum > /dev/null 2>&1; then
    printf '%s  %s\n' "$rayfield_sha" "$download" | sha256sum --check --strict
elif command -v shasum > /dev/null 2>&1; then
    actual_sha="$(shasum -a 256 "$download" | cut -d ' ' -f 1)"
    if [[ "$actual_sha" != "$rayfield_sha" ]]; then
        printf 'Rayfield checksum mismatch: expected %s, got %s\n' "$rayfield_sha" "$actual_sha" >&2
        exit 1
    fi
else
    printf 'sha256sum or shasum is required to verify Rayfield.\n' >&2
    exit 1
fi

luau-compile "$download" > /dev/null
mv "$download" "$destination"
printf 'Vendored Rayfield Gen2 %s at %s\n' "$rayfield_version" "$destination"
\t' read -r _ rayfield_version rayfield_url rayfield_sha _ < <(luau scripts/metadata.luau)
if [[ -z "$rayfield_url" || -z "$rayfield_sha" ]]; then
    printf 'Rayfield metadata is incomplete.\n' >&2
    exit 1
fi

destination="$project_root/vendor/rayfield-gen2/bundled.luau"
mkdir -p "$(dirname -- "$destination")"
download="$(mktemp "${TMPDIR:-/tmp}/rayfield-gen2.XXXXXX.luau")"
cleanup() {
    rm -f "$download"
}
trap cleanup EXIT

curl \
    --connect-timeout 15 \
    --fail \
    --location \
    --max-time 120 \
    --retry 3 \
    --retry-all-errors \
    --silent \
    --show-error \
    "$rayfield_url" \
    --output "$download"

if command -v sha256sum > /dev/null 2>&1; then
    printf '%s  %s\n' "$rayfield_sha" "$download" | sha256sum --check --strict
elif command -v shasum > /dev/null 2>&1; then
    actual_sha="$(shasum -a 256 "$download" | cut -d ' ' -f 1)"
    if [[ "$actual_sha" != "$rayfield_sha" ]]; then
        printf 'Rayfield checksum mismatch: expected %s, got %s\n' "$rayfield_sha" "$actual_sha" >&2
        exit 1
    fi
else
    printf 'sha256sum or shasum is required to verify Rayfield.\n' >&2
    exit 1
fi

luau-compile "$download" > /dev/null
mv "$download" "$destination"
printf 'Vendored Rayfield Gen2 at %s\n' "$destination"
