#!/usr/bin/env bash

set -euo pipefail

TEST_ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
readonly TEST_ROOT

fail() {
    printf 'FAIL: %s\n' "$*" >&2
    exit 1
}

assert_eq() {
    local expected="$1"
    local actual="$2"
    local label="$3"

    [[ "$actual" == "$expected" ]] ||
        fail "${label}: expected '${expected}', got '${actual}'"
}

test_package_map() {
    # shellcheck source=../lib/package-map.sh
    source "${TEST_ROOT}/lib/package-map.sh"

    DISTRO_FAMILY="fedora"
    assert_eq "fd-find" "$(pkg_name fd)" "Fedora fd package"
    assert_eq $'gcc\ngcc-c++\nmake' "$(pkg_name build-tools)" "Fedora build tools"

    DISTRO_FAMILY="suse"
    assert_eq $'gcc\ngcc-c++\nmake' "$(pkg_name build-tools)" "openSUSE build tools"

    DISTRO_FAMILY="alpine"
    assert_eq "build-base" "$(pkg_name build-tools)" "Alpine build tools"
}

test_multi_package_resolution() {
    # shellcheck source=../lib/packages.sh
    source "${TEST_ROOT}/lib/packages.sh"

    local captured=""

    DISTRO_FAMILY="fedora"
    pkg_install_backend() {
        captured="$*"
    }

    pkg_install build-tools fd
    assert_eq "gcc gcc-c++ make fd-find" "$captured" "multi-package resolution"
}

test_failed_verification_is_fatal() {
    if (
        # shellcheck source=../install.sh
        source "${TEST_ROOT}/install.sh"

        info() { :; }
        ok() { :; }
        warn() { :; }
        detect_platform() { :; }
        load_package_manager() { :; }
        install_base() { :; }
        install_git() { :; }
        install_zsh() { :; }
        install_starship() { :; }
        install_fonts() { :; }
        install_lazygit() { :; }
        install_yazi() { :; }
        install_neovim() { :; }
        install_nvim_config() { :; }
        install_ghostty() { :; }
        verify_installation() { return 1; }
        print_next_steps() { :; }

        main
    ) >/dev/null 2>&1; then
        fail "installer returned success after failed verification"
    fi
}

test_no_remote_shell_pipes() {
    if rg -n --glob '*.sh' '(curl|wget)[^|]*[|][[:space:]]*(ba)?sh' "$TEST_ROOT"; then
        fail "found an unverified remote shell pipeline"
    fi
}

test_package_map
test_multi_package_resolution
test_failed_verification_is_fatal
test_no_remote_shell_pipes
bash "${TEST_ROOT}/tests/nvim-install.sh"
bash "${TEST_ROOT}/tests/platforms.sh"
bash "${TEST_ROOT}/tests/standalone.sh"

printf 'All tests passed\n'
