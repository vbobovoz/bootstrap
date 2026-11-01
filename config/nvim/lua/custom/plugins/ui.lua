-- Coordinates the colorscheme, bufferline, and statusline.
-- Loaded first by custom.plugins.init.

local gh = require('custom.util').gh

vim.pack.add {
  gh 'akinsho/bufferline.nvim',
  gh 'nvim-mini/mini.nvim',
}
if vim.g.have_nerd_font then vim.pack.add { gh 'nvim-tree/nvim-web-devicons' } end

vim.pack.add { gh 'rebelot/kanagawa.nvim' }
require('kanagawa').setup {
  theme = 'wave',
  background = { dark = 'wave', light = 'lotus' },
  colors = {
    theme = {
      wave = { ui = { bg = '#16161d', bg_gutter = '#16161d' } },
    },
  },
  commentStyle = { italic = false },
  keywordStyle = { italic = false },
  overrides = function(colors)
    local palette = colors.palette
    return {
      RainbowDelimiterRed = { fg = palette.autumnRed },
      RainbowDelimiterYellow = { fg = palette.carpYellow },
      RainbowDelimiterBlue = { fg = palette.crystalBlue },
      RainbowDelimiterOrange = { fg = palette.surimiOrange },
      RainbowDelimiterGreen = { fg = palette.springGreen },
      RainbowDelimiterViolet = { fg = palette.oniViolet },
      RainbowDelimiterCyan = { fg = palette.waveAqua1 },
    }
  end,
}
vim.o.background = 'dark'
vim.cmd.colorscheme 'kanagawa-wave'

vim.api.nvim_set_hl(0, 'NormalFloat', { link = 'Normal' })
vim.api.nvim_set_hl(0, 'SnacksNormal', { link = 'Normal' })
vim.api.nvim_set_hl(0, 'SnacksNormalNC', { link = 'Normal' })
vim.api.nvim_set_hl(0, 'FloatBorder', { fg = '#5C6670', bg = 'NONE' })

require('custom.ui.bufferline').setup()
require('custom.ui.statusline').setup()
