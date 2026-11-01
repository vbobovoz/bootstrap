-- Windows-specific shell, path, font, and terminal helpers.

--- Windows-specific Neovim setup: shell, PATH, HOME, GUI font.
local M = {}

local is_win = vim.fn.has 'win32' == 1

---@return boolean
function M.is_windows() return is_win end

---@return string
function M.path_sep() return is_win and ';' or ':' end

--- Prepend directories to PATH without adding duplicates.
---@param dirs string[]
---@param opts? { only_existing?: boolean }
function M.prepend_path(dirs, opts)
  local sep = M.path_sep()
  local only_existing = not opts or opts.only_existing ~= false
  local prepend = {}
  local present = {}

  local function key(dir)
    local normalized = vim.fs.normalize(dir)
    return is_win and normalized:lower() or normalized
  end

  for _, dir in ipairs(vim.split(vim.env.PATH or '', sep, { plain = true })) do
    if dir ~= '' then present[key(dir)] = true end
  end

  for _, dir in ipairs(dirs) do
    if dir and dir ~= '' and (not only_existing or vim.fn.isdirectory(dir) == 1) and not present[key(dir)] then
      table.insert(prepend, dir)
      present[key(dir)] = true
    end
  end
  if #prepend > 0 then vim.env.PATH = table.concat(prepend, sep) .. sep .. (vim.env.PATH or '') end
end

--- PowerShell for :!, jobs, and terminals (cmd.exe breaks quotes and Unicode).
local function setup_shell()
  local shell = vim.fn.executable 'pwsh' == 1 and 'pwsh' or 'powershell'
  vim.o.shell = shell
  -- See :help shell-powershell
  vim.o.shellcmdflag =
    '-NoLogo -NoProfile -ExecutionPolicy RemoteSigned -Command [Console]::InputEncoding=[Console]::OutputEncoding=[System.Text.Encoding]::UTF8;'
  vim.o.shellredir = '2>&1 | Out-File -Encoding UTF8 %s; exit $LastExitCode'
  vim.o.shellpipe = '2>&1 | Out-File -Encoding UTF8 %s; exit $LastExitCode'
  vim.o.shellquote = ''
  vim.o.shellxquote = ''
end

local function setup_home()
  if not vim.env.HOME or vim.env.HOME == '' then vim.env.HOME = vim.env.USERPROFILE end
end

local function setup_common_path()
  local home = vim.env.HOME or vim.env.USERPROFILE or ''
  M.prepend_path {
    home .. '\\scoop\\apps\\mingw\\current\\bin',
    home .. '\\go\\bin',
    home .. '\\.local\\go\\bin',
    home .. '\\.cargo\\bin',
    home .. '\\.local\\bin',
    'C:\\Program Files\\Go\\bin',
  }
end

local function setup_guifont()
  if vim.g.neovide or vim.fn.has 'gui_running' == 1 then vim.o.guifont = 'Lilex Nerd Font:h12' end
end

function M.setup()
  if not is_win then return end
  setup_home()
  setup_shell()
  setup_common_path()
  if not vim.env.CC and vim.fn.executable 'gcc' == 1 then vim.env.CC = vim.fn.exepath 'gcc' end
  setup_guifont()
end

return M
