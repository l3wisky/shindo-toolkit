#!/usr/bin/env bash
set -euo pipefail

project_root="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$project_root"

metadata="$(luau scripts/metadata.luau)"
version=""
rayfield_version=""
rayfield_url=""
rayfield_sha=""
artifact_url=""
IFS=$'\t' read -r version rayfield_version rayfield_url rayfield_sha artifact_url <<< "$metadata"
if [[ -z "$version" || -z "$rayfield_version" || -z "$rayfield_url" || -z "$rayfield_sha" || -z "$artifact_url" ]]; then
    printf 'Release metadata is incomplete.\n' >&2
    exit 1
fi

verify_sha256() {
    local expected_sha="$1"
    local file="$2"
    local actual_sha

    if command -v sha256sum > /dev/null 2>&1; then
        printf '%s  %s\n' "$expected_sha" "$file" | sha256sum --check --strict
        return
    fi
    if command -v shasum > /dev/null 2>&1; then
        actual_sha="$(shasum -a 256 "$file" | cut -d ' ' -f 1)"
        if [[ "$actual_sha" == "$expected_sha" ]]; then
            return
        fi
        printf 'Checksum mismatch for %s: expected %s, got %s\n' \
            "$file" "$expected_sha" "$actual_sha" >&2
        exit 1
    fi
    printf 'sha256sum or shasum is required to verify release inputs.\n' >&2
    exit 1
}

grep -Fq "$artifact_url" loader.luau
grep -Fq 'local runtimeRef = "dev"' loader.dev.luau
grep -Fq 'raw.githubusercontent.com/l3wisky/shindo-toolkit/main/loader.luau' README.md
grep -Fq 'raw.githubusercontent.com/l3wisky/shindo-toolkit/dev/loader.dev.luau' README.md
grep -Fq 'raw.githubusercontent.com/l3wisky/shindo-toolkit/main/loader.luau' README.ru.md
grep -Fq 'raw.githubusercontent.com/l3wisky/shindo-toolkit/dev/loader.dev.luau' README.ru.md
grep -Fq "$rayfield_url" NOTICE
grep -Fq "SHA-256: ${rayfield_sha}" NOTICE
grep -Fq "Shindo Toolkit v${version}" dist/shindo-toolkit.luau
grep -Fq "Bundled dependency: Rayfield Gen2 ${rayfield_version} source under MPL-2.0:" \
    dist/shindo-toolkit.luau
grep -Fq 'https://www.mozilla.org/MPL/2.0/' dist/shindo-toolkit.luau

module_paths="$(
    grep -oE 'bootstrap\.load\("[^"]+' src/init.luau \
        | sed 's/^bootstrap\.load("//' \
        | LC_ALL=C sort -u
)"
while IFS= read -r module_path; do
    grep -Fq "["${module_path}"]" build/entry.luau
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
rayfield_license="vendor/rayfield-gen2/LICENSE"
rayfield_readme="vendor/rayfield-gen2/README.md"
third_party_notices="dist/THIRD_PARTY_NOTICES.txt"
grep -Fq "Rayfield Gen2 v${rayfield_version}" "$rayfield_vendor"
grep -Fq "$rayfield_sha" "$rayfield_readme"
grep -Fq 'Mozilla Public License Version 2.0' "$rayfield_license"
verify_sha256 "$rayfield_sha" "$rayfield_vendor"
luau-compile "$rayfield_vendor" > /dev/null

grep -Fq "SHA-256: ${rayfield_sha}" "$third_party_notices"
grep -Fq 'Mozilla Public License Version 2.0' "$third_party_notices"

rayfield_size="$(wc -c < "$rayfield_vendor" | tr -d '[:space:]')"
bundle_size="$(wc -c < dist/shindo-toolkit.luau | tr -d '[:space:]')"
notices_size="$(wc -c < "$third_party_notices" | tr -d '[:space:]')"
printf 'Verified Rayfield vendor (%s bytes), release bundle (%s bytes), and notices (%s bytes).\n' \
    "$rayfield_size" "$bundle_size" "$notices_size"
