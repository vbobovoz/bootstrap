#!/usr/bin/env bash

# ------------------------------------------------------------
# Ghostty
# ------------------------------------------------------------

readonly GHOSTTY_UBUNTU_VERSION="1.3.1-0.ppa2"
readonly GHOSTTY_UBUNTU_RELEASE="1.3.1-0-ppa2"

ghostty_available() {
    command_exists ghostty && return 0
    [[ "$DISTRO_FAMILY" == macos ]] || return 1
    [[ -x /Applications/Ghostty.app/Contents/MacOS/ghostty ]] && return 0
    command_exists brew && brew list --cask ghostty >/dev/null 2>&1
}

install_ghostty() {
    info "Installing and configuring Ghostty"

    if ghostty_available; then
        ok "already installed: ghostty"
    else
        install_ghostty_package
    fi

    if ghostty_available; then
        install_ghostty_config
        configure_default_terminal
        ok "Ghostty configured"
    else
        warn "Ghostty is not installed; skipping configuration"
    fi
}

install_ghostty_package() {
    case "$DISTRO_FAMILY" in
        arch)
            pkg_install ghostty
            ;;

        macos)
            pkg_install_cask ghostty
            ;;

        debian)
            install_ghostty_debian
            ;;

        *)
            warn "Automatic Ghostty installation is not implemented for ${DISTRO_FAMILY}"
            return 0
            ;;
    esac
}

install_ghostty_debian() {
    if [[ "$DISTRO" != "ubuntu" ]]; then
        warn "Automatic Ghostty installation is currently supported only for Ubuntu"
        return 0
    fi

    if [[ -r /etc/os-release ]]; then
        # shellcheck disable=SC1091
        source /etc/os-release
    fi

    if command_exists dpkg &&
        dpkg --compare-versions "${VERSION_ID:-0}" ge "26.04"; then

        info "Installing Ghostty from Ubuntu repository"
        pkg_install ghostty
        return 0
    fi

    install_ghostty_ubuntu_release

    if ! command_exists ghostty; then
        warn "Ghostty installation did not succeed"
        return 0
    fi

    ok "Ghostty installed"
}

install_ghostty_ubuntu_release() {
    local arch
    local checksum
    local filename
    local release_target
    local tmp
    local url

    case "${VERSION_ID:-}" in
        24.04|25.10)
            release_target="${VERSION_ID}"
            ;;
        *)
            warn "No verified Ghostty package is available for Ubuntu ${VERSION_ID:-unknown}"
            return 0
            ;;
    esac

    arch="$(dpkg --print-architecture)"

    case "${arch}:${release_target}" in
        amd64:24.04)
            checksum="478d440153ef544426418efc7d6d8901715359f452c46be29071901a94b8cd47"
            ;;
        amd64:25.10)
            checksum="793bde1c31163d8e1d12ea939c8b941f7908170e57bbf19b121434a0f6621c59"
            ;;
        arm64:24.04)
            checksum="91063815b6ce3d834d59714b4ad0310f744448b6716836d035b3d331d1923363"
            ;;
        arm64:25.10)
            checksum="c6a4fd4fd786b4bdea42036650ef1724f535c4b636329f488f7ece36820d3d6b"
            ;;
        *)
            warn "No verified Ghostty package is available for ${arch} on Ubuntu ${release_target}"
            return 0
            ;;
    esac

    command_exists curl || die "curl is required to install Ghostty"
    command_exists sha256sum || die "sha256sum is required to verify Ghostty"

    tmp="$(mktemp -d)"
    filename="ghostty_${GHOSTTY_UBUNTU_VERSION}_${arch}_${release_target}.deb"
    url="https://github.com/mkasberg/ghostty-ubuntu/releases/download/${GHOSTTY_UBUNTU_RELEASE}/${filename}"

    info "Downloading verified Ghostty ${GHOSTTY_UBUNTU_VERSION} package"
    curl -fsSL -o "${tmp}/${filename}" "$url"

    if ! printf '%s  %s\n' \
        "$checksum" \
        "${tmp}/${filename}" \
        | sha256sum -c - >/dev/null; then

        rm -rf "$tmp"
        die "Checksum verification failed for Ghostty ${GHOSTTY_UBUNTU_VERSION}"
    fi

    run_sudo apt-get install -y "${tmp}/${filename}"
    rm -rf "$tmp"
}

install_ghostty_config() {
    local source="${ROOT_DIR}/config/ghostty/config"
    local target="${XDG_CONFIG_HOME:-${HOME}/.config}/ghostty/config"

    [[ -f "$source" ]] ||
        die "Ghostty config not found: ${source}"

    copy_file "$source" "$target"
}

configure_default_terminal() {
    case "$DISTRO_FAMILY" in
        macos)
            return 0
            ;;

        *)
            configure_default_terminal_linux
            ;;
    esac
}

configure_default_terminal_linux() {
    local source="${ROOT_DIR}/config/ghostty/xdg-terminals.list"
    local target="${XDG_CONFIG_HOME:-${HOME}/.config}/xdg-terminals.list"

    if [[ -f "$source" ]]; then
        copy_file "$source" "$target"
    else
        warn "XDG terminal config not found: ${source}"
    fi

    if [[ "$DISTRO_FAMILY" == "arch" ]] && command_exists omarchy; then
        info "Setting Ghostty as Omarchy default terminal"

        if omarchy default terminal ghostty; then
            ok "Ghostty is now the Omarchy default terminal"
        else
            warn "Unable to set Ghostty through Omarchy CLI"
        fi

        return 0
    fi

    if [[ "$DISTRO_FAMILY" == "debian" ]] &&
        command_exists update-alternatives; then

        configure_debian_terminal_alternative
    fi
}

configure_debian_terminal_alternative() {
    local ghostty_path
    ghostty_path="$(command -v ghostty)"

    [[ -n "$ghostty_path" ]] || return 0

    if update-alternatives \
        --query x-terminal-emulator 2>/dev/null \
        | grep -F "Alternative: ${ghostty_path}" >/dev/null; then

        run_sudo update-alternatives \
            --set x-terminal-emulator \
            "$ghostty_path"

        ok "Ghostty set as x-terminal-emulator"
    else
        run_sudo update-alternatives \
            --install /usr/bin/x-terminal-emulator x-terminal-emulator "$ghostty_path" 50
        run_sudo update-alternatives --set x-terminal-emulator "$ghostty_path"
        ok "Ghostty registered as x-terminal-emulator"
    fi
}
