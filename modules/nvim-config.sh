#!/usr/bin/env bash

# Bootstrap owns this configuration; no private GitLab access is required.
install_nvim_config() {
    local source="${ROOT_DIR}/config/nvim"
    local target="${XDG_CONFIG_HOME:-${HOME}/.config}/nvim"
    local staging
    local backup

    [[ -f "${source}/init.lua" ]] || die "Neovim config not found: ${source}"

    if [[ -d "$target" && ! -L "$target" ]] && diff -qr "$source" "$target" >/dev/null 2>&1; then
        ok "Neovim config is already up to date"
        return 0
    fi

    ensure_dir "$(dirname "$target")"
    staging="$(mktemp -d "${target}.tmp.XXXXXX")"
    if ! cp -R "${source}/." "$staging/"; then
        rm -rf "$staging"
        die "Unable to prepare Neovim configuration"
    fi

    if [[ -e "$target" || -L "$target" ]]; then
        backup="${target}.bak.$(date +%Y%m%d_%H%M%S)"
        while [[ -e "$backup" || -L "$backup" ]]; do backup="${backup}_"; done
        info "Backing up Neovim config -> ${backup}"
        if ! mv "$target" "$backup"; then
            rm -rf "$staging"
            die "Unable to back up Neovim configuration"
        fi
    fi

    if ! mv "$staging" "$target"; then
        [[ -z "${backup:-}" ]] || mv "$backup" "$target"
        rm -rf "$staging"
        die "Unable to install Neovim configuration"
    fi
    ok "Installed Neovim configuration from bootstrap"
}
