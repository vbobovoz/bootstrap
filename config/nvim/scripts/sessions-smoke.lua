-- Exercise real Resession save/load with isolated state and two tab directories.
local fixture = vim.fn.tempname()

local function canonical(path) return vim.uv.fs_realpath(path) or vim.fs.normalize(path) end

local function check()
  local resession = require 'resession'
  local root = vim.fs.joinpath(fixture, 'project')
  local cwd_a = vim.fs.joinpath(root, 'first')
  local cwd_b = vim.fs.joinpath(root, 'second')
  vim.fn.mkdir(vim.fs.joinpath(root, '.git'), 'p')
  vim.fn.mkdir(cwd_a, 'p')
  vim.fn.mkdir(cwd_b, 'p')
  local file_a = vim.fs.joinpath(cwd_a, 'a.txt')
  local file_b = vim.fs.joinpath(cwd_b, 'b.txt')
  vim.fn.writefile({ 'first' }, file_a)
  vim.fn.writefile({ 'second' }, file_b)

  vim.cmd.edit(file_a)
  vim.cmd.tcd(cwd_a)
  vim.cmd.tabnew(file_b)
  vim.cmd.tcd(cwd_b)
  resession.save('cwd-regression', { notify = false })
  resession.save_tab('tab-cwd-regression', { notify = false })
  resession.detach()
  vim.cmd.tcd(root)

  resession.load('cwd-regression', { attach = false })
  local tabs = vim.api.nvim_list_tabpages()
  assert(#tabs == 2, 'session must restore two tabs')
  for i, expected in ipairs { cwd_a, cwd_b } do
    vim.api.nvim_set_current_tabpage(tabs[i])
    vim.api.nvim_exec_autocmds('BufEnter', { group = 'custom-project-root', buffer = 0 })
    assert(canonical(vim.fn.getcwd()) == canonical(expected), 'restored cwd must survive BufEnter in tab ' .. i)
    assert(vim.t.custom_project_root_initialized, 'restored tab directory must be initialized')
  end

  -- Loading one tab must preserve other tabs, including an untouched empty tab.
  vim.cmd.tabnew()
  local empty_tab = vim.api.nvim_get_current_tabpage()
  vim.api.nvim_set_current_tabpage(tabs[1])
  resession.load('tab-cwd-regression', { attach = false })
  assert(canonical(vim.fn.getcwd()) == canonical(cwd_b), 'tab-scoped session must retain its saved directory')
  assert(vim.t.custom_project_root_initialized, 'loaded tab must be initialized')
  assert(not vim.t[empty_tab].custom_project_root_initialized, 'unrelated empty tab must remain uninitialized')
  assert(canonical(vim.fn.getcwd(-1, vim.api.nvim_tabpage_get_number(tabs[1]))) == canonical(cwd_a), 'unrelated project tab must retain its cwd')

  vim.api.nvim_set_current_tabpage(empty_tab)
  vim.cmd.edit(file_a)
  assert(canonical(vim.fn.getcwd()) == canonical(root), 'unrelated empty tab must still detect its first project')

  -- A tab session may also reuse the current empty tab instead of creating one.
  vim.cmd.tabnew()
  local reused = vim.api.nvim_get_current_tabpage()
  resession.load('tab-cwd-regression', { attach = false })
  assert(vim.api.nvim_get_current_tabpage() == reused, 'empty tab should be reused')
  assert(vim.t.custom_project_root_initialized and canonical(vim.fn.getcwd()) == canonical(cwd_b), 'reused tab must retain restored cwd')
end

local ok, err = xpcall(check, debug.traceback)
require('resession').detach()
vim.cmd.cd '/tmp'
vim.fn.delete(fixture, 'rf')
if not ok then
  io.stderr:write(err .. '\n')
  vim.cmd 'cquit 1'
end
vim.cmd 'qa!'
