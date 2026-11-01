-- Shared Snacks UI, picker, explorer, and utility setup.
-- Loaded first so other plugin modules can use the global Snacks API.

local util = require 'custom.util'
local gh = util.gh
local dashboard_startup_ms
local search_excludes = { '.git', '.idea', '.vscode', '.ruff_cache', '.venv', 'venv', 'node_modules' }

local header_path = vim.fn.stdpath 'config' .. '/lua/custom/headers/nvim.txt'
local dashboard_header = vim.fn.filereadable(header_path) == 1 and table.concat(vim.fn.readfile(header_path), '\n') or 'NVIM'

vim.pack.add { gh 'folke/snacks.nvim' }

require('snacks').setup {
  bigfile = {
    enabled = true,
    size = 2 * 1024 * 1024,
  },
  dashboard = {
    enabled = true,
    width = 54,
    pane_gap = 3,
    autokeys = '67890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ',
    preset = {
      keys = {
        { icon = ' ', key = 'o', desc = 'Open', action = '<leader>o' },
        { icon = ' ', key = 'f', desc = 'Find file', action = function() Snacks.picker.files() end },
        { icon = ' ', key = 'g', desc = 'Grep project', action = function() Snacks.picker.grep() end },
        { icon = ' ', key = 'p', desc = 'Projects', action = function() Snacks.picker.projects() end },
        {
          icon = ' ',
          key = 'c',
          desc = 'Neovim config',
          action = function() Snacks.picker.files { cwd = vim.fn.stdpath 'config' } end,
        },
        { icon = ' ', key = 'q', desc = 'Quit', action = '<cmd>qa<cr>' },
      },
    },
    sections = {
      {
        pane = 1,
        function()
          if vim.o.columns < 110 or vim.o.lines < 34 then return nil end
          return { text = dashboard_header, align = 'center' }
        end,
      },
      { pane = 2, section = 'keys', gap = 1, padding = 1 },
      {
        pane = 2,
        function() return require('custom.features.sessions').dashboard_items(5) end,
        icon = ' ',
        title = 'Sessions',
        key = 's',
        action = function() require('custom.features.sessions').pick_load() end,
        indent = 2,
        padding = 1,
      },
      {
        pane = 2,
        icon = ' ',
        title = 'Recent Files',
        section = 'recent_files',
        key = 'r',
        action = function() Snacks.picker.recent() end,
        limit = 5,
        indent = 2,
        padding = 1,
      },
      {
        pane = 2,
        function()
          if not dashboard_startup_ms then
            local started = tonumber(vim.g.custom_start_time_ns) or vim.uv.hrtime()
            dashboard_startup_ms = (vim.uv.hrtime() - started) / 1e6
          end
          return {
            align = 'center',
            text = {
              { '⚡ Neovim ready in ', hl = 'footer' },
              { string.format('%.1f ms', dashboard_startup_ms), hl = 'special' },
            },
          }
        end,
      },
    },
  },
  explorer = {
    enabled = true,
    replace_netrw = true,
    trash = true,
  },
  indent = {
    enabled = true,
    indent = { char = '▏' },
    scope = { char = '▎' },
  },
  input = { enabled = true },
  notifier = {
    enabled = true,
    timeout = 3000,
    top_down = true,
  },
  words = { enabled = true, debounce = 250, modes = { 'n', 'i' } },
  picker = {
    enabled = true,
    ui_select = true,

    layouts = {
      default = {
        layout = {
          box = 'horizontal',
          width = 0.95,
          height = 0.9,
          {
            box = 'vertical',
            border = 'rounded',
            title = '{title}',
            title_pos = 'center',
            { win = 'input', height = 1, border = 'bottom' },
            { win = 'list', border = 'none' },
          },
          { win = 'preview', width = 0.7, border = 'rounded' },
        },
      },
    },
    sources = {
      files = {
        exclude = search_excludes,
      },
      grep = {
        exclude = search_excludes,
        regex = false,
      },
      explorer = {
        exclude = {
          '.git',
          '.idea',
          '.vscode',
          '.ruff_cache',
        },
        win = {
          list = {
            keys = {
              ['\\'] = 'close',
            },
          },
        },
      },
      projects = {
        patterns = util.project_markers,
        confirm = { 'tcd', 'picker_files' },
      },
    },
  },
  terminal = {
    shell = vim.o.shell,
    win = {
      wo = {
        winbar = '',
      },
    },
  },
}

local function map(lhs, rhs, desc, mode) vim.keymap.set(mode or 'n', lhs, rhs, { desc = desc }) end

map('<leader>fH', function() Snacks.picker.help() end, '[F]ind [H]elp')
map('<leader>fk', function() Snacks.picker.keymaps() end, '[F]ind [K]eymaps')
map('<leader>ff', function() Snacks.picker.files() end, '[F]ind [F]iles')
map('<leader>fs', function() Snacks.picker.pickers() end, '[F]ind pickers')
map('<leader>fw', function() Snacks.picker.grep_word() end, '[F]ind current [W]ord')
map('<leader>fw', function()
  Snacks.picker.grep {
    live = false,
    search = function(picker) return picker:word() end,
  }
end, '[F]ind selected text', 'x')
map('<leader>fg', function() Snacks.picker.grep() end, '[F]ind by [G]rep (project)')
map('<leader>fd', function() Snacks.picker.diagnostics() end, '[F]ind [D]iagnostics')
map('<leader>fr', function() Snacks.picker.resume() end, '[F]ind [R]esume last picker')
map('<leader>fh', function() Snacks.picker.search_history() end, '[F]ind search [H]istory')
map('<leader>f.', function() Snacks.picker.recent { filter = { cwd = true } } end, '[F]ind Recent Files (project)')
map('<leader>fc', function() Snacks.picker.commands() end, '[F]ind [C]ommands')
map('<leader>fb', function() Snacks.picker.buffers() end, '[ ] Find existing buffers')
map('<leader>fp', function() Snacks.picker.projects() end, '[F]ind recent [P]rojects')
map('<leader>/', function() Snacks.picker.lines() end, '[/] Search in current buffer')
map('<leader>f/', function() Snacks.picker.grep_buffers() end, '[F]ind in open buffers')
map('<leader>fn', function() Snacks.picker.files { cwd = vim.fn.stdpath 'config' } end, '[F]ind [N]eovim files')
map('<leader>m', function() Snacks.dashboard.open() end, '[M]ain [M]enu')

map('<leader>b', function() Snacks.picker.buffers() end, 'Buffers')
map('L', '<cmd>bnext<CR>', 'Next buffer')
map('H', '<cmd>bprevious<CR>', 'Previous buffer')
map('<leader>c', function() Snacks.bufdelete() end, '[C]lose Buffer')
map('<leader>C', function()
  local current = vim.api.nvim_get_current_buf()
  for _, buf in ipairs(vim.api.nvim_list_bufs()) do
    if buf ~= current and vim.api.nvim_buf_is_loaded(buf) and vim.bo[buf].buftype == '' then Snacks.bufdelete(buf) end
  end
end, '[C]lose other file buffers')

map('\\', function()
  local explorer = (Snacks.picker.get { source = 'explorer' })[1]
  if explorer then
    explorer:close()
  else
    Snacks.explorer.reveal()
  end
end, 'Toggle Explorer')

map('gd', function() Snacks.picker.lsp_definitions() end, '[G]oto [D]efinition')
map('gr', function() Snacks.picker.lsp_references() end, '[G]oto [R]eferences')
