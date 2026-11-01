-- LazyGit via Snacks and Gitsigns buffer mappings.
-- Loaded by custom.plugins.init.

local gh = require('custom.util').gh

vim.pack.add {
  gh 'lewis6991/gitsigns.nvim',
}

local function blame_commit()
  local file = vim.api.nvim_buf_get_name(0)
  local line = vim.api.nvim_win_get_cursor(0)[1]

  if file == '' then return end

  local root = vim.fs.root(0, '.git')
  if not root then
    vim.notify('Not in a git repository', vim.log.levels.WARN)
    return
  end

  local relfile = vim.fs.relpath(root, file)
  if not relfile then return end

  local result = vim.fn.system {
    'git',
    '-C',
    root,
    'blame',
    '-L',
    line .. ',' .. line,
    '--porcelain',
    '--',
    relfile,
  }

  if vim.v.shell_error ~= 0 then
    vim.notify('Failed to get blame', vim.log.levels.ERROR)
    return
  end

  local sha = result:match '^([0-9a-f]+)'

  if not sha or sha:match '^0+$' then
    vim.notify('No committed change for this line', vim.log.levels.INFO)
    return
  end

  local subject = vim.fn
    .system({
      'git',
      '-C',
      root,
      'show',
      '-s',
      '--format=%s',
      sha,
    })
    :gsub('%s+$', '')

  Snacks.picker.pick {
    title = 'Commit: ' .. sha:sub(1, 10),
    cwd = root,
    layout = {
      layout = {
        box = 'horizontal',
        width = 0.95,
        height = 0.9,
        {
          box = 'vertical',
          width = 0.2,
          border = 'rounded',
          title = '{title}',
          { win = 'input', height = 1, border = 'bottom' },
          { win = 'list', border = 'none' },
        },
        {
          win = 'preview',
          title = '{preview}',
          border = 'rounded',
          width = 0.8,
        },
      },
    },
    items = {
      {
        text = subject,
        commit = sha,
        cwd = root,
      },
    },
    format = function(item)
      return {
        { item.commit:sub(1, 10) .. ' ', 'SnacksPickerGitCommit' },
        { item.text },
      }
    end,
    preview = 'git_show',
  }
end

vim.keymap.set('n', '<leader>gc', blame_commit, { desc = '[G]it [C]ommit under cursor' })
vim.keymap.set('n', '<leader>gf', function() Snacks.picker.git_log_file { confirm = 'focus_preview' } end, { desc = 'Git file history' })
vim.keymap.set('n', '<leader>gL', function() Snacks.picker.git_log_line() end, { desc = 'Git line history' })
vim.keymap.set('n', '<leader>gb', function() Snacks.picker.git_branches() end, { desc = '[G]it [B]ranches' })
vim.keymap.set('n', '<leader>gl', function() Snacks.picker.git_log() end, { desc = '[G]it [L]og' })
vim.keymap.set('n', '<leader>gs', function() Snacks.picker.git_status() end, { desc = '[G]it [S]tatus' })
vim.keymap.set('n', '<leader>gd', function() Snacks.picker.git_diff() end, { desc = '[G]it [D]iff' })
vim.keymap.set({ 'n', 'x' }, '<leader>go', function() Snacks.gitbrowse() end, { desc = '[G]it [O]pen in browser' })
if vim.fn.executable 'lazygit' == 1 then vim.keymap.set('n', '<leader><leader>', function() Snacks.lazygit() end, { desc = 'Open LazyGit' }) end

require('gitsigns').setup {
  signs = {
    add = { text = '+' },
    change = { text = '~' },
    delete = { text = '_' },
    topdelete = { text = '‾' },
    changedelete = { text = '~' },
  },
  current_line_blame = true,
  current_line_blame_formatter = '<author> (<abbrev_sha>), <author_time:%R> - <summary>',

  on_attach = function(bufnr)
    local gitsigns = require 'gitsigns'

    local function map(mode, l, r, opts)
      opts = opts or {}
      opts.buffer = bufnr
      vim.keymap.set(mode, l, r, opts)
    end

    -- In vimdiff, jump with built-in ]c/[c. Do not concatenate direction ('next'/'prev')
    -- with 'c' — that would feed normal! the invalid keys 'nextc' / 'prevc'.
    local function nav_hunk(direction)
      if vim.wo.diff then
        vim.cmd.normal { direction == 'prev' and '[c' or ']c', bang = true }
      else
        gitsigns.nav_hunk(direction)
      end
    end

    map('n', '<leader>gr', gitsigns.reset_hunk, { desc = 'Reset Git hunk' })
    map('n', '<leader>gh', gitsigns.preview_hunk, { desc = 'Preview Git hunk' })
    map('n', '<leader>ga', gitsigns.stage_hunk, { desc = 'Stage or unstage Git hunk' })
    map('x', '<leader>ga', function()
      local first, last = vim.fn.line '.', vim.fn.line 'v'
      gitsigns.stage_hunk { math.min(first, last), math.max(first, last) }
    end, { desc = 'Stage selected Git lines' })
    map('n', ']c', function() nav_hunk 'next' end, { desc = 'Git: next [c]hange' })
    map('n', '[c', function() nav_hunk 'prev' end, { desc = 'Git: previous [c]hange' })
  end,
}
