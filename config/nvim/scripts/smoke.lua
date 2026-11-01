-- Headless behavior checks used by `make check`.

local function check()
  local util = require 'custom.util'
  local windows = require 'custom.features.windows'

  local function normalized(path) return vim.fs.normalize(vim.uv.fs_realpath(path) or vim.fn.fnamemodify(path, ':p')) end

  local config_root = normalized(vim.fn.stdpath 'config')
  assert(vim.fn.filereadable(config_root .. '/init.lua') == 1, 'active config must contain init.lua')
  assert(
    vim.tbl_contains(vim.opt.runtimepath:get(), vim.fs.joinpath(vim.fn.stdpath 'data', 'site')),
    'new parser installation directory must be registered even when missing from the initial runtimepath'
  )

  local seen = {}
  for _, marker in ipairs(util.project_markers) do
    assert(not seen[marker], 'duplicate project marker: ' .. marker)
    seen[marker] = true
  end

  local mason_bin = vim.fs.joinpath(vim.fn.stdpath 'data', 'mason', 'bin')
  local function path_count(path)
    local count = 0
    for _, entry in ipairs(vim.split(vim.env.PATH or '', windows.path_sep(), { plain = true })) do
      if vim.fs.normalize(entry) == vim.fs.normalize(path) then count = count + 1 end
    end
    return count
  end

  assert(path_count(mason_bin) == 1, 'Mason bin directory must occur exactly once on PATH')

  assert(vim.fn.exists ':Mason' == 2, ':Mason command must exist before lazy LSP setup')
  assert(package.loaded['render-markdown'] == nil, 'render-markdown must not load at startup')
  assert(package.loaded.lint == nil, 'nvim-lint must not load at startup')
  assert(not vim.t.custom_project_root_initialized, 'unnamed startup buffer must not lock the tab project root')

  local markdown = vim.api.nvim_create_buf(true, true)
  vim.api.nvim_set_current_buf(markdown)
  vim.bo[markdown].filetype = 'markdown'
  assert(package.loaded['render-markdown'] ~= nil, 'render-markdown must load for Markdown buffers')
  assert(require('render-markdown.state').config.latex.enabled == false, 'render-markdown LaTeX support must be disabled')

  vim.api.nvim_buf_delete(markdown, { force = true })

  local fixture = vim.fn.tempname()
  local project_a = vim.fs.joinpath(fixture, 'project-a')
  local project_b = vim.fs.joinpath(fixture, 'project-b')
  local file_a = vim.fs.joinpath(project_a, 'main.py')
  local file_b = vim.fs.joinpath(project_b, 'nested dir', 'config%test.py')

  vim.fn.mkdir(vim.fs.joinpath(project_a, '.git'), 'p')
  vim.fn.mkdir(vim.fs.joinpath(project_b, '.git'), 'p')
  vim.fn.mkdir(vim.fs.dirname(file_b), 'p')
  vim.fn.writefile({}, file_a)
  vim.fn.writefile({}, file_b)

  vim.cmd.edit(vim.fn.fnameescape(file_a))
  assert(normalized(vim.fn.getcwd()) == normalized(project_a), 'first project file must set the tab directory')
  assert(vim.wait(1000, function() return package.loaded.lint ~= nil end), 'nvim-lint must load for Python buffers')
  assert(path_count(mason_bin) == 1, 'lazy LSP setup must not duplicate Mason on PATH')

  assert(not vim.lsp.config.pyright.settings.python.pythonPath, 'config must not override the Python interpreter')
  local statusline = require 'custom.ui.statusline'
  assert(statusline.current_file_path() == 'main.py', 'statusline must show the project-relative file path')

  vim.cmd.edit(vim.fn.fnameescape(file_b))
  assert(normalized(vim.fn.getcwd()) == normalized(project_a), 'another project in the same tab must not change its directory')
  assert(statusline.current_file_path() == 'nested dir/config%test.py', 'path must use the file project, even when tab cwd belongs to another project')

  vim.cmd.tabnew(vim.fn.fnameescape(file_b))
  assert(normalized(vim.fn.getcwd()) == normalized(project_b), 'a new tab must detect its own project directory')
  vim.cmd.tabclose()

  vim.cmd.enew()
  assert(statusline.current_file_path() == '', 'unnamed buffers must not show a file path')

  vim.fn.delete(fixture, 'rf')
end

local ok, err = xpcall(check, debug.traceback)
if not ok then
  io.stderr:write(err .. '\n')
  vim.cmd 'cquit 1'
end
vim.cmd 'qa!'
