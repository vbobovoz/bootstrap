-- General editing enhancements and which-key groups.

local gh = require('custom.util').gh

vim.pack.add { gh 'NMAC427/guess-indent.nvim' }
vim.cmd 'filetype plugin indent on'
require('guess-indent').setup {
  filetype_exclude = { 'netrw', 'tutor', 'bigfile', 'go', 'python', 'json' },
}

vim.pack.add { gh 'folke/which-key.nvim' }

vim.pack.add({ gh 'MeanderingProgrammer/render-markdown.nvim' }, { load = function() end })
vim.g.render_markdown_config = { latex = { enabled = false } }

require('which-key').setup {
  delay = 200,
  icons = { mappings = vim.g.have_nerd_font },
  spec = {
    { '<leader>f', group = 'Find', mode = { 'n', 'v' } },
    { '<leader>s', group = 'Sessions' },
    { '<leader>t', group = 'Tests' },
    { '<leader>g', group = 'Git' },
    { '<leader>a', group = 'AI' },
    { '<leader>u', group = 'Options' },
    { '<leader>l', group = 'LSP', mode = { 'n', 'x' } },
    { '<leader>j', group = 'Jump with Flash' },
  },
}

Snacks.toggle({
  name = 'Autosave on focus loss',
  get = function() return vim.g.custom_autosave ~= false end,
  set = function(state) vim.g.custom_autosave = state end,
}):map '<leader>ua'

Snacks.toggle({
  name = 'Format on save',
  get = function() return vim.g.custom_format_on_save ~= false end,
  set = function(state) vim.g.custom_format_on_save = state end,
}):map '<leader>uf'

Snacks.toggle.diagnostics({ name = 'Diagnostics (global)' }):map '<leader>ud'
Snacks.toggle({
  name = 'Diagnostic lines below cursor',
  get = function() return vim.diagnostic.config().virtual_lines ~= false end,
  set = function(state) vim.diagnostic.config { virtual_text = not state, virtual_lines = state and { current_line = true } or false } end,
}):map '<leader>uv'
Snacks.toggle.option('relativenumber', { name = 'Relative numbers (window)' }):map '<leader>ur'

Snacks.toggle({
  name = 'Treesitter context (global)',
  get = function() return require('treesitter-context').enabled() end,
  set = function(state) require('treesitter-context')[state and 'enable' or 'disable']() end,
}):map '<leader>uc'

Snacks.toggle({
  name = 'AI suggestions (buffer)',
  get = function() return vim.b.custom_inline_ai ~= false end,
  set = function(state)
    vim.b.custom_inline_ai = state
    local neo = package.loaded.neocodeium
    if not state and neo then neo.clear() end
  end,
}):map '<leader>un'

vim.api.nvim_create_autocmd('FileType', {
  group = vim.api.nvim_create_augroup('custom-markdown', { clear = true }),
  pattern = 'markdown',
  once = true,
  callback = function() vim.cmd.packadd 'render-markdown.nvim' end,
  desc = 'Load Markdown rendering on the first Markdown buffer',
})

vim.pack.add { gh 'folke/todo-comments.nvim' }
vim.schedule(function() require('todo-comments').setup { signs = false } end)
require('mini.ai').setup { mappings = { around_next = 'aa', inside_next = 'ii' }, n_lines = 500 }
require('mini.surround').setup()
require('mini.move').setup()
require('mini.jump').setup()
