#!/usr/bin/env bash

# ------------------------------------------------------------
# Starship
# ------------------------------------------------------------

readonly STARSHIP_VERSION="1.26.0"

install_starship() {
    info "Installing and configuring Starship"

    if command_exists starship; then
        ok "already installed: starship"
    else
        install_starship_binary
    fi

    install_starship_config

    ok "Starship configured"
}

install_starship_binary() {
    case "$DISTRO_FAMILY" in
        arch|macos)
            pkg_install starship
            ;;

        debian)
            install_starship_debian
            ;;

        *)
            install_starship_official
            ;;
    esac
}

install_starship_debian() {
    if apt-cache show starship >/dev/null 2>&1; then
        pkg_install starship
        return 0
    fi

    warn "Starship package is not available in the current APT repositories"
    install_starship_official
}

install_starship_official() {
    local arch
    local checksum
    local target
    local tmp
    local url

    arch="$(uname -m)"

    case "$arch" in
        x86_64)
            target="x86_64-unknown-linux-musl"
            checksum="b7c232b0e8249d8e55a40beb79c5c43a7d370f3f9408bd215deb0170daeaadf3"
            ;;
        aarch64|arm64)
            target="aarch64-unknown-linux-musl"
            checksum="dc30189378d2f2e287384e8a692d3f95ad1df64cf0e8c36aa9201516028aed6b"
            ;;
        *)
            die "Unsupported architecture for Starship: ${arch}"
            ;;
    esac

    command_exists curl || die "curl is required to install Starship"
    command_exists tar || die "tar is required to install Starship"
    command_exists sha256sum || die "sha256sum is required to verify Starship"

    tmp="$(mktemp -d)"
    url="https://github.com/starship/starship/releases/download/v${STARSHIP_VERSION}/starship-${target}.tar.gz"

    info "Downloading Starship ${STARSHIP_VERSION}"

    curl -fsSL -o "${tmp}/starship.tar.gz" "$url"

    if ! printf '%s  %s\n' \
        "$checksum" \
        "${tmp}/starship.tar.gz" \
        | sha256sum -c - >/dev/null; then

        rm -rf "$tmp"
        die "Checksum verification failed for Starship ${STARSHIP_VERSION}"
    fi

    tar -xzf "${tmp}/starship.tar.gz" -C "$tmp" starship
    run_sudo install -m 0755 "${tmp}/starship" /usr/local/bin/starship
    rm -rf "$tmp"

    ok "Installed Starship ${STARSHIP_VERSION}"
}

install_starship_config() {
    local source="${ROOT_DIR}/config/starship/starship.toml"
    local target="${XDG_CONFIG_HOME:-${HOME}/.config}/starship.toml"

    [[ -f "$source" ]] ||
        die "Starship config not found: ${source}"

    copy_file "$source" "$target"
}
