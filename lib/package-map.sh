#!/usr/bin/env bash

# ------------------------------------------------------------
# Package map
# ------------------------------------------------------------
#
# Modules use logical package names.
# This function resolves them to real package names for the
# current distro family.
#
# If a package has the same name everywhere, it is returned
# unchanged.
#

pkg_name() {
    local package="$1"

    case "$package" in

        # ----------------------------------------------------
        # Archive tools
        # ----------------------------------------------------

        7zip)
            case "$DISTRO_FAMILY" in
                debian)
                    if [[ "${DISTRO:-}" == ubuntu && "${VERSION_ID:-}" == 26.04 ]]; then
                        printf '%s\n' "7zip"
                    else
                        printf '%s\n' "p7zip-full"
                    fi
                    ;;
                arch)   printf '%s\n' "7zip" ;;
                macos)  printf '%s\n' "p7zip" ;;
                *)      printf '%s\n' "7zip" ;;
            esac
            ;;

        # ----------------------------------------------------
        # Poppler
        # ----------------------------------------------------

        poppler)
            case "$DISTRO_FAMILY" in
                debian) printf '%s\n' "poppler-utils" ;;
                *)      printf '%s\n' "poppler" ;;
            esac
            ;;

        # ----------------------------------------------------
        # fd
        # ----------------------------------------------------

        fd)
            case "$DISTRO_FAMILY" in
                debian) printf '%s\n' "fd-find" ;;
                fedora) printf '%s\n' "fd-find" ;;
                *)      printf '%s\n' "fd" ;;
            esac
            ;;

        # ----------------------------------------------------
        # Build toolchain
        # ----------------------------------------------------

        build-tools)
            case "$DISTRO_FAMILY" in
                debian) printf '%s\n' "build-essential" ;;
                arch)   printf '%s\n' "base-devel" ;;
                alpine) printf '%s\n' "build-base" ;;
                fedora)
                    printf '%s\n' "gcc" "gcc-c++" "make"
                    ;;
                suse)
                    printf '%s\n' "gcc" "gcc-c++" "make"
                    ;;
                macos)  printf '%s\n' "make" ;;
                *)      printf '%s\n' "make" ;;
            esac
            ;;

        # ----------------------------------------------------
        # Node.js
        # ----------------------------------------------------

        nodejs)
            case "$DISTRO_FAMILY" in
                macos) printf '%s\n' "node" ;;
                *)     printf '%s\n' "nodejs" ;;
            esac
            ;;

        # ----------------------------------------------------
        # Default
        # ----------------------------------------------------

        *)
            printf '%s\n' "$package"
            ;;
    esac
}
