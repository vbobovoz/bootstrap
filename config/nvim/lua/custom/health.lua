-- Health checks for external tools used by this configuration.

local function check_version()
  local verstr = tostring(vim.version())
  if not vim.version.ge then
    vim.health.error(string.format("Neovim out of date: '%s'. Upgrade to latest stable or nightly", verstr))
    return
  end

  if vim.version.ge(vim.version(), '0.12') then
    vim.health.ok(string.format("Neovim version is: '%s'", verstr))
  else
    vim.health.error(string.format("Neovim out of date: '%s'. Upgrade to latest stable or nightly", verstr))
  end
end

---@param name string
---@return boolean
local function executable(name) return vim.fn.executable(name) == 1 end

---@param label string
---@param candidates string[]
---@param level 'error'|'warn'|'info'
local function check_command(label, candidates, level)
  for _, name in ipairs(candidates) do
    if executable(name) then
      vim.health.ok(string.format('%s: `%s`', label, name))
      return
    end
  end

  local message = string.format('%s not found (tried: %s)', label, table.concat(candidates, ', '))
  if level == 'error' then
    vim.health.error(message)
  elseif level == 'warn' then
    vim.health.warn(message)
  else
    vim.health.info(message)
  end
end

local function check_required_tools()
  vim.health.start 'custom.nvim: core requirement'

  check_command('Git', { 'git' }, 'error')
end

local function check_feature_tools()
  vim.health.start 'custom.nvim: feature dependencies'

  check_command('ripgrep (project grep)', { 'rg' }, 'warn')
  check_command('fd (file picker)', { 'fd' }, 'warn')
  check_command('C compiler (Treesitter parsers)', { 'cc', 'gcc', 'clang', 'cl' }, 'warn')
  check_command('tar (Treesitter parsers)', { 'tar' }, 'warn')
  if executable 'tree-sitter' then
    local result = vim.system({ 'tree-sitter', '--version' }, { text = true, timeout = 3000 }):wait()
    local version = (result.stdout or ''):match '(%d+%.%d+%.%d+)'
    if result.code == 0 and version and vim.version.ge(version, '0.26.1') then
      vim.health.ok('tree-sitter-cli: ' .. version)
    else
      vim.health.warn 'Treesitter requires tree-sitter-cli >= 0.26.1; could not verify a compatible version'
    end
  else
    vim.health.warn 'tree-sitter-cli >= 0.26.1 is required to install Treesitter parsers'
  end
  check_command('Node.js (Node-based language tools)', { 'node' }, 'warn')
  check_command('npm (Mason language tools)', { 'npm' }, 'warn')
  check_command('curl (Mason and Treesitter downloads)', { 'curl' }, 'warn')
  check_command('unzip (Mason packages)', { 'unzip' }, 'warn')
  check_command('Make (config checks)', { 'make', 'gmake' }, 'info')
end

local function check_clipboard()
  vim.health.start 'custom.nvim: clipboard'

  local ok, provider = pcall(vim.fn['provider#clipboard#Executable'])
  if ok and type(provider) == 'string' and provider ~= '' then
    vim.health.ok('Clipboard provider: ' .. provider)
  else
    vim.health.warn('No clipboard provider detected', {
      'Install `wl-clipboard` on Wayland, `xclip`/`xsel` on X11, or run `:checkhealth vim.provider` for details.',
    })
  end
end

local function check_optional_tools()
  vim.health.start 'custom.nvim: optional integrations'

  check_command('LazyGit (`<Space><Space>`)', { 'lazygit' }, 'info')
  check_command('Go development', { 'go' }, 'info')

  check_command('Yazi', { 'yazi' }, 'info')
  check_command('Helm', { 'helm' }, 'info')
end

local function mason_executable(name)
  if executable(name) then return true end

  local path = vim.fs.joinpath(vim.fn.stdpath 'data', 'mason', 'bin', name)
  if vim.fn.executable(path) == 1 or vim.fn.filereadable(path) == 1 then return true end

  if vim.fn.has 'win32' == 1 then
    for _, suffix in ipairs { '.cmd', '.exe', '.bat' } do
      if vim.fn.executable(path .. suffix) == 1 or vim.fn.filereadable(path .. suffix) == 1 then return true end
    end
  end
  return false
end

local function check_language_tools()
  vim.health.start 'custom.nvim: language tools'

  local tools = require('custom.tools').packages
  for _, package in ipairs(vim.fn.sort(vim.tbl_keys(tools))) do
    local tool = tools[package]
    if mason_executable(tool.executable) then
      vim.health.ok(tool.label .. ' is installed')
    else
      vim.health.warn(tool.label .. ' is not installed', { 'Open a supported file or run `:Mason` to install it.' })
    end
  end
end

return {
  check = function()
    vim.health.start 'custom.nvim'

    local uv = vim.uv or vim.loop
    vim.health.info('System Information: ' .. vim.inspect(uv.os_uname()))

    check_version()
    check_required_tools()
    check_feature_tools()
    check_clipboard()
    check_optional_tools()
    check_language_tools()
  end,
}
