-- Parse every Lua file with Neovim's own Lua runtime.

local function check()
  local root = vim.fn.getcwd()
  local files = vim.fs.find(function(name) return name:match '%.lua$' ~= nil end, {
    path = root,
    type = 'file',
    limit = math.huge,
  })

  table.sort(files)
  for _, path in ipairs(files) do
    local chunk, err = loadfile(path)
    assert(chunk, err)
  end
end

local ok, err = xpcall(check, debug.traceback)
if not ok then
  io.stderr:write(err .. '\n')
  vim.cmd 'cquit 1'
end
vim.cmd 'qa!'
