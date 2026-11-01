SHELL := /bin/sh

NVIM_BIN ?= nvim
NVIM_DATA_HOME ?= $(if $(XDG_DATA_HOME),$(XDG_DATA_HOME),$(HOME)/.local/share)
STYLUA ?= $(shell command -v stylua 2>/dev/null || printf '%s' '$(NVIM_DATA_HOME)/nvim/mason/bin/stylua')
CHECK_ROOT ?= $(if $(TMPDIR),$(TMPDIR),/tmp)/bootstrap-nvim-check
CHECK_MODES := lua mason workflow startup smoke privacy sessions devops selection bootstrap
CHECK_TARGETS := $(addsuffix -check,$(CHECK_MODES))

.PHONY: check format-check $(CHECK_TARGETS)

check: format-check $(filter-out bootstrap-check,$(CHECK_TARGETS))
	@printf 'All checks passed.\n'

format-check:
	@printf 'Checking StyLua formatting...\n'
	@test -x "$(STYLUA)" || { printf '%s\n' 'stylua is not installed in PATH or Mason.' >&2; exit 1; }
	@"$(STYLUA)" --check .

# Quick modes only read installed checkouts; bootstrap-check explicitly downloads.
$(CHECK_TARGETS): %-check:
	@printf 'Checking %s...\n' '$*'
	@NVIM_BIN="$(NVIM_BIN)" NVIM_DATA_HOME="$(NVIM_DATA_HOME)" CHECK_ROOT="$(CHECK_ROOT)" sh scripts/check.sh '$*'
