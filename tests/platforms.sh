#!/usr/bin/env bash
set -euo pipefail

TEST_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
source "${TEST_DIR}/install.sh"

fail() { printf 'FAIL: %s\n' "$*" >&2; exit 1; }

for version in 0.12.0 0.12.6 0.13.0 1.0.0; do
    version_at_least "$version" 0.12.0 || fail "version rejected: $version"
done
for version in '' unknown 0.11.9 0.9.0; do
    if version_at_least "$version" 0.12.0; then fail "version accepted: $version"; fi
done

(
    node() { printf '%s\n' v26.0.0; }
    if node_version_ok; then fail 'outdated Node accepted'; fi
    node() { printf '%s\n' v26.13.0; }
    node_version_ok || fail 'current Node rejected'
    node() { printf '%s\n' v27.0.0-alpha.0; }
    if node_version_ok; then fail 'alpha Node accepted as stable'; fi
)

(
    DISTRO_FAMILY=debian
    DISTRO=ubuntu
    VERSION_ID=26.04
    [[ "$(pkg_name 7zip)" == 7zip ]] || fail 'Ubuntu 26.04 archive package'
    VERSION_ID=24.04
    [[ "$(pkg_name 7zip)" == p7zip-full ]] || fail 'Ubuntu 24.04 archive package'
)

(
    uname() { printf '%s\n' Darwin; }
    detect_platform
    [[ "$PKG_MANAGER" == brew && "$DISTRO_FAMILY" == macos ]] || fail 'Darwin detection'
)

(
    called=''
    apply_config() { called="${called} $1"; }
    main --configs-only
    [[ "$called" == ' nvim ghostty zsh starship' ]] || fail 'config-only dispatch'
)

(
    called=''
    prepare_platform() { :; }
    pkg_update() { :; }
    pkg_install() { :; }
    install_neovim() { called="${called} package"; }
    install_nvim_config() { called="${called} config"; }
    install_base() { fail 'single-module install ran all packages'; }
    main --only neovim
    [[ "$called" == ' package config' ]] || fail 'single Neovim dispatch'
)

if (main --config unknown) >/dev/null 2>&1; then fail 'unknown config accepted'; fi
if (main --only unknown) >/dev/null 2>&1; then fail 'unknown module accepted'; fi
if (main --nvim-config-only extra) >/dev/null 2>&1; then fail 'extra arguments accepted'; fi

(
    DISTRO_FAMILY=macos
    installed=0
    configured=0
    ghostty_available() { ((installed == 1)); }
    install_ghostty_package() { installed=1; }
    install_ghostty_config() { configured=1; }
    configure_default_terminal() { :; }
    install_ghostty >/dev/null
    [[ "$configured" == 1 ]] || fail 'macOS Ghostty config skipped after app installation'
)

printf 'Platform and CLI tests passed\n'
