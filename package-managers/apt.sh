#!/usr/bin/env bash

# ------------------------------------------------------------
# APT backend
# ------------------------------------------------------------

pkg_update() {
    info "Updating APT package index"
    run_sudo apt-get update
}

pkg_install_backend() {
    local packages=("$@")
    local missing=()
    local package

    for package in "${packages[@]}"; do
        if [[ "$(dpkg-query -W -f='${Status}' "$package" 2>/dev/null || true)" == 'install ok installed' ]]; then
            ok "already installed: ${package}"
        else
            missing+=("$package")
        fi
    done

    if ((${#missing[@]} == 0)); then
        return 0
    fi

    info "Installing packages via APT: ${missing[*]}"
    run_sudo apt-get install -y --no-install-recommends "${missing[@]}"
}
