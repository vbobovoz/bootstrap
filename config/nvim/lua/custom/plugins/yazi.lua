local gh = require('custom.util').gh

if vim.fn.executable 'yazi' == 0 then return end

vim.pack.add({
  gh 'nvim-lua/plenary.nvim',
  gh 'mikavilpas/yazi.nvim',
}, { load = false })

local configured = false
local function open_yazi()
  if not configured then
    configured = true
    pcall(vim.cmd.packadd, 'plenary.nvim')
    pcall(vim.cmd.packadd, 'yazi.nvim')

    require('yazi').setup {
      open_for_directories = false,
      floating_window_scaling_factor = 0.9,
      yazi_floating_window_winblend = 0,
      integrations = {
        grep_in_directory = 'snacks.picker',
        grep_in_selected_files = 'snacks.picker',
      },
    }
  end
  require('yazi').yazi()
end

vim.keymap.set('n', '<leader>o', open_yazi, {
  desc = '[O]pen file or directory',
})
