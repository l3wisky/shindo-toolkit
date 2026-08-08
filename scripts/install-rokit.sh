#!/usr/bin/env bash
set -euo pipefail

project_root="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
source "$project_root/scripts/tool-versions.sh"

destination="$project_root/.tools/rokit-$ROKIT_VERSION"
system="$(uname -s)"
machine="$(uname -m)"

case "$system/$machine" in
    Linux/x86_64 | Linux/amd64)
        platform="linux"
        architecture="x86_64"
        expected_sha="951a7f3ec3d2a5e021fd1867d32f69f010ee4c2927f644b759578afc59c65fc0"
        ;;
    Linux/aarch64 | Linux/arm64)
        platform="linux"
        architecture="aarch64"
        expected_sha="b9ba200dd70620d9dbc11bbb0b368a62c6891328e6bc5fab4b7f68200089553a"
        ;;
    Darwin/x86_64 | Darwin/amd64)
        platform="macos"
        architecture="x86_64"
        expected_sha="9643ca30421e9c3dda1f4996bb03b3a43b08dfdc17c28198843e2233e446ba10"
        ;;
    Darwin/arm64 | Darwin/aarch64)
        platform="macos"
        architecture="aarch64"
        expected_sha="eb8e6b4f8026db2b80ad0887c50f342958ecdbacbdeda2fd6028b3c4f774a3ee"
        ;;
    MINGW*/x86_64 | MSYS*/x86_64 | CYGWIN*/x86_64)
        platform="windows"
        architecture="x86_64"
        expected_sha="f9ba1704014ff67d51e8005f605955c7c26d2429a5312a9419dc477fc310e96d"
        ;;
    MINGW*/arm64 | MSYS*/arm64 | CYGWIN*/arm64 | MINGW*/aarch64 | MSYS*/aarch64 | CYGWIN*/aarch64)
        platform="windows"
        architecture="aarch64"
        expected_sha="aff0e76e304fdc938cffa5b7ee1e183a052acac541868b4271192f20c734282a"
        ;;
    *)
        printf 'Unsupported platform for Rokit: %s %s\n' "$system" "$machine" >&2
        exit 1
        ;;
esac

binary="rokit"
if [[ "$platform" == "windows" ]]; then
    binary="rokit.exe"
fi
if [[ -x "$destination/$binary" ]]; then
    exit 0
fi

asset="rokit-$ROKIT_VERSION-$platform-$architecture.zip"
mkdir -p "$project_root/.tools"
install_temp="$(mktemp -d "$project_root/.tools/.rokit-$ROKIT_VERSION.XXXXXX")"
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
    "https://github.com/rojo-rbx/rokit/releases/download/v$ROKIT_VERSION/$asset" \
    --output "$archive"

if command -v sha256sum > /dev/null 2>&1; then
    printf '%s  %s\n' "$expected_sha" "$archive" | sha256sum --check --strict
elif command -v shasum > /dev/null 2>&1; then
    actual_sha="$(shasum -a 256 "$archive" | cut -d ' ' -f 1)"
    if [[ "$actual_sha" != "$expected_sha" ]]; then
        printf 'Rokit archive checksum mismatch: expected %s, got %s\n' \
            "$expected_sha" "$actual_sha" >&2
        exit 1
    fi
else
    printf 'sha256sum or shasum is required to verify the Rokit archive.\n' >&2
    exit 1
fi

mkdir "$install_temp/bin"
unzip -q "$archive" -d "$install_temp/bin"
chmod +x "$install_temp/bin/$binary" 2>/dev/null || true
if [[ ! -x "$install_temp/bin/$binary" ]]; then
    printf 'The official archive does not contain %s.\n' "$binary" >&2
    exit 1
fi

rm -rf "$destination"
mv "$install_temp/bin" "$destination"
printf 'Installed Rokit %s in %s\n' "$ROKIT_VERSION" "$destination"
