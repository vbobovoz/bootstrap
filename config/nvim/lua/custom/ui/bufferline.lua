-- Bufferline setup and refresh helpers.
-- Loaded by custom.plugins.ui and session refresh hooks.

local M = {}

local function bufremove(bufnr) Snacks.bufdelete(bufnr) end

local opts = {
  options = {
    themable = false,
    indicator = { style = 'icon', icon = '▎' },
    separator_style = 'thin',
    close_command = bufremove,
    right_mouse_command = bufremove,
    color_icons = true,
    show_buffer_icons = true,
  },
  highlights = {
    buffer_selected = { bold = true },
  },
}

function M.refresh() vim.cmd.redrawtabline() end

function M.setup() require('bufferline').setup(opts) end

return M
