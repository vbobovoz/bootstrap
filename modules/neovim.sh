#!/usr/bin/env bash

# ------------------------------------------------------------
# Neovim
# ------------------------------------------------------------

install_neovim() {
    info "Installing Neovim and dependencies"

    pkg_install build-tools ripgrep fd unzip curl wget ca-certificates
    if [[ "$DISTRO" == ubuntu ]]; then
        install_neovim_ubuntu
    else
        pkg_install neovim nodejs
    fi

    install_neovim_platform_extras
    ensure_fd_command
    hash -r
    if ! neovim_version_ok; then
        if [[ "$DISTRO_FAMILY" == macos ]]; then
            brew upgrade neovim
            hash -r
        fi
        neovim_version_ok || die "Neovim 0.12+ is required; check which nvim is first on PATH"
    fi
    ok "Neovim dependencies installed"
}

neovim_version_ok() {
    command_exists nvim || return 1
    local version
    version="$(nvim --version | sed -n '1s/^NVIM v//p')"
    version_at_least "$version" 0.12.0
}

install_neovim_ubuntu() {
    if neovim_version_ok; then
        ok "Neovim 0.12+ is already installed"
        return 0
    fi
    local arch checksum tmp target
    case "$(linux_tool_arch)" in
        amd64)
            arch=x86_64
            checksum="474430d53e6264f6d6dd18db42d6dc9df3a1b56ca9e88a325bbf860e1a811d87"
            ;;
        arm64)
            arch=arm64
            checksum="8f1f64a0bdb97247034038c3823c6cbad5bdf9ecd5751b85494b71c3ee04c815"
            ;;
    esac
    tmp="$(mktemp -d)"
    target=/opt/bootstrap/nvim-0.12.6
    download_verified "https://github.com/neovim/neovim/releases/download/v0.12.6/nvim-linux-${arch}.tar.gz" "$checksum" "$tmp/nvim.tar.gz"
    run_sudo mkdir -p "$target" /usr/local/bin
    run_sudo tar -xzf "$tmp/nvim.tar.gz" -C "$target" --strip-components=1
    run_sudo ln -sfn "$target/bin/nvim" /usr/local/bin/nvim
    rm -rf "$tmp"
    hash -r
}

install_neovim_platform_extras() {
    case "$DISTRO_FAMILY" in
        debian)
            pkg_install xclip wl-clipboard python3 python3-venv python3-pip
            if [[ "$DISTRO" == ubuntu ]]; then
                install_ubuntu_dev_tools
            else
                pkg_install npm
            fi
            ;;
        arch)
            pkg_install npm xclip wl-clipboard
            ;;

        alpine)
            # Alpine packages Node.js and npm separately.
            pkg_install npm
            ;;

        macos)
            install_node
            pkg_install_if_missing python3 python
            # npm comes with Homebrew's node package.
            # Go is needed by gopls/goimports; Helm enables chart linting.
            pkg_install_if_missing go go
            pkg_install_if_missing helm helm
            pkg_install_if_missing tree-sitter tree-sitter-cli
            ;;

        *)
            # We'll add distro-specific extras when support is verified.
            ;;
    esac
}

ensure_fd_command() {
    if command_exists fd; then
        ok "fd command available"
        return 0
    fi

    if ! command_exists fdfind; then
        warn "Neither fd nor fdfind is available"
        return 0
    fi

    # Debian/Ubuntu package fd-find installs the binary as "fdfind".
    if command_exists update-alternatives; then
        info "Registering fdfind as fd"

        run_sudo update-alternatives \
            --install /usr/local/bin/fd fd /usr/bin/fdfind 100 \
            || true

        run_sudo update-alternatives \
            --set fd /usr/bin/fdfind \
            || true
    fi

    if command_exists fd; then
        ok "fd command available"
    else
        warn "fdfind is installed, but fd alias could not be configured"
    fi
}
