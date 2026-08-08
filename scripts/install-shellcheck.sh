#!/usr/bin/env bash
set -euo pipefail

project_root="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
source "$project_root/scripts/tool-versions.sh"
version="$SHELLCHECK_VERSION"
destination="$project_root/.tools/shellcheck-$version"
system="$(uname -s)"
machine="$(uname -m)"

case "$system/$machine" in
    Linux/x86_64 | Linux/amd64)
        asset="shellcheck-v$version.linux.x86_64.tar.xz"
        expected_sha="8c3be12b05d5c177a04c29e3c78ce89ac86f1595681cab149b65b97c4e227198"
        ;;
    Linux/aarch64 | Linux/arm64)
        asset="shellcheck-v$version.linux.aarch64.tar.xz"
        expected_sha="12b331c1d2db6b9eb13cfca64306b1b157a86eb69db83023e261eaa7e7c14588"
        ;;
    Darwin/x86_64 | Darwin/amd64)
        asset="shellcheck-v$version.darwin.x86_64.tar.xz"
        expected_sha="3c89db4edcab7cf1c27bff178882e0f6f27f7afdf54e859fa041fca10febe4c6"
        ;;
    Darwin/arm64 | Darwin/aarch64)
        asset="shellcheck-v$version.darwin.aarch64.tar.xz"
        expected_sha="56affdd8de5527894dca6dc3d7e0a99a873b0f004d7aabc30ae407d3f48b0a79"
        ;;
    MINGW*/x86_64 | MSYS*/x86_64 | CYGWIN*/x86_64)
        asset="shellcheck-v$version.zip"
        expected_sha="8a4e35ab0b331c85d73567b12f2a444df187f483e5079ceffa6bda1faa2e740e"
        ;;
    *)
        printf 'Unsupported platform for ShellCheck: %s %s\n' "$system" "$machine" >&2
        exit 1
        ;;
esac

if [[ -x "$destination/shellcheck" || -x "$destination/shellcheck.exe" ]]; then
    exit 0
fi

mkdir -p "$project_root/.tools"
install_temp="$(mktemp -d "$project_root/.tools/.shellcheck-$version.XXXXXX")"
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
    "https://github.com/koalaman/shellcheck/releases/download/v$version/$asset" \
    --output "$archive"

if command -v sha256sum > /dev/null 2>&1; then
    printf '%s  %s\n' "$expected_sha" "$archive" | sha256sum --check --strict
elif command -v shasum > /dev/null 2>&1; then
    actual_sha="$(shasum -a 256 "$archive" | cut -d ' ' -f 1)"
    if [[ "$actual_sha" != "$expected_sha" ]]; then
        printf 'ShellCheck archive checksum mismatch: expected %s, got %s\n' "$expected_sha" "$actual_sha" >&2
        exit 1
    fi
else
    printf 'sha256sum or shasum is required to verify the ShellCheck archive.\n' >&2
    exit 1
fi

mkdir "$install_temp/bin"
case "$asset" in
    *.tar.xz)
        tar -xJf "$archive" -C "$install_temp"
        mv "$install_temp/shellcheck-v$version/shellcheck" "$install_temp/bin/shellcheck"
        ;;
    *.zip)
        unzip -q "$archive" -d "$install_temp/bin"
        ;;
esac
chmod +x "$install_temp/bin"/shellcheck* 2>/dev/null || true

if [[ ! -x "$install_temp/bin/shellcheck" && ! -x "$install_temp/bin/shellcheck.exe" ]]; then
    printf 'The official archive does not contain ShellCheck.\n' >&2
    exit 1
fi

rm -rf "$destination"
mv "$install_temp/bin" "$destination"
printf 'Installed ShellCheck %s in %s\n' "$version" "$destination"
