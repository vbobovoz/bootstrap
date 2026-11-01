#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
VERSION="${1:-24.04}"
case "$VERSION" in 24.04|26.04) ;; *) printf 'Expected Ubuntu 24.04 or 26.04\n' >&2; exit 1 ;; esac

args=(--rm --pull always -e DEBIAN_FRONTEND=noninteractive -e SHELL=/usr/bin/zsh)
args+=(--mount "type=bind,source=${ROOT},target=/repo,readonly")
if [[ -n "${BOOTSTRAP_TEST_PLATFORM:-}" ]]; then args+=(--platform "$BOOTSTRAP_TEST_PLATFORM"); fi

# No host HOME/config mounts. All packages and state stay inside the container.
docker run "${args[@]}" "ubuntu:${VERSION}" bash -c '
    set -e
    apt-get update
    apt-get install -y --no-install-recommends ca-certificates curl
    bash /repo/install.sh
    bash /repo/tests/run.sh
    ghostty +validate-config
    cd /repo
    nvim --headless -i NONE --cmd "set shadafile=NONE" "+lua vim.schedule(function() dofile(\"/repo/tests/nvim-integration.lua\") end)"
'
