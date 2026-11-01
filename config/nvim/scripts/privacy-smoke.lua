-- Verify both provider migration and the existing sensitive/gitignore boundaries.
local function check()
  local inline = require 'custom.plugins.inline'
  local root = vim.fn.tempname()
  vim.fn.mkdir(root, 'p')
  local result = vim.system({ 'git', 'init', '--quiet', root }, { text = true }):wait()
  assert(result.code == 0, result.stderr)
  vim.fn.writefile({ 'ignored.yaml' }, root .. '/.gitignore')
  local buf = vim.api.nvim_create_buf(false, true)
  assert(not inline.filter(buf), 'unnamed buffers must not use AI suggestions')
  for _, name in ipairs {
    '.env',
    '.env.local',
    'app.env',
    'server.pem',
    'server.key',
    'id_ed25519',
    'credentials.json',
    '.ssh/config',
    '.aws/config',
    '.kube/config',
    'kubeconfig',
    '.docker/config.json',
    'secrets/app.json',
    'terraform.tfstate',
    'local.tfvars',
    'ignored.yaml',
  } do
    vim.api.nvim_buf_set_name(buf, root .. '/' .. name)
    assert(not inline.filter(buf), 'private or gitignored file must be excluded: ' .. name)
  end
  vim.api.nvim_buf_set_name(buf, root .. '/main.go')
  assert(inline.filter(buf), 'ordinary source files must allow suggestions')
  vim.b[buf].custom_inline_ai = false
  assert(not inline.filter(buf), 'buffer toggle must disable suggestions')
  vim.api.nvim_buf_delete(buf, { force = true })
  vim.fn.delete(root, 'rf')
end

local ok, err = xpcall(check, debug.traceback)
if not ok then
  io.stderr:write(err .. '\n')
  vim.cmd 'cquit 1'
end
vim.cmd 'qa!'
