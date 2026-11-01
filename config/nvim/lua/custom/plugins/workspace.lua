-- Project-aware terminal behavior.
-- Loaded by custom.plugins.init.

local function toggle_terminal()
  local cwd = vim.fn.getcwd()
  local terminal, created = Snacks.terminal.get(nil, {
    cwd = cwd,
    auto_close = false,
    win = {
      position = 'bottom',
      height = 15,
    },
  })
  if not terminal then return end

  if created then
    terminal:on('TermClose', function(self)
      if self.closed then return end
      vim.schedule(function()
        if self:buf_valid() then self:close() end
        vim.cmd.checktime()
      end)
    end, { buf = true })
  else
    terminal:toggle()
  end
end

vim.keymap.set('n', '<C-\\>', toggle_terminal, { desc = 'Toggle terminal' })
