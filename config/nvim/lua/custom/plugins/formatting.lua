-- Conform formatters, format-on-save rules, and manual formatting.
-- Loaded by custom.plugins.init.

local gh = require('custom.util').gh

vim.pack.add { gh 'stevearc/conform.nvim' }

require('conform').setup {
  notify_on_error = true,

  format_on_save = function(bufnr)
    if vim.g.custom_format_on_save == false then return end
    if vim.bo[bufnr].filetype == 'go' then return { timeout_ms = 2000, lsp_format = 'never' } end
    if vim.bo[bufnr].filetype == 'python' then return { timeout_ms = 2500, lsp_format = 'never' } end
    if vim.bo[bufnr].filetype == 'lua' then return { timeout_ms = 2000, lsp_format = 'never' } end
  end,

  default_format_opts = {
    lsp_format = 'fallback',
  },
  formatters_by_ft = {
    lua = { 'stylua' },
    python = { 'ruff_organize_imports', 'ruff_fix', 'ruff_format' },
    go = { 'goimports', 'gofumpt' },
    yaml = { 'prettier' },
    ['yaml.gitlab'] = { 'prettier' },
    ['yaml.docker-compose'] = { 'prettier' },
    ['yaml.helm-values'] = { 'prettier' },
    sh = { 'shfmt' },
    bash = { 'shfmt' },
  },
}
vim.keymap.set({ 'n', 'v' }, '<leader>F', function()
  local ft = vim.bo.filetype
  if ft == 'helm' then
    vim.notify('Helm templates are excluded from automatic formatting.', vim.log.levels.INFO)
    return
  end
  local opts = { async = true }

  if ft == 'python' then
    opts.timeout_ms = 5000
    opts.lsp_format = 'never'
  elseif ft == 'go' then
    opts.timeout_ms = 3000
    opts.lsp_format = 'never'
  elseif ft:match '^yaml' or ft == 'sh' or ft == 'bash' then
    opts.timeout_ms = 3000
    opts.lsp_format = 'never'
  else
    opts.timeout_ms = 2000
    opts.lsp_format = 'fallback'
  end
  require('conform').format(opts)
end, { desc = '[F]ormat buffer' })
