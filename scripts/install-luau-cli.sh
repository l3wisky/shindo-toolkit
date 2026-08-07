#!/usr/bin/env bash
set -euo pipefail

project_root="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
version="0.733"
destination="$project_root/.tools/luau-$version"

case "$(uname -s)" in
    Linux)
        asset="luau-ubuntu.zip"
        expected_sha="2f37bbe79a6389ea2304531e2b4bba333bd0c2076bdc90256dfe30ace16f3c03"
        ;;
    Darwin)
        asset="luau-macos.zip"
        expected_sha="9ae1e43068eb10e508e19a23c3a657b638aaf20c0c0b2179dbadde87148a5766"
        ;;
    MINGW* | MSYS* | CYGWIN*)
        asset="luau-windows.zip"
        expected_sha="af6ccdb2dba70469297aab6436f5e46a68943de62a035f875eb3c777c3894d2b"
        ;;
    *)
        printf 'Unsupported platform for the official Luau CLI archive: %s\n' "$(uname -s)" >&2
        exit 1
        ;;
esac

if [[ -x "$destination/luau" && -x "$destination/luau-analyze" && -x "$destination/luau-compile" ]]; then
    exit 0
fi
if [[ -x "$destination/luau.exe" && -x "$destination/luau-analyze.exe" && -x "$destination/luau-compile.exe" ]]; then
    exit 0
fi

mkdir -p "$project_root/.tools"
install_temp="$(mktemp -d "$project_root/.tools/.luau-$version.XXXXXX")"
archive="$install_temp/$asset"
cleanup() {
    rm -rf "$install_temp"
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
    "https://github.com/luau-lang/luau/releases/download/$version/$asset" \
    --output "$archive"

if command -v sha256sum > /dev/null 2>&1; then
    printf '%s  %s\n' "$expected_sha" "$archive" | sha256sum --check --strict
elif command -v shasum > /dev/null 2>&1; then
    actual_sha="$(shasum -a 256 "$archive" | cut -d ' ' -f 1)"
    if [[ "$actual_sha" != "$expected_sha" ]]; then
        printf 'Luau archive checksum mismatch: expected %s, got %s\n' "$expected_sha" "$actual_sha" >&2
        exit 1
    fi
else
    printf 'sha256sum or shasum is required to verify the Luau archive.\n' >&2
    exit 1
fi

unzip -q "$archive" -d "$install_temp/bin"
chmod +x "$install_temp/bin"/luau* 2>/dev/null || true

for executable in luau luau-analyze luau-compile; do
    if [[ ! -x "$install_temp/bin/$executable" && ! -x "$install_temp/bin/$executable.exe" ]]; then
        printf 'The official archive does not contain %s.\n' "$executable" >&2
        exit 1
    fi
done

rm -rf "$destination"
mv "$install_temp/bin" "$destination"
printf 'Installed Luau CLI %s in %s\n' "$version" "$destination"
