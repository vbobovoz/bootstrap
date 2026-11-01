-- Networked integration check for a disposable, fully bootstrapped machine.
-- Installs Mason tools/parsers and checks real Go completion + YAML diagnostics.
local function check()
  local root = vim.fn.tempname()
  vim.fn.mkdir(root .. '/.git', 'p')
  vim.fn.writefile({ 'module example.test/bootstrap', '', 'go 1.26' }, root .. '/go.mod')
  vim.fn.writefile({ 'package main', '', 'import "fmt"', '', 'func main() {', '\tfmt.Prin', '}' }, root .. '/main.go')
  vim.cmd.edit(vim.fn.fnameescape(root .. '/main.go'))
  -- Request every configured language through the production installation queue.
  for _, filetype in ipairs { 'python', 'lua', 'json', 'yaml', 'helm', 'dockerfile', 'sh', 'yaml.helm-values' } do
    local ignored = vim.o.eventignore
    vim.o.eventignore = 'FileType'
    vim.bo.filetype = filetype
    vim.o.eventignore = ignored
    vim.api.nvim_exec_autocmds('FileType', { group = 'custom-lsp-lazy-setup', pattern = filetype })
  end
  local ignored = vim.o.eventignore
  vim.o.eventignore = 'FileType'
  vim.bo.filetype = 'go'
  vim.o.eventignore = ignored

  local tools = {
    'gopls',
    'goimports',
    'gofumpt',
    'golangci-lint',
    'ruff',
    'stylua',
    'pyright-langserver',
    'lua-language-server',
    'vscode-json-language-server',
    'yaml-language-server',
    'helm_ls',
    'docker-langserver',
    'bash-language-server',
    'hadolint',
    'shellcheck',
    'shfmt',
    'prettier',
    'yamllint',
  }
  assert(
    vim.wait(240000, function()
      for _, tool in ipairs(tools) do
        if vim.fn.executable(tool) == 0 then return false end
      end
      return true
    end, 250),
    'Mason tools not installed: ' .. vim.inspect(vim.tbl_filter(function(tool) return vim.fn.executable(tool) == 0 end, tools))
  )

  local parsers = { 'go', 'yaml', 'gotmpl', 'dockerfile', 'bash' }
  local parser_errors = {}
  assert(
    vim.wait(60000, function()
      parser_errors = {}
      for _, parser in ipairs(parsers) do
        local loaded, result, err = pcall(vim.treesitter.language.add, parser)
        if not loaded or not result then parser_errors[parser] = err or tostring(result) end
      end
      return next(parser_errors) == nil
    end, 250),
    'Treesitter parsers did not install: ' .. vim.inspect(parser_errors)
  )

  vim.lsp.enable('gopls', false)
  assert(vim.wait(10000, function() return #vim.lsp.get_clients { name = 'gopls' } == 0 end, 100), 'previous gopls did not stop')
  vim.lsp.enable 'gopls'
  local go_buf = vim.api.nvim_get_current_buf()
  assert(
    vim.wait(30000, function()
      for _, client in ipairs(vim.lsp.get_clients { name = 'gopls', bufnr = go_buf }) do
        if client.initialized then return true end
      end
      return false
    end, 100),
    'gopls did not attach'
  )
  local client = vim.lsp.get_clients({ name = 'gopls', bufnr = go_buf })[1]
  local response = client:request_sync('textDocument/completion', {
    textDocument = { uri = vim.uri_from_bufnr(go_buf) },
    position = { line = 5, character = 9 },
    context = { triggerKind = 1 },
  }, 30000, go_buf)
  assert(response and not response.err and response.result, vim.inspect(response))
  local labels = {}
  for _, item in ipairs(response.result.items or response.result) do
    labels[item.label:match '^[%w_]+'] = true
  end
  assert(labels.Print and labels.Printf and labels.Println, 'fmt completion missing: ' .. vim.inspect(labels))

  vim.fn.writefile({ vim.json.encode { type = 'object', properties = { replicas = { type = 'integer' } } } }, root .. '/schema.json')
  vim.fn.writefile({ '# yaml-language-server: $schema=' .. root .. '/schema.json', 'replicas: wrong' }, root .. '/manifest.yaml')
  vim.cmd.edit(vim.fn.fnameescape(root .. '/manifest.yaml'))
  local yaml_buf = vim.api.nvim_get_current_buf()
  assert(vim.wait(30000, function() return #vim.diagnostic.get(yaml_buf) > 0 end, 100), 'YAML schema diagnostics missing')

  vim.api.nvim_exec_autocmds('InsertEnter', {})
  assert(require('blink.cmp').get_lsp_capabilities().textDocument.completion, 'Blink initialization failed')
  assert(vim.g.colors_name == 'kanagawa', 'Colorscheme failed to load')
  assert(vim.v.errmsg == '', vim.v.errmsg)
  vim.fn.delete(root, 'rf')
  print 'INTEGRATION_OK: all Mason tools, Treesitter, Go completion, YAML validation, Blink, Kanagawa'
end

local ok, err = xpcall(check, debug.traceback)
if not ok then
  io.stderr:write(err .. '\n')
  vim.cmd 'cquit 1'
end
vim.cmd 'qa!'
