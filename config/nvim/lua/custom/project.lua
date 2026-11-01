-- Project roots and Python environments shared by navigation, LSP, tests, and terminals.
local M = {}

---@type table<string, string|false>
local project_root_cache = {}

M.project_markers = {
  '.git',
  'go.mod',
  'pyproject.toml',
  'package.json',
  'Cargo.toml',
  'Gemfile',
  'composer.json',
  'pom.xml',
  'build.gradle',
  'mix.exs',
  'venv',
  '.venv',
}

M.python_root_markers = { 'pyrightconfig.json', 'pyproject.toml', 'setup.py', 'setup.cfg', 'pytest.ini', 'mypy.ini', 'requirements.txt', 'Pipfile', '.git' }

---@param path string
---@return string|nil
function M.python_root(path) return vim.fs.root(path, M.python_root_markers) end

function M.clear_project_root_cache() project_root_cache = {} end

---@param path? string
---@return string|nil
function M.project_root(path)
  path = path or vim.api.nvim_buf_get_name(0)
  if path == '' then path = vim.fn.getcwd() end

  local normalized = vim.fs.normalize(vim.fn.fnamemodify(path, ':p'))
  local stat = vim.uv.fs_stat(normalized)
  local directory = stat and stat.type == 'directory' and normalized or vim.fs.dirname(normalized)
  local cached = project_root_cache[directory]
  if cached ~= nil then return cached or nil end

  local root = vim.fs.root(normalized, M.project_markers)
  project_root_cache[directory] = root or false
  return root
end

return M
