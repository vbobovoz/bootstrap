#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
SANDBOX="$(mktemp -d)"
trap 'rm -rf "$SANDBOX"' EXIT
export XDG_CONFIG_HOME="${SANDBOX}/config"

mkdir -p "${XDG_CONFIG_HOME}/nvim"
printf 'original config\n' > "${XDG_CONFIG_HOME}/nvim/original.txt"

bash "${ROOT}/install.sh" --nvim-config-only >/dev/null
diff -qr "${ROOT}/config/nvim" "${XDG_CONFIG_HOME}/nvim"
backups=("${XDG_CONFIG_HOME}"/nvim.bak.*)
[[ ${#backups[@]} -eq 1 && -f "${backups[0]}/original.txt" ]]

# Reapplying identical config must not create another backup.
bash "${ROOT}/install.sh" --nvim-config-only >/dev/null
backups=("${XDG_CONFIG_HOME}"/nvim.bak.*)
[[ ${#backups[@]} -eq 1 ]]

# Applying editor configs must also install Ghostty under XDG_CONFIG_HOME.
bash "${ROOT}/install.sh" --editor-config-only >/dev/null
cmp "${ROOT}/config/ghostty/config" "${XDG_CONFIG_HOME}/ghostty/config"

export ZDOTDIR="${SANDBOX}/zsh"
bash "${ROOT}/install.sh" --configs-only >/dev/null
cmp "${ROOT}/config/zsh/.zshrc" "${ZDOTDIR}/.zshrc"
cmp "${ROOT}/config/starship/starship.toml" "${XDG_CONFIG_HOME}/starship.toml"

export GIT_CONFIG_GLOBAL="${SANDBOX}/gitconfig"
git config --global user.name 'Fixture User'
bash "${ROOT}/install.sh" --config git >/dev/null
[[ "$(git config --global user.name)" == 'Fixture User' ]]
[[ "$(git config --global core.editor)" == nvim ]]
backups=("${GIT_CONFIG_GLOBAL}".bak.*)
[[ ${#backups[@]} -eq 1 ]]

# Broken links must be backed up without changing their destination.
export XDG_CONFIG_HOME="${SANDBOX}/symlink-config"
mkdir -p "$XDG_CONFIG_HOME"
ln -s "${SANDBOX}/missing" "${XDG_CONFIG_HOME}/nvim"
bash "${ROOT}/install.sh" --nvim-config-only >/dev/null
[[ -f "${XDG_CONFIG_HOME}/nvim/init.lua" ]]
backups=("${XDG_CONFIG_HOME}"/nvim.bak.*)
[[ ${#backups[@]} -eq 1 && -L "${backups[0]}" ]]
[[ ! -e "${SANDBOX}/missing" ]]
printf 'Neovim installation tests passed\n'
