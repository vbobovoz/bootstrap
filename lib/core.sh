#!/usr/bin/env bash

# ------------------------------------------------------------
# Logging
# ------------------------------------------------------------

info() {
    printf '\033[1;34m==>\033[0m %s\n' "$*"
}

ok() {
    printf '\033[1;32mok\033[0m %s\n' "$*"
}

warn() {
    printf '\033[1;33mwarn\033[0m %s\n' "$*" >&2
}

die() {
    printf '\033[1;31merror\033[0m %s\n' "$*" >&2
    exit 1
}

# ------------------------------------------------------------
# Common helpers
# ------------------------------------------------------------

command_exists() {
    command -v "$1" >/dev/null 2>&1
}

run_sudo() {
    if [[ "$(id -u)" == 0 ]]; then
        "$@"
        return
    fi
    info "(sudo) $*"
    sudo "$@"
}

ensure_dir() {
    local dir="$1"

    if [[ ! -d "$dir" ]]; then
        mkdir -p "$dir"
    fi
}

backup_file() {
    local file="$1"

    [[ -e "$file" || -L "$file" ]] || return 0

    local backup
    backup="${file}.bak.$(date +%Y%m%d_%H%M%S)"
    while [[ -e "$backup" || -L "$backup" ]]; do backup="${backup}_"; done

    info "Backing up ${file} -> ${backup}"
    cp -a "$file" "$backup"
}

# Portable numeric comparison (also works in macOS Bash 3.2).
version_at_least() {
    local major minor patch expected_major expected_minor expected_patch
    IFS=. read -r major minor patch <<< "${1%%[-+]*}"
    IFS=. read -r expected_major expected_minor expected_patch <<< "${2%%[-+]*}"
    [[ "$major" =~ ^[0-9]+$ && "${minor:-0}" =~ ^[0-9]+$ && "${patch:-0}" =~ ^[0-9]+$ ]] || return 1
    if ((10#$major != 10#$expected_major)); then ((10#$major > 10#$expected_major))
    elif ((10#${minor:-0} != 10#${expected_minor:-0})); then ((10#${minor:-0} > 10#${expected_minor:-0}))
    else ((10#${patch:-0} >= 10#${expected_patch:-0})); fi
}

download_verified() {
    local url="$1" checksum="$2" target="$3"
    [[ "$checksum" =~ ^[0-9a-f]{64}$ ]] || die "Invalid SHA256 for ${url}"
    curl -fsSL --retry 3 -o "$target" "$url"
    printf '%s  %s\n' "$checksum" "$target" | sha256sum -c - >/dev/null || die "SHA256 mismatch: ${url}"
}

copy_file() {
    local source="$1"
    local target="$2"

    [[ -f "$source" ]] || die "Source file not found: ${source}"

    ensure_dir "$(dirname "$target")"

    if [[ -f "$target" ]] && ! [[ -L "$target" ]] && cmp -s "$source" "$target"; then
        ok "already up to date: ${target}"
        return 0
    fi

    if [[ -e "$target" || -L "$target" ]]; then
        backup_file "$target"
        rm -rf "$target"
    fi

    cp "$source" "$target"

    ok "installed: ${target}"
}
