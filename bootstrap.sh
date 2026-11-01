#!/usr/bin/env bash

set -euo pipefail

readonly REPO_OWNER="vbobovoz"
readonly REPO_NAME="bootstrap"
readonly REPO_BRANCH="main"

readonly ARCHIVE_URL="https://github.com/${REPO_OWNER}/${REPO_NAME}/archive/refs/heads/${REPO_BRANCH}.tar.gz"

TMP_DIR=""

cleanup() {
    if [[ -n "${TMP_DIR:-}" && -d "$TMP_DIR" ]]; then
        rm -rf "$TMP_DIR"
    fi
}

trap cleanup EXIT

main() {
    command -v curl >/dev/null 2>&1 || {
        printf 'error: curl is required\n' >&2
        exit 1
    }

    command -v tar >/dev/null 2>&1 || {
        printf 'error: tar is required\n' >&2
        exit 1
    }

    TMP_DIR="$(mktemp -d)"

    printf '==> Downloading bootstrap repository\n'

    curl -fsSL \
        "$ARCHIVE_URL" \
        -o "${TMP_DIR}/bootstrap.tar.gz"

    printf '==> Extracting bootstrap repository\n'

    tar -xzf \
        "${TMP_DIR}/bootstrap.tar.gz" \
        -C "$TMP_DIR"

    local repo_dir
    repo_dir="${TMP_DIR}/${REPO_NAME}-${REPO_BRANCH}"

    [[ -x "${repo_dir}/install.sh" ]] || {
        printf 'error: install.sh not found or not executable\n' >&2
        exit 1
    }

    printf '==> Starting installer\n'

    "${repo_dir}/install.sh" "$@"
}

main "$@"
