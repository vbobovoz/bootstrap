-- Asynchronous linting

local project = require 'custom.project'

-- Select linters explicitly; their executable names come from nvim-lint.
local linters_by_ft = {
  dockerfile = { 'hadolint' },
  sh = { 'shellcheck' },
  bash = { 'shellcheck' },
  go = { 'golangcilint' },
  python = { 'ruff' },
  yaml = { 'yamllint' },
}
linters_by_ft['yaml.helm-values'] = linters_by_ft.yaml
linters_by_ft['yaml.docker-compose'] = linters_by_ft.yaml
linters_by_ft['yaml.gitlab'] = linters_by_ft.yaml

local roots_by_ft = {
  dockerfile = project.project_root,
  go = function(path) return vim.fs.root(path, 'go.mod') or vim.fs.root(path, { 'go.work', '.git' }) end,
  python = project.python_root,
}
local lint_on_open = {}

vim.pack.add({ 'https://github.com/mfussenegger/nvim-lint' }, { load = function() end })

local lint

local function load_lint()
  if lint then return lint end
  vim.cmd.packadd 'nvim-lint'
  lint = require 'lint'
  lint.linters_by_ft = linters_by_ft
  lint.linters.golangcilint = require 'custom.linters.golangci'
  return lint
end

---@param bufnr integer
local function try_lint(bufnr)
  if not vim.api.nvim_buf_is_valid(bufnr) or not vim.api.nvim_buf_is_loaded(bufnr) then return end
  local path = vim.api.nvim_buf_get_name(bufnr)
  if path == '' or not vim.bo[bufnr].modifiable then return end
  local filetype = vim.bo[bufnr].filetype
  local names = linters_by_ft[filetype]
  if not names or #names == 0 then return end
  local find_root = roots_by_ft[filetype]
  local root = find_root and find_root(path)
  vim.api.nvim_buf_call(bufnr, function()
    local instance = load_lint()
    local cwd = root or vim.fs.dirname(path)
    -- nvim-lint evaluates args under :cd, which clears a tab-local cwd when it
    -- differs. chdir() preserves the directory scope and avoids that code path.
    local previous = vim.fn.getcwd()
    vim.cmd.call { 'chdir(' .. vim.fn.string(cwd) .. ')', mods = { noautocmd = true } }
    local ok, err = pcall(instance.try_lint, names, {
      cwd = cwd,
      filter = function(linter)
        local cmd = type(linter.cmd) == 'function' and linter.cmd() or linter.cmd
        return vim.fn.executable(cmd) == 1
      end,
    })
    vim.cmd.call { 'chdir(' .. vim.fn.string(previous) .. ')', mods = { noautocmd = true } }
    if not ok then error(err) end
  end)
end

-- Share one debounce timer, retaining every buffer saved during the burst.
local pending_lint = {}
local flush_lint = require('snacks.util').debounce(function()
  local buffers = pending_lint
  pending_lint = {}
  for bufnr in pairs(buffers) do
    try_lint(bufnr)
  end
end, { ms = 250 })

local lint_augroup = vim.api.nvim_create_augroup('custom-lint', { clear = true })
vim.api.nvim_create_autocmd('BufWritePost', {
  group = lint_augroup,
  callback = function(args)
    if not linters_by_ft[vim.bo[args.buf].filetype] then return end
    pending_lint[args.buf] = true
    flush_lint()
  end,
  desc = 'Lint configured buffers after saves settle',
})

vim.api.nvim_create_autocmd('FileType', {
  group = lint_augroup,
  pattern = vim.tbl_keys(linters_by_ft),
  callback = function(args)
    vim.schedule(function()
      load_lint()
      if vim.api.nvim_buf_is_valid(args.buf) and lint_on_open[vim.bo[args.buf].filetype] ~= false then try_lint(args.buf) end
    end)
  end,
  desc = 'Initialize linting for configured filetypes',
})

vim.api.nvim_create_autocmd('User', {
  group = lint_augroup,
  pattern = 'MasonToolsUpdateCompleted',
  callback = function()
    vim.schedule(function()
      for _, buf in ipairs(vim.api.nvim_list_bufs()) do
        if lint_on_open[vim.bo[buf].filetype] ~= false then try_lint(buf) end
      end
    end)
  end,
  desc = 'Retry linting open buffers after tools are installed',
})
