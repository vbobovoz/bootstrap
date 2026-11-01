-- Regression checks with installed adapter/lint code and temporary project/tool fixtures.
-- No plugin downloads, Mason installations, language servers, or real project commands.
local fixture = vim.fn.tempname()

local function canonical(path) return vim.uv.fs_realpath(path) or vim.fs.normalize(path) end

local function check()
  vim.opt.runtimepath:prepend(vim.fn.getcwd())
  vim.g.mapleader = ' '
  vim.o.swapfile = false
  local site = vim.env.CUSTOM_NVIM_INSTALLED_SITE or vim.fs.joinpath(vim.fn.stdpath 'data', 'site')
  local plugins = vim.fs.joinpath(site, 'pack', 'core', 'opt')
  for _, name in ipairs { 'neotest-python', 'nvim-lint', 'snacks.nvim' } do
    local path = vim.fs.joinpath(plugins, name)
    assert(vim.fn.isdirectory(path) == 1, 'required installed plugin: ' .. name)
    vim.opt.runtimepath:append(path)
  end
  rawset(vim.pack, 'add', function() end)
  rawset(vim.cmd, 'packadd', function() end)

  local function write(path, lines, executable)
    vim.fn.mkdir(vim.fs.dirname(path), 'p')
    vim.fn.writefile(lines or {}, path)
    if executable then assert(vim.uv.fs_chmod(path, 493)) end
    return path
  end
  local project_a = vim.fs.joinpath(fixture, 'project-a')
  local project_b = vim.fs.joinpath(fixture, 'project-b')
  write(vim.fs.joinpath(project_a, 'pyproject.toml'))
  write(vim.fs.joinpath(project_b, 'requirements.txt'))
  write(vim.fs.joinpath(project_b, '.venv', 'bin', 'python'), { '#!/bin/sh', 'exit 0' }, true)
  local test_b = write(vim.fs.joinpath(project_b, 'test_example.py'))
  vim.cmd.tcd(project_a)

  -- Exercise the installed adapter's internal discovery/build paths, not just adapter.root.
  local adapter
  package.loaded.neotest = {
    setup = function(opts) adapter = opts.adapters[1] end,
    run = { run = function() end },
  }
  package.loaded['neotest-golang'] = setmetatable({}, { __call = function() return {} end })
  package.loaded.nio = {
    wrap = function(fn)
      return function(root)
        fn(root, function() end)
      end
    end,
    fn = { tempname = vim.fn.tempname },
  }
  package.loaded['neotest.logging'] = {}
  package.loaded['neotest.lib'] = {
    files = {
      sep = '/',
      match_root_pattern = function()
        return function() return project_a end
      end,
      write = function() end,
      stream_lines = function()
        return function() end, function() end
      end,
    },
    treesitter = { parse_positions = function() return 'positions' end },
  }
  require 'custom.plugins.neotest'
  vim.fn.maparg(' tn', 'n', false, true).callback()
  assert(adapter and adapter.root(test_b) == project_b, 'Neotest must use the file project, not the tab directory')
  local base = require 'neotest-python.base'
  base.treesitter_queries = function(_, _, python)
    assert(python[1] == (vim.fn.exepath 'python3' ~= '' and vim.fn.exepath 'python3' or 'python'), 'test discovery must use PATH, not select a venv')
    return ''
  end
  assert(adapter.discover_positions(test_b) == 'positions')
  local spec = adapter.build_spec {
    tree = { data = function() return { path = test_b, id = test_b } end },
  }
  assert(spec.command[1] == (vim.fn.exepath 'python3' ~= '' and vim.fn.exepath 'python3' or 'python'), 'test execution must use PATH, not select a venv')
  local nested = vim.fs.joinpath(project_b, 'nested')
  write(vim.fs.joinpath(nested, 'pytest.ini'))
  assert(adapter.root(vim.fs.joinpath(nested, 'test_nested.py')) == nested, 'pytest-only projects must share Python root detection')
  assert(canonical(vim.fn.getcwd()) == canonical(project_a), 'Neotest must preserve the tab directory')

  -- Use the real nvim-lint process launcher with tiny fixture executables.
  local tools = vim.fs.joinpath(fixture, 'tools')
  vim.fn.mkdir(tools, 'p')
  vim.env.PATH = tools
  local spawns = {}
  local spawn = vim.uv.spawn
  vim.uv.spawn = function(command, opts, callback)
    spawns[#spawns + 1] = { command = command, cwd = opts.cwd, args = opts.args }
    return spawn(command, opts, callback)
  end
  local system = vim.fn.system
  rawset(vim.fn, 'system', function() error 'synchronous process probe during lint setup' end)
  require 'custom.plugins.lint'
  local python_buf = vim.api.nvim_create_buf(true, false)
  vim.api.nvim_buf_set_name(python_buf, test_b)
  vim.api.nvim_set_current_buf(python_buf)
  vim.bo.filetype = 'python'
  assert(vim.wait(1000, function() return package.loaded.lint ~= nil end), 'scheduled lint setup did not finish')
  vim.wait(30, function() return false end)
  assert(#spawns == 0, 'missing Ruff must be skipped')

  write(vim.fs.joinpath(tools, 'ruff'), { '#!/bin/sh', "printf '%s\\n' '[]'" }, true)
  vim.api.nvim_exec_autocmds('User', { pattern = 'MasonToolsUpdateCompleted', data = { 'ruff' } })
  assert(vim.wait(1000, function() return #spawns == 1 end), 'Ruff installation must trigger Python linting')
  assert(canonical(spawns[1].cwd) == canonical(project_b), 'Ruff must run in project B')
  assert(canonical(vim.fn.getcwd()) == canonical(project_a) and vim.fn.haslocaldir(-1, 0) == 1, 'linting must preserve tab cwd and its scope')

  local module = vim.fs.joinpath(fixture, 'go-module')
  write(vim.fs.joinpath(module, 'go.mod'), { 'module example.test/fixture', 'go 1.24' })
  local go_file = write(vim.fs.joinpath(module, 'pkg', 'example.go'), { 'package pkg' })
  write(vim.fs.joinpath(tools, 'golangci-lint'), { '#!/bin/sh', "printf '%s\\n' '{\"Issues\":null}'" }, true)
  local go_buf = vim.api.nvim_create_buf(true, false)
  vim.api.nvim_buf_set_name(go_buf, go_file)
  vim.api.nvim_set_current_buf(go_buf)
  local eventignore = vim.o.eventignore
  vim.o.eventignore = 'FileType'
  vim.bo.filetype = 'go'
  vim.o.eventignore = eventignore
  vim.api.nvim_exec_autocmds('BufWritePost', { buffer = go_buf })
  assert(vim.wait(1000, function() return #spawns == 2 end), 'Go lint must run after the save debounce')
  assert(canonical(spawns[2].cwd) == canonical(module), 'Go lint must run in its module')
  assert(vim.tbl_contains(spawns[2].args, '--allow-serial-runners'), 'Go runners must wait for the shared golangci-lint lock')
  assert(canonical(spawns[2].args[#spawns[2].args]) == canonical(vim.fs.dirname(go_file)), 'module files must be linted as a package')
  local standalone = write(vim.fs.joinpath(fixture, 'standalone.go'), { 'package main' })
  vim.api.nvim_buf_set_name(go_buf, standalone)
  vim.api.nvim_exec_autocmds('BufWritePost', { buffer = go_buf })
  assert(vim.wait(1000, function() return #spawns == 3 end), 'standalone Go lint must run after the save debounce')
  assert(canonical(spawns[3].args[#spawns[3].args]) == canonical(standalone), 'standalone Go files must be passed individually')
  assert(canonical(vim.fn.getcwd()) == canonical(project_a) and vim.fn.haslocaldir(-1, 0) == 1, 'Go lint must preserve tab cwd and its scope')
  -- A burst of saves launches only the final request, without blocking writes.
  for _ = 1, 3 do
    vim.api.nvim_exec_autocmds('BufWritePost', { buffer = go_buf })
    vim.wait(40, function() return false end)
  end
  assert(#spawns == 3, 'rapid saves must not start linters immediately')
  assert(vim.wait(1000, function() return #spawns == 4 end), 'rapid saves must eventually lint')
  vim.wait(300, function() return false end)
  assert(#spawns == 4, 'rapid saves must coalesce into one process')

  local golangci = require 'custom.linters.golangci'
  local function issue(path) return { Pos = { Filename = path, Line = 2, Column = 3 }, Severity = 'error', FromLinter = 'govet', Text = 'example issue' } end
  local diagnostics = golangci.parser(vim.json.encode { Issues = { issue 'standalone.go', issue 'other.go' } }, go_buf, fixture)
  assert(#diagnostics == 1 and diagnostics[1].lnum == 1 and diagnostics[1].col == 2, 'Go diagnostics must filter files and convert positions')
  assert(diagnostics[1].severity == vim.diagnostic.severity.ERROR)
  assert(#golangci.parser('{"Issues":null}', go_buf, fixture) == 0)
  local lint = require 'lint'
  assert(vim.wait(2000, function() return #lint.get_running() == 0 end), 'fixture linters did not finish')
  vim.api.nvim_exec_autocmds('BufWritePost', { buffer = go_buf })
  vim.api.nvim_buf_delete(go_buf, { force = true })
  vim.wait(350, function() return false end)
  assert(#spawns == 4, 'deleted buffers must not start queued linters')
  -- Shared debounce must retain saves from different buffers in the burst.
  local other_buf = vim.api.nvim_create_buf(true, false)
  vim.api.nvim_buf_set_name(other_buf, vim.fs.joinpath(project_b, 'other.py'))
  vim.api.nvim_set_current_buf(other_buf)
  vim.bo.filetype = 'python'
  vim.wait(300, function() return false end)
  local before = #spawns
  vim.api.nvim_exec_autocmds('BufWritePost', { buffer = python_buf })
  vim.api.nvim_exec_autocmds('BufWritePost', { buffer = other_buf })
  assert(vim.wait(1000, function() return #spawns == before + 2 end), 'debounce must lint both saved buffers')
  assert(vim.wait(2000, function() return #lint.get_running() == 0 end), 'queued Python linters must finish')

  -- Resolve executable names from definitions, including function-valued commands.
  -- An unavailable linter must not prevent another configured linter from running.
  lint.linters.fixture_missing = vim.tbl_extend('force', lint.linters.ruff, { cmd = 'missing-fixture-linter' })
  lint.linters.fixture_available = vim.tbl_extend('force', lint.linters.ruff, {
    cmd = function() return vim.fs.joinpath(tools, 'ruff') end,
  })
  lint.linters_by_ft.python = { 'fixture_missing', 'fixture_available' }
  before = #spawns
  vim.api.nvim_exec_autocmds('BufWritePost', { buffer = python_buf })
  assert(vim.wait(1000, function() return #spawns == before + 1 end), 'available linter must run alongside a missing one')
  assert(spawns[#spawns].command == vim.fs.joinpath(tools, 'ruff'), 'command must come from the linter definition')
  assert(vim.wait(2000, function() return #lint.get_running() == 0 end), 'fixture linter must finish')

  -- Saving a buffer after changing to an unconfigured filetype must be skipped.
  vim.bo[python_buf].filetype = 'lua'
  before = #spawns
  vim.api.nvim_exec_autocmds('BufWritePost', { buffer = python_buf })
  vim.wait(350, function() return false end)
  assert(#spawns == before, 'unconfigured filetypes must not start a linter')
  rawset(vim.fn, 'system', system)
  vim.uv.spawn = spawn
end

local ok, err = xpcall(check, debug.traceback)
vim.cmd.cd '/tmp'
vim.fn.delete(fixture, 'rf')
if not ok then
  io.stderr:write(err .. '\n')
  vim.cmd 'cquit 1'
end
vim.cmd 'qa!'
