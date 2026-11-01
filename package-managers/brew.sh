#!/usr/bin/env bash

# ------------------------------------------------------------
# Homebrew backend
# ------------------------------------------------------------

ensure_brew() {
    if ! command_exists brew; then
        if [[ -x /opt/homebrew/bin/brew ]]; then
            eval "$(/opt/homebrew/bin/brew shellenv)"
        elif [[ -x /usr/local/bin/brew ]]; then
            eval "$(/usr/local/bin/brew shellenv)"
        fi
    fi
    if command_exists brew; then
        return 0
    fi

    die "Homebrew is not installed"
}

pkg_update() {
    ensure_brew

    info "Updating Homebrew"
    brew update
}

pkg_install_backend() {
    ensure_brew

    local packages=("$@")
    local missing=()
    local package

    for package in "${packages[@]}"; do
        if brew list --formula "$package" >/dev/null 2>&1; then
            ok "already installed: ${package}"
        else
            missing+=("$package")
        fi
    done

    if ((${#missing[@]} == 0)); then
        return 0
    fi

    info "Installing packages via Homebrew: ${missing[*]}"
    brew install "${missing[@]}"
}

pkg_install_cask() {
    ensure_brew

    local packages=("$@")
    local missing=()
    local package

    for package in "${packages[@]}"; do
        if brew list --cask "$package" >/dev/null 2>&1; then
            ok "already installed cask: ${package}"
        else
            missing+=("$package")
        fi
    done

    if ((${#missing[@]} == 0)); then
        return 0
    fi

    info "Installing Homebrew casks: ${missing[*]}"
    brew install --cask "${missing[@]}"
}
