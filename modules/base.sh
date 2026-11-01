#!/usr/bin/env bash

install_base() {
    info "Installing base system packages"

    pkg_update

    pkg_install \
        git \
        curl \
        ca-certificates \
        unzip \
        fontconfig \
        zoxide \
        eza \
        btop \
        jq \
        ddgr \
        ffmpegthumbnailer \
        poppler \
        imagemagick \
        7zip \
        fzf

    ok "Base system packages installed"
}
