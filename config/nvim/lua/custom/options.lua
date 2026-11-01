-- Core editor options and platform initialization.
-- Loaded first from init.lua so leaders and environment are ready for plugins.

vim.loader.enable()

local win = require 'custom.features.windows'
win.setup()
win.prepend_path({ vim.fs.joinpath(vim.fn.stdpath 'data', 'mason', 'bin') }, { only_existing = false })

if vim.fn.executable 'go' == 0 then
  local home = vim.env.HOME or vim.fn.expand '~'
  win.prepend_path { '/usr/local/go/bin', home .. '/go/bin', home .. '/.local/go/bin' }
end

vim.g.loaded_python3_provider = 0
vim.g.loaded_ruby_provider = 0
vim.g.loaded_perl_provider = 0
vim.g.loaded_node_provider = 0

vim.g.mapleader = ' '
vim.g.maplocalleader = ' '

vim.g.have_nerd_font = true

vim.o.termguicolors = true

vim.o.number = true
vim.o.relativenumber = true

vim.o.mouse = 'a'

-- Shift+arrows select text in Visual mode, where `y` keeps its copy action.
vim.o.keymodel = 'startsel,stopsel'
vim.o.selectmode = ''
vim.o.selection = 'exclusive'

vim.o.showmode = false

vim.schedule(function() vim.o.clipboard = 'unnamedplus' end)

vim.o.breakindent = true

vim.o.undofile = true

vim.o.ignorecase = true
vim.o.smartcase = true

vim.o.signcolumn = 'yes'

vim.o.updatetime = 250

vim.o.timeoutlen = 300

vim.o.splitright = true
vim.o.splitbelow = true

vim.o.list = true

vim.o.inccommand = 'split'

vim.o.cursorline = true

vim.o.scrolloff = 10

vim.o.confirm = true
