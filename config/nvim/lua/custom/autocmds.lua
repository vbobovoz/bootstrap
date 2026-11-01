-- Global autocommands shared by all filetypes.
-- Loaded directly from init.lua after options and keymaps.

local project = require 'custom.project'

local project_markers = {}
for _, marker in ipairs(project.project_markers) do
  project_markers[marker] = true
end

vim.api.nvim_create_autocmd('TextYankPost', {
  desc = 'Highlight when yanking (copying) text',
  group = vim.api.nvim_create_augroup('custom-highlight-yank', { clear = true }),
  callback = function() vim.hl.on_yank() end,
})

vim.api.nvim_create_autocmd({ 'DirChanged', 'BufWritePost' }, {
  desc = 'Invalidate cached project roots when project layout may have changed',
  group = vim.api.nvim_create_augroup('custom-project-root-cache', { clear = true }),
  callback = function(args)
    if args.event == 'DirChanged' or project_markers[vim.fs.basename(vim.api.nvim_buf_get_name(args.buf))] then project.clear_project_root_cache() end
  end,
})

local project_root_group = vim.api.nvim_create_augroup('custom-project-root', { clear = true })

vim.api.nvim_create_autocmd('DirChanged', {
  group = project_root_group,
  pattern = 'tabpage',
  callback = function()
    if not vim.v.event.changed_window then vim.t.custom_project_root_initialized = true end
  end,
  desc = 'Keep an explicitly changed tab directory before its first project file',
})

vim.api.nvim_create_autocmd('BufEnter', {
  group = project_root_group,
  callback = function(args)
    if vim.t.custom_project_root_initialized then return end
    if vim.bo[args.buf].buftype ~= '' then return end
    local path = vim.api.nvim_buf_get_name(args.buf)
    if path == '' then return end
    local root = project.project_root(path)
    if not root then return end

    vim.t.custom_project_root_initialized = true
    if vim.fs.normalize(root) ~= vim.fs.normalize(vim.fn.getcwd()) then vim.cmd.tcd(vim.fn.fnameescape(root)) end
  end,
  desc = 'Set the tab working directory from its first project file',
})

require 'custom.autosave'
