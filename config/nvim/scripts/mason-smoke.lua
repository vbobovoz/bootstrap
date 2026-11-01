-- Exercise the real installer with an in-memory registry; no downloads or state writes.

local function check()
  vim.opt.runtimepath:prepend(vim.fn.getcwd())
  local site = vim.env.CUSTOM_NVIM_INSTALLED_SITE or vim.fs.joinpath(vim.fn.stdpath 'data', 'site')
  local plugin = vim.fs.joinpath(site, 'pack', 'core', 'opt', 'mason-tool-installer.nvim')
  vim.opt.runtimepath:append(plugin)

  local refreshes, installs, checked = {}, {}, {}
  local installed = {}
  package.loaded['mason-registry'] = {
    refresh = function(callback) table.insert(refreshes, callback) end,
    get_package = function(name)
      table.insert(checked, name)
      return {
        name = name,
        is_installed = function() return installed[name] == true end,
        is_installing = function() return false end,
        once = function() end,
        install = function(_, _, callback) installs[name] = callback end,
      }
    end,
  }
  package.loaded['mason.version'] = { MAJOR_VERSION = 2 }
  package.loaded.schemastore = { yaml = { schemas = function() return {} end } }
  package.loaded.mason = { setup = function() end }
  local bridge_requests = 0
  package.preload['mason-lspconfig'] = function()
    bridge_requests = bridge_requests + 1
    error 'mason-lspconfig must not be loaded'
  end
  package.loaded['blink.cmp'] = { get_lsp_capabilities = function() return {} end }
  -- Keep test doubles out of LuaLS's inferred definitions for the Neovim API.
  rawset(vim.pack, 'add', function() end)
  rawset(vim.cmd, 'packadd', function() end)
  rawset(vim, 'notify', function() end)
  rawset(vim, 'lsp', {
    buf = vim.lsp.buf,
    handlers = { ['textDocument/documentHighlight'] = function() end },
    config = function() end,
    enable = function() end,
  })

  dofile(vim.fs.joinpath(plugin, 'plugin', 'mason-tool-installer.lua'))
  assert(vim.fn.exists ':MasonToolsClean' == 2, 'installed plugin must register its cleanup command')
  require 'custom.plugins.lsp'

  local function request(filetype)
    local eventignore = vim.o.eventignore
    vim.o.eventignore = 'FileType'
    vim.bo.filetype = filetype
    vim.o.eventignore = eventignore
    vim.api.nvim_exec_autocmds('FileType', { group = 'custom-lsp-lazy-setup', pattern = filetype })
  end

  local function wait_for_refresh(count)
    assert(vim.wait(1000, function() return #refreshes == count end), 'expected next queued registry refresh')
  end

  local function complete(name, success)
    local callback = assert(installs[name], 'installation was not requested: ' .. name)
    installs[name] = nil
    installed[name] = success
    callback(success)
  end

  request 'python'
  assert(vim.fn.exists ':MasonToolsClean' == 0, 'language-scoped installation must not expose global cleanup')
  request 'go'
  request 'json'
  request 'jsonc'
  request 'python'
  assert(#refreshes == 1, 'only one language check may be active, got ' .. #refreshes)
  refreshes[1]()
  assert(installs.pyright and installs.ruff, 'first refresh must retain Python tools')
  assert(not installs.gopls, 'Go must wait for the Python check')
  complete('pyright', true)
  vim.wait(20, function() return false end)
  assert(#refreshes == 1, 'queue must wait for every package in the active check')
  complete('ruff', false)

  wait_for_refresh(2)
  request 'python'
  refreshes[2]()
  for _, name in ipairs { 'gopls', 'goimports', 'gofumpt', 'golangci-lint' } do
    complete(name, true)
  end

  wait_for_refresh(3)
  refreshes[3]()
  complete('json-lsp', true)
  wait_for_refresh(4)
  refreshes[4]()
  wait_for_refresh(5)
  refreshes[5]()
  assert(installs.ruff and not installs.pyright, 'retry must install only the failed package')
  complete('ruff', true)
  vim.wait(20, function() return false end)
  request 'python'
  request 'go'
  assert(#refreshes == 5, 'successful language checks must not be repeated')
  assert(vim.tbl_contains(checked, 'json-lsp'), 'JSON and JSONC must use the shared Mason package')
  assert(bridge_requests == 0, 'tool installation must not depend on mason-lspconfig')
end

local ok, err = xpcall(check, debug.traceback)
if not ok then
  io.stderr:write(err .. '\n')
  vim.cmd 'cquit 1'
end
vim.cmd 'qa!'
