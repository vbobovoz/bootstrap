#!/bin/sh
# Run with isolated writable state; quick checks read existing plugin checkouts.
set -eu

check_mode=${1:-startup}
case "$check_mode" in
  lua|mason|workflow|startup|smoke|privacy|sessions|devops|selection|bootstrap) ;;
  *) printf 'Unknown check: %s\n' "$check_mode" >&2; exit 1 ;;
esac

check_dir=$(mktemp -d "${CHECK_ROOT:-${TMPDIR:-/tmp}/nvim-config-check}.XXXXXX")
trap 'rm -rf -- "$check_dir"' EXIT HUP INT TERM
mkdir -p "$check_dir/cache" "$check_dir/data/nvim" "$check_dir/state"

case "$check_mode" in
  lua|mason|workflow|selection) check_init=NONE ;;
  *) check_init=scripts/check-init.lua ;;
esac

check_config_home=$check_dir/config
mkdir -p "$check_config_home"
if [ "$check_mode" != bootstrap ]; then ln -s "$PWD" "$check_config_home/nvim"; fi
if [ "$check_mode" = bootstrap ]; then
  # vim.pack also writes its lockfile in the config directory. Deploy a copy so
  # even the explicit installation check cannot change the working lockfile.
  check_config_home=$check_dir/config
  mkdir -p "$check_config_home/nvim"
  cp -R init.lua lua ftplugin queries nvim-pack-lock.json "$check_config_home/nvim/"
fi

CUSTOM_NVIM_INSTALLED_SITE="${NVIM_DATA_HOME:-${XDG_DATA_HOME:-$HOME/.local/share}}/nvim/site" \
CUSTOM_NVIM_CHECK_MODE="$check_mode" \
XDG_CONFIG_HOME="$check_config_home" \
XDG_CACHE_HOME="$check_dir/cache" XDG_DATA_HOME="$check_dir/data" XDG_STATE_HOME="$check_dir/state" \
NVIM_LOG_FILE="$check_dir/nvim.log" \
"${NVIM_BIN:-nvim}" --headless -n -i NONE --cmd 'set shadafile=NONE' -u "$check_init" \
  '+lua if vim.v.errmsg ~= "" then io.stderr:write(vim.v.errmsg .. "\n"); vim.cmd("cquit 1") end' \
  '+lua local mode = vim.env.CUSTOM_NVIM_CHECK_MODE; local scripts = { lua = "lua-check", mason = "mason-smoke", workflow = "workflow-smoke", sessions = "sessions-smoke", privacy = "privacy-smoke", devops = "devops-smoke", selection = "selection-smoke", smoke = "smoke" }; if mode == "selection" then vim.opt.runtimepath:prepend(vim.fn.getcwd()); require("custom.options") end; if scripts[mode] then dofile("scripts/" .. scripts[mode] .. ".lua") end' \
  '+qa!'
