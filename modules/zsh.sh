#!/usr/bin/env bash

# ------------------------------------------------------------
# Zsh
# ------------------------------------------------------------

install_zsh() {
    info "Installing and configuring Zsh"

    if ! command_exists zsh; then
        pkg_install zsh
    else
        ok "already installed: zsh"
    fi

    install_zsh_config
    set_default_shell_zsh

    ok "Zsh configured"
}

install_zsh_config() {
    local source="${ROOT_DIR}/config/zsh/.zshrc"
    local target="${ZDOTDIR:-${HOME}}/.zshrc"

    [[ -f "$source" ]] || die "Zsh config not found: ${source}"

    copy_file "$source" "$target"
}

set_default_shell_zsh() {
    local zsh_path
    zsh_path="$(command -v zsh)"

    [[ -n "$zsh_path" ]] || die "Unable to locate zsh binary"

    if [[ "${SHELL:-}" == "$zsh_path" ]]; then
        ok "Zsh is already the default shell"
        return 0
    fi

    if [[ -r /etc/shells ]] && ! grep -Fxq "$zsh_path" /etc/shells; then
        info "Adding ${zsh_path} to /etc/shells"
        printf '%s\n' "$zsh_path" | sudo tee -a /etc/shells >/dev/null
    fi

    info "Changing default shell to ${zsh_path}"

    chsh -s "$zsh_path"

    ok "Default shell changed to Zsh"
}
