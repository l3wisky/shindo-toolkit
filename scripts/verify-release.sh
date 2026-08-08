#!/usr/bin/env bash
set -euo pipefail

project_root="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$project_root"

IFS=$'\t' read -r version rayfield_version rayfield_url rayfield_sha artifact_url \
    < <(luau scripts/metadata.luau)

grep -Fq "$artifact_url" loader.luau
grep -Fq 'local runtimeRef = "dev"' loader.dev.luau
grep -Fq 'raw.githubusercontent.com/l3wisky/shindo-toolkit/main/loader.luau' README.md
grep -Fq 'raw.githubusercontent.com/l3wisky/shindo-toolkit/dev/loader.dev.luau' README.md
grep -Fq 'raw.githubusercontent.com/l3wisky/shindo-toolkit/main/loader.luau' README.ru.md
grep -Fq 'raw.githubusercontent.com/l3wisky/shindo-toolkit/dev/loader.dev.luau' README.ru.md
grep -Fq "$rayfield_url" NOTICE
grep -Fq "SHA-256: ${rayfield_sha}" NOTICE
grep -Fq "Shindo Toolkit v${version}" dist/shindo-toolkit.luau

module_paths="$(
    grep -oE 'bootstrap\.load\("[^"]+' src/init.luau \
        | sed 's/^bootstrap\.load("//' \
        | LC_ALL=C sort -u
)"
while IFS= read -r module_path; do
    grep -Fq "[\"${module_path}\"]" build/entry.luau
done <<< "$module_paths"

translation_keys="$(
    grep -rhoE --include='*.luau' 'app\.(ui|t|error|toast)\("[a-z0-9_]+' src \
        | sed -E 's/^app\.(ui|t|error|toast)\("//' \
        | LC_ALL=C sort -u
)"
while IFS= read -r translation_key; do
    grep -Eq "^[[:space:]]+${translation_key} =" src/i18n.luau
done <<< "$translation_keys"

rayfield_vendor="vendor/rayfield-gen2/bundled.luau"
grep -Fq "Rayfield Gen2 v${rayfield_version}" "$rayfield_vendor"
printf '%s  %s\n' "$rayfield_sha" "$rayfield_vendor" | sha256sum --check --strict
luau-compile "$rayfield_vendor" > /dev/null

rayfield_size="$(wc -c < "$rayfield_vendor" | tr -d '[:space:]')"
bundle_size="$(wc -c < dist/shindo-toolkit.luau | tr -d '[:space:]')"
printf 'Verified Rayfield vendor (%s bytes) and release bundle (%s bytes).\n' \
    "$rayfield_size" "$bundle_size"
