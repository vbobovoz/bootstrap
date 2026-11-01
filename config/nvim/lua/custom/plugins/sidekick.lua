-- AI agent integration for Neovim via sidekick.nvim.
-- Provides a toggleable terminal for CLI agents (Claude Code, Codex) and keymaps to send editor context to them.

local gh = require('custom.util').gh

vim.pack.add({ gh 'folke/sidekick.nvim' }, { load = function() end })

local cli
local function sidekick_cli()
  if cli then return cli end

  vim.cmd.packadd 'sidekick.nvim'
  require('sidekick').setup {
    nes = { enabled = false },
    cli = {
      prompts = {
        refactor = 'Refactor {this} to be more readable and maintainable. Keep behavior unchanged.',
        review = 'Review {file} for bugs, edge cases and security issues. Be concise.',
        docs = 'Add documentation comments to {this}.',
        mr_desc = 'Write a pull request description',
      },
    },
  }
  cli = require 'sidekick.cli'
  return cli
end

vim.keymap.set({ 'n', 't' }, '<leader>aa', function() sidekick_cli().toggle() end, { desc = 'Toggle AI CLI' })
vim.keymap.set('n', '<leader>as', function() sidekick_cli().select { filter = { installed = true } } end, { desc = 'Select AI CLI' })
vim.keymap.set('n', '<leader>ad', function() sidekick_cli().close() end, { desc = 'Detach AI session' })
vim.keymap.set({ 'n', 'x' }, '<leader>at', function() sidekick_cli().send { msg = '{this}' } end, { desc = 'Send selection or current item to AI' })
vim.keymap.set('n', '<leader>af', function() sidekick_cli().send { msg = '{file}' } end, { desc = 'Send file to AI' })
vim.keymap.set({ 'n', 'x' }, '<leader>ap', function() sidekick_cli().prompt() end, { desc = 'Select AI prompt' })
