#!/usr/bin/env bash

set -euo pipefail

ROOT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
readonly ROOT_DIR

# ------------------------------------------------------------
# Core
# ------------------------------------------------------------

source "${ROOT_DIR}/lib/core.sh"
source "${ROOT_DIR}/lib/detect.sh"
source "${ROOT_DIR}/lib/packages.sh"
source "${ROOT_DIR}/lib/package-map.sh"
source "${ROOT_DIR}/lib/verify.sh"

# ------------------------------------------------------------
# Modules
# ------------------------------------------------------------

source "${ROOT_DIR}/modules/base.sh"
source "${ROOT_DIR}/modules/dev-tools.sh"
source "${ROOT_DIR}/modules/git.sh"
source "${ROOT_DIR}/modules/zsh.sh"
source "${ROOT_DIR}/modules/starship.sh"
source "${ROOT_DIR}/modules/fonts.sh"
source "${ROOT_DIR}/modules/lazygit.sh"
source "${ROOT_DIR}/modules/yazi.sh"
source "${ROOT_DIR}/modules/neovim.sh"
source "${ROOT_DIR}/modules/nvim-config.sh"
source "${ROOT_DIR}/modules/ghostty.sh"

# ------------------------------------------------------------
# Entrypoint
# ------------------------------------------------------------

usage() {
    cat <<'HELP'
Usage: bash install.sh [OPTION]
  (no option)                 Install the complete environment
  --only MODULE               Install one module and its configuration
  --config NAME               Apply configuration only (no packages)
  --configs-only              Apply nvim, ghostty, zsh and starship configs
  --nvim-config-only          Alias for --config nvim
  --editor-config-only        Apply nvim and ghostty configs
  --check                     Verify installed tools without installing
  --help                      Show this help
Modules: base git zsh starship fonts lazygit yazi node neovim ghostty
Configs: nvim ghostty zsh starship git
HELP
}

apply_config() {
    case "$1" in
        nvim) install_nvim_config ;;
        ghostty) install_ghostty_config ;;
        zsh) install_zsh_config ;;
        starship) install_starship_config ;;
        git)
            command_exists git || die "Git is required; run --only git first"
            install_git
            ;;
        *) die "Unknown config: $1 (see --help)" ;;
    esac
}

prepare_platform() {
    detect_platform
    if [[ "$DISTRO" == ubuntu ]]; then
        case "${VERSION_ID:-}" in
            24.04|26.04) ;;
            *) die "Supported Ubuntu versions: 24.04 and 26.04 LTS" ;;
        esac
    fi
    if [[ "$DISTRO_FAMILY" == macos ]]; then
        xcode-select -p >/dev/null 2>&1 || die "Install Xcode Command Line Tools first: xcode-select --install"
    fi
    load_package_manager
}

install_single_module() {
    local module="$1"
    case "$module" in
        base|git|zsh|starship|fonts|lazygit|yazi|node|neovim|ghostty) ;;
        *) die "Unknown module: ${module} (see --help)" ;;
    esac
    prepare_platform
    if [[ "$module" != base ]]; then
        pkg_update
        pkg_install git curl ca-certificates unzip
    fi
    case "$module" in
        base) install_base ;;
        git) install_git ;;
        zsh) install_zsh ;;
        starship) install_starship ;;
        fonts) pkg_install fontconfig; install_fonts ;;
        lazygit) install_lazygit ;;
        yazi) install_yazi ;;
        node) install_node ;;
        neovim) install_neovim; install_nvim_config ;;
        ghostty) install_ghostty ;;
    esac
}

main() {
    case "${1:-}" in
        --help|-h) usage; return 0 ;;
        --config|--only)
            [[ $# -eq 2 ]] || die "Expected exactly one name after $1 (see --help)"
            if [[ "$1" == --config ]]; then apply_config "$2"
            else install_single_module "$2"; fi
            return 0
            ;;
        --configs-only)
            [[ $# -eq 1 ]] || die "Unexpected arguments (see --help)"
            apply_config nvim
            apply_config ghostty
            apply_config zsh
            apply_config starship
            return 0
            ;;
        --editor-config-only)
            [[ $# -eq 1 ]] || die "Unexpected arguments (see --help)"
            apply_config nvim
            apply_config ghostty
            return 0
            ;;
        --nvim-config-only)
            [[ $# -eq 1 ]] || die "Unexpected arguments (see --help)"
            apply_config nvim
            return 0
            ;;
        --check)
            [[ $# -eq 1 ]] || die "Unexpected arguments (see --help)"
            detect_platform
            verify_installation
            return
            ;;
        "") ;;
        *) die "Unknown option: $1 (see --help)" ;;
    esac

    info "Starting system bootstrap"

    prepare_platform

    info "Detected distro: ${DISTRO}"
    info "Distro family: ${DISTRO_FAMILY}"
    info "Package manager: ${PKG_MANAGER}"

    install_base
    install_git
    install_zsh
    install_starship
    install_fonts
    install_lazygit
    install_yazi
    install_neovim
    install_nvim_config
    install_ghostty

    printf '\n'

    verify_installation ||
        die "Installation verification failed"

    printf '\n'
    ok "System bootstrap complete"

    print_next_steps
}

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
    main "$@"
fi
