-- Label-based navigation loaded only when its mapping is used.
-- Standard search and f/t motions remain unchanged.

local gh = require('custom.util').gh

vim.pack.add({ gh 'folke/flash.nvim' }, { load = false })

local configured = false

local function jump()
  if not configured then
    vim.cmd.packadd 'flash.nvim'
    require('flash').setup {}
    configured = true
  end
  require('flash').jump()
end

vim.keymap.set({ 'n', 'x', 'o' }, '<leader>j', jump, { desc = '[J]ump with Flash' })
