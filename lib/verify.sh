#!/usr/bin/env bash

# ------------------------------------------------------------
# Verification
# ------------------------------------------------------------

verify_installation() {
    info "Verifying installed tools"

    local missing=()
    local command

    for command in \
        git \
        zsh \
        lazygit \
        yazi \
        zoxide \
        eza \
        btop \
        jq \
        starship \
        nvim \
        rg \
        make \
        node \
        go \
        helm \
        tree-sitter \
        npm
    do
        if command_exists "$command"; then
            ok "${command} -> $(command -v "$command")"
        else
            missing+=("$command")
        fi
    done

    if ! ghostty_available; then missing+=("Ghostty"); fi
    if command_exists node && ! node_version_ok; then missing+=("Node.js >= ${NODE_VERSION}"); fi
    if command_exists nvim && ! neovim_version_ok; then missing+=("Neovim >= 0.12"); fi

    if command_exists fd; then
        ok "fd -> $(command -v fd)"
    elif command_exists fdfind; then
        ok "fdfind -> $(command -v fdfind)"
    else
        missing+=("fd/fdfind")
    fi

    if ((${#missing[@]} > 0)); then
        warn "Missing tools: ${missing[*]}"
        return 1
    fi

    ok "All required tools are available"
}

print_next_steps() {
    printf '\n'
    printf '\033[1;36m--- Next steps ---\033[0m\n\n'

    printf '%s\n' \
        "1. Log out and log back in so the new default shell takes effect." \
        "2. Open Ghostty and verify that Lilex Nerd Font is rendered correctly." \
        "3. Test icons with:" \
        '   printf "\ue7a2 \uf113\n"' \
        "4. Verify your shell:" \
        '   echo "$SHELL"' \
        "5. Verify Neovim:" \
        '   nvim --version' \
        "6. Verify fd:" \
        '   fd --version' \
        "7. Open Neovim, run :Mason and wait for language tools to install." \
        "8. Run :checkhealth custom and :checkhealth vim.lsp." \
        "9. After Ghostty config changes: reload config, then reset font zoom."

    printf '\n'
}
