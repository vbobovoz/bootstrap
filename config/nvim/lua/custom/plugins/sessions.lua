-- Resession integration, lifecycle hooks, and session mappings.
-- Loaded by custom.plugins.init.

local sessions = require 'custom.features.sessions'
local gh = require('custom.util').gh

vim.pack.add { gh 'stevearc/resession.nvim' }

local resession = require 'resession'
resession.setup {
  autosave = {
    enabled = true,
    interval = 60,
    notify = false,
  },
  extensions = {
    quickfix = {},
  },
}

local autosave_group = vim.api.nvim_create_augroup('custom-sessions-autosave', { clear = true })

local function autosave_current()
  local name = resession.get_current()
  if name then resession.save(name, { notify = false }) end
end

local tabs_before_load = {}
resession.add_hook('pre_load', function()
  tabs_before_load = {}
  for _, tab in ipairs(vim.api.nvim_list_tabpages()) do
    tabs_before_load[tab] = true
  end
  resession.save_all { notify = false }
  sessions.close_all_terminals()
end)

resession.add_hook('post_load', function(name, opts)
  opts = opts or {}
  for _, tab in ipairs(vim.api.nvim_list_tabpages()) do
    if opts.reset or tab == vim.api.nvim_get_current_tabpage() or not tabs_before_load[tab] then vim.t[tab].custom_project_root_initialized = true end
  end
  tabs_before_load = {}
  sessions.record_opened(name)
  sessions.refresh_icons()
end)

local autosave_timer = nil

vim.api.nvim_create_autocmd('BufWritePost', {
  group = autosave_group,
  callback = function()
    local name = resession.get_current()
    if not name then return end

    if autosave_timer then
      autosave_timer:stop()
    else
      local ok, timer = pcall(vim.uv.new_timer)
      if not ok or not timer then return end
      autosave_timer = timer
    end

    autosave_timer:start(
      2000,
      0,
      vim.schedule_wrap(function()
        if autosave_timer then
          autosave_timer:close()
          autosave_timer = nil
        end
        autosave_current()
      end)
    )
  end,
  desc = 'Autosave session on file write (debounced, 2s)',
})

vim.keymap.set('n', '<leader>ss', sessions.save, { desc = 'Session: save' })
vim.keymap.set('n', '<leader>sl', sessions.pick_load, { desc = 'Session: load' })
vim.keymap.set('n', '<leader>sd', sessions.pick_delete, { desc = 'Session: delete' })
vim.keymap.set('n', '<leader>sx', sessions.detach, { desc = 'Session: detach' })

pcall(
  function()
    require('which-key').add {
      { '<leader>ss', desc = 'Save' },
      { '<leader>sl', desc = 'Load' },
      { '<leader>sd', desc = 'Delete' },
      { '<leader>sx', desc = 'Detach' },
    }
  end
)
