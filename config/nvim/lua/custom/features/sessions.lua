-- Session naming, discovery, persistence, and UI helpers.
-- Loaded by custom.plugins.sessions.

local M = {}
local util = require 'custom.util'

local ACCESS_FILE = vim.fn.stdpath 'data' .. '/custom-session-last-opened.json'

---@type table<string, integer>|nil
local access_times_cache = nil

---@type any|nil
local cached_devicons = false

local function resession() return require 'resession' end

local function read_access_times_from_disk()
  if vim.fn.filereadable(ACCESS_FILE) == 0 then return {} end
  local ok, data = pcall(vim.json.decode, table.concat(vim.fn.readfile(ACCESS_FILE), '\n'))
  if ok and type(data) == 'table' then return data end
  return {}
end

local function write_access_times(times)
  vim.fn.mkdir(vim.fn.fnamemodify(ACCESS_FILE, ':h'), 'p')
  vim.fn.writefile({ vim.json.encode(times) }, ACCESS_FILE)
end

local function get_access_times()
  if not access_times_cache then access_times_cache = read_access_times_from_disk() end
  return access_times_cache
end

local function flush_access_times()
  if access_times_cache then write_access_times(access_times_cache) end
end

vim.api.nvim_create_autocmd('VimLeavePre', {
  callback = flush_access_times,
})

---@param name string
function M.record_opened(name)
  if not name or name == '' then return end
  local times = get_access_times()
  times[name] = os.time()
end

---@param name string
function M.forget_opened(name)
  if not name or name == '' then return end
  local times = get_access_times()
  if times[name] then times[name] = nil end
end

local function sort_by_last_opened(names)
  local times = get_access_times()
  table.sort(names, function(a, b)
    local ta = times[a] or 0
    local tb = times[b] or 0
    if ta ~= tb then return ta > tb end
    return a < b
  end)
end

local resession_util ---@type any|nil
local resession_files ---@type any|nil
local resession_mods_tried = false

local function ensure_resession_mods()
  if resession_mods_tried then return resession_util ~= nil and resession_files ~= nil end
  resession_mods_tried = true
  local ok_util, util = pcall(require, 'resession.util')
  local ok_files, files = pcall(require, 'resession.files')
  if ok_util and ok_files then
    resession_util = util
    resession_files = files
    return true
  end
  return false
end

---@param name string
---@return { name: string, cwd: string, cwd_full: string }
local function get_session_info(name)
  if not ensure_resession_mods() then return { name = name, cwd = '', cwd_full = '' } end

  local data = resession_files.load_json_file(resession_util.get_session_file(name))
  local cwd_full
  if data then
    if data.tab_scoped and data.tabs and data.tabs[1] then
      cwd_full = data.tabs[1].cwd
    elseif data.global then
      cwd_full = data.global.cwd
    end
  end

  return {
    name = name,
    cwd = cwd_full and resession_util.shorten_path(cwd_full) or '',
    cwd_full = cwd_full or '',
  }
end

local function get_devicons()
  if cached_devicons ~= false then return cached_devicons end
  local ok, devicons = pcall(require, 'nvim-web-devicons')
  if not ok then
    cached_devicons = nil
    return nil
  end
  if not devicons.has_loaded() then devicons.setup() end
  cached_devicons = devicons
  return cached_devicons
end

---@param cwd string
---@return string, string|nil
local function project_icon(cwd)
  if cwd == '' or not vim.g.have_nerd_font then return '  ', nil end

  local devicons = get_devicons()
  if not devicons then return '  ', nil end

  for _, marker in ipairs(util.project_markers) do
    if vim.fn.filereadable(cwd .. '/' .. marker) == 1 then
      local icon, hl = devicons.get_icon(marker)
      if icon then return icon .. ' ', hl end
    end
  end

  local icon, hl = devicons.get_icon(vim.fn.fnamemodify(cwd, ':t'))
  if icon then return icon .. ' ', hl end

  return '  ', nil
end

function M.refresh_icons()
  vim.defer_fn(function() require('custom.ui.bufferline').refresh() end, 50)
end

function M.save()
  local current = resession().get_current()
  vim.ui.input({
    prompt = 'Session name: ',
    default = current or '',
    completion = 'customlist,v:lua.require"custom.features.sessions".complete',
  }, function(name)
    if not name or name == '' then return end
    resession().save(name)
    M.record_opened(name)
  end)
end

function M.complete(arglead, cmdline, cursorpos)
  local names = resession().list()
  local out = {}
  for _, name in ipairs(names) do
    if name:sub(1, #arglead) == arglead then table.insert(out, name) end
  end
  return out
end

---@param prompt string
---@param on_choice fun(name: string)
local function pick_session(prompt, on_choice)
  local names = resession().list()
  if #names == 0 then
    vim.notify('No saved sessions', vim.log.levels.WARN)
    return
  end

  sort_by_last_opened(names)

  local items = {}
  for i, name in ipairs(names) do
    local info = get_session_info(name)
    local icon = project_icon(info.cwd_full)
    local suffix = info.cwd ~= '' and ('  ' .. info.cwd) or ''
    items[#items + 1] = {
      idx = i,
      name = name,
      text = string.format('%s%-22s%s', icon, info.name, suffix),
    }
  end

  Snacks.picker.pick {
    title = prompt,
    items = items,
    format = 'text',
    sort = { fields = { 'score:desc', 'idx' } },
    preview = 'none',
    layout = { preset = 'select', layout = { min_width = 70 } },
    confirm = function(picker, item)
      picker:close()
      if item then vim.schedule(function() on_choice(item.name) end) end
    end,
  }
end

function M.pick_load()
  pick_session('Load session', function(name) resession().load(name) end)
end

function M.pick_delete()
  pick_session('Delete session', function(name)
    resession().delete(name)
    M.forget_opened(name)
  end)
end

---@param limit? integer
---@return table[]
function M.dashboard_items(limit)
  local names = resession().list()
  sort_by_last_opened(names)

  local items = {}
  for i = 1, math.min(limit or 5, #names) do
    local name = names[i]
    local info = get_session_info(name)
    local cwd = info.cwd ~= '' and vim.fn.pathshorten(info.cwd) or ''
    local cwd_width = math.max(8, 44 - #info.name - 2)
    if #cwd > cwd_width then cwd = '…' .. cwd:sub(-(cwd_width - 1)) end
    local suffix = cwd ~= '' and ('  ' .. cwd) or ''
    items[#items + 1] = {
      icon = ' ',
      desc = info.name .. suffix,
      key = tostring(i),
      action = function() resession().load(name) end,
    }
  end
  return items
end

function M.detach()
  resession().detach()
  vim.notify('Detached from session', vim.log.levels.INFO)
end

function M.close_all_terminals()
  for _, terminal in ipairs(Snacks.terminal.list()) do
    pcall(function() terminal:close() end)
  end
end

return M
