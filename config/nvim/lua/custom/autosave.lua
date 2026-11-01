-- Safe autosave behavior for regular file buffers.

local M = {}

local group = vim.api.nvim_create_augroup('custom-autosave', { clear = true })

local skip_buftype = {
  [''] = false,
  acwrite = true,
  nofile = true,
  prompt = true,
  quickfix = true,
  terminal = true,
}

local skip_filetype = {
  [''] = false,
  snacks_picker_input = true,
  snacks_picker_list = true,
  snacks_picker_preview = true,
  mason = true,
}

---@param bufnr? integer
function M.should_save(bufnr)
  if vim.g.custom_autosave == false then return false end
  bufnr = bufnr or vim.api.nvim_get_current_buf()
  if not vim.api.nvim_buf_is_valid(bufnr) or not vim.api.nvim_buf_is_loaded(bufnr) then return false end
  local bo = vim.bo[bufnr]
  if skip_buftype[bo.buftype] then return false end
  if not bo.buflisted or not bo.modifiable or bo.readonly then return false end
  if not bo.modified then return false end
  if skip_filetype[bo.filetype] then return false end
  if vim.api.nvim_buf_get_name(bufnr) == '' then return false end
  return true
end

---@param bufnr? integer
function M.save(bufnr)
  bufnr = bufnr or vim.api.nvim_get_current_buf()
  if not M.should_save(bufnr) then return end
  vim.api.nvim_buf_call(bufnr, function() vim.cmd.write { mods = { silent = true } } end)
end

function M.setup()
  vim.api.nvim_create_autocmd('FocusLost', {
    group = group,
    desc = 'Autosave current buffer when Neovim loses focus',
    nested = true,
    callback = function() M.save() end,
  })
end

M.setup()

return M
