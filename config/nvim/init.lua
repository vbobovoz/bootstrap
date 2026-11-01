-- Neovim configuration entry point.
-- Loads core settings and plugin modules in dependency order.

vim.g.custom_start_time_ns = vim.uv.hrtime()

require 'custom.options'
require('custom.devops').setup()
require 'custom.keymaps'
require 'custom.autocmds'
require 'custom.pack'
require 'custom.plugins'

-- vim: ts=2 sts=2 sw=2 et
