local gh = require('custom.util').gh

local plugins = {
  gh 'nvim-neotest/nvim-nio',
  gh 'nvim-neotest/neotest',
  gh 'nvim-neotest/neotest-python',
  gh 'fredrikaverpil/neotest-golang',
}
vim.pack.add(plugins, { load = function() end })

local nt
local function neotest()
  if nt then return nt end

  vim.cmd.packadd 'plenary.nvim'
  vim.cmd.packadd 'nvim-nio'
  vim.cmd.packadd 'neotest'
  vim.cmd.packadd 'neotest-python'
  vim.cmd.packadd 'neotest-golang'

  local project = require 'custom.project'

  -- The pinned adapter calls base.get_root inside discovery and build_spec too.
  -- Set it before constructing the adapter so every path uses the shared rules.
  require('neotest-python.base').get_root = project.python_root

  nt = require 'neotest'
  nt.setup {
    adapters = {
      require 'neotest-python' {
        runner = 'pytest',
        python = function()
          local python = vim.fn.exepath 'python3'
          return { python ~= '' and python or 'python' }
        end,
      },
      require 'neotest-golang' {},
    },
  }
  return nt
end

local map = vim.keymap.set
map('n', '<leader>tn', function() neotest().run.run() end, { desc = 'Run nearest test' })
map('n', '<leader>tf', function() neotest().run.run(vim.fn.expand '%') end, { desc = 'Run tests in current file' })
map('n', '<leader>tl', function() neotest().run.run_last() end, { desc = 'Repeat last test run' })
map('n', '<leader>ts', function() neotest().summary.toggle() end, { desc = 'Toggle test summary' })
map('n', '<leader>to', function() neotest().output.open { enter = true } end, { desc = 'Open test output' })
