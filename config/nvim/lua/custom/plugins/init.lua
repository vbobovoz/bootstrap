-- Explicit plugin-module loading order.
-- Loaded from init.lua after vim.pack hooks are registered.

local gh = require('custom.util').gh
vim.pack.add({ gh 'nvim-lua/plenary.nvim' }, { load = function() end })

local modules = {
  'snacks',
  'ui',
  'editor',
  'flash',
  'workspace',
  'git',
  'sessions',
  'lsp',
  'formatting',
  'lint',
  'inline',
  'completion',
  'treesitter',
  'autopairs',
  'yazi',
  'sidekick',
  'neotest',
}

for _, module in ipairs(modules) do
  require('custom.plugins.' .. module)
end
