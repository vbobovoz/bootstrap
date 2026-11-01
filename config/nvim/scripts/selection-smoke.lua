-- Exercise native shifted-arrow selection without touching the system clipboard.
local function check()
  vim.o.clipboard = ''
  vim.o.swapfile = false

  local function keys(input) vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes(input, true, false, true), 'xt', false) end

  local function reset(column)
    keys '<Esc>'
    vim.api.nvim_buf_set_lines(0, 0, -1, false, { 'alpha beta gamma', 'second line' })
    vim.api.nvim_win_set_cursor(0, { 1, column or 0 })
    vim.fn.setreg('"', '')
  end

  for _, prefix in ipairs { '', 'i' } do
    reset()
    keys(prefix .. '<S-Right>y')
    assert(vim.fn.getreg '"' == 'a', 'Shift+Right must copy exactly one character')
    reset()
    keys(prefix .. '<C-S-Right>y')
    assert(vim.fn.getreg '"' == 'alpha ', 'Ctrl+Shift+Right must select to the next word')
    reset(6)
    keys(prefix .. '<C-S-Left>y')
    assert(vim.fn.getreg '"' == 'alpha ', 'Ctrl+Shift+Left must select to the previous word')
    reset()
    if prefix == 'i' then
      keys 'i<C-Right>|<Esc>'
      assert(vim.api.nvim_get_current_line() == 'alpha |beta gamma', 'Ctrl+Right must move the insertion point to the next word')
    else
      keys '<C-Right>'
      assert(vim.api.nvim_win_get_cursor(0)[2] == 6, 'Ctrl+Right must jump to the next word')
    end
    keys '<Esc>'
  end

  reset()
  keys '<S-Right><S-Right><S-Left>y'
  assert(vim.fn.getreg '"' == 'a', 'Reverse arrows must shrink the selection')
  reset()
  keys '<S-Down>y'
  assert(vim.fn.getreg '"' == 'alpha beta gamma\n', 'Shift+Down must extend the selection vertically')
  reset()
  keys '<S-Right><Right>'
  assert(vim.fn.mode() == 'n', 'Unshifted arrows must end selection')
end

local ok, err = xpcall(check, debug.traceback)
if not ok then
  io.stderr:write(err .. '\n')
  vim.cmd 'cquit 1'
end
print 'Arrow selection checks passed'
vim.cmd 'qa!'
