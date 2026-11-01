-- Lualine setup and status components.
-- Loaded by custom.plugins.ui.

local M = {}

local gh = require('custom.util').gh
local util = require 'custom.util'

vim.pack.add { gh 'nvim-lualine/lualine.nvim' }

-- Resolve against the file's project, even when another project owns the tab cwd.
function M.current_file_path()
  if vim.bo.buftype ~= '' then return '' end
  local path = vim.api.nvim_buf_get_name(0)
  if path == '' then return '' end
  local root = vim.fs.root(path, '.git') or util.project_root(path) or vim.fn.getcwd()
  return vim.fs.relpath(root, path) or vim.fn.fnamemodify(path, ':~')
end

function M.setup()
  require('lualine').setup {
    options = {
      theme = 'auto',

      section_separators = { left = '', right = '' },
      component_separators = { left = '', right = '' },

      icons_enabled = true,

      globalstatus = true,

      refresh = {
        statusline = 1000,
        tabline = 1000,
        winbar = 1000,
      },
    },

    sections = {
      -- ============================================================
      -- LEFT SIDE
      -- ============================================================
      lualine_a = {
        {
          'mode',
          color = { gui = 'bold' },
        },
      },

      lualine_b = {
        {
          function() return vim.fn.fnamemodify(vim.fn.getcwd(), ':t') end,
          icon = '📁',
          color = { fg = '#a292a3', gui = 'bold' },
        },
      },

      lualine_c = { 'branch', 'diff', 'diagnostics' },

      -- ============================================================
      -- RIGHT SIDE
      -- ============================================================
      lualine_x = { 'searchcount' },
      lualine_y = { 'progress' },
      lualine_z = {
        { function() return (M.current_file_path():gsub('%%', '%%%%')) end },
        'location',
      },
    },

    inactive_sections = {
      lualine_a = {},
      lualine_b = {},
      lualine_c = { 'filename' },
      lualine_x = { 'location' },
      lualine_y = {},
      lualine_z = {},
    },

    extensions = { 'quickfix' },
  }
end

return M
