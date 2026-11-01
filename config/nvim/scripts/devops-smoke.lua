-- Run after init.lua. No cluster or Docker daemon is needed.
local function check()
  assert(vim.g.colors_name == 'kanagawa', 'Kanagawa must be active')
  assert(require('kanagawa')._CURRENT_THEME == 'wave', 'Wave variant must be active')
  assert(vim.api.nvim_get_hl(0, { name = 'Normal' }).bg == tonumber('16161d', 16), 'Dark background must be active')
  local root = vim.fn.tempname()
  vim.fn.mkdir(root .. '/chart/templates/nested', 'p')
  vim.fn.mkdir(root .. '/plain/templates', 'p')
  vim.fn.writefile({ 'apiVersion: v2', 'name: test', 'version: 0.1.0' }, root .. '/chart/Chart.yaml')
  local cases = {
    ['chart/templates/deployment.yaml'] = 'helm',
    ['chart/templates/nested/service.yml'] = 'helm',
    ['chart/templates/_helpers.tpl'] = 'helm',
    ['chart/templates/NOTES.txt'] = 'helm',
    ['chart/values.yaml'] = 'yaml.helm-values',
    ['chart/values.production.yml'] = 'yaml.helm-values',
    ['plain/templates/config.yaml'] = 'yaml',
    ['plain/values.yaml'] = 'yaml',
    ['plain/.gitlab-ci.yml'] = 'yaml.gitlab',
    ['plain/.gitlab/build.yaml'] = 'yaml.gitlab',
    ['plain/Dockerfile.production'] = 'dockerfile',
    ['plain/test.sh'] = 'sh',
  }
  for relative, expected in pairs(cases) do
    local actual = vim.filetype.match { filename = root .. '/' .. relative }
    assert(actual == expected, relative .. ': expected ' .. expected .. ', got ' .. tostring(actual))
  end

  vim.bo.filetype = 'yaml'
  local yaml = vim.lsp.config.yamlls
  assert(not vim.tbl_contains(yaml.filetypes, 'helm'), 'YAML LSP must not attach to templates')
  assert(not vim.tbl_contains(yaml.filetypes, 'yaml.helm-values'), 'Helm must own chart values')
  assert(vim.tbl_contains(yaml.settings.yaml.customTags, '!reference sequence'), 'GitLab references must be accepted')
  assert(yaml.settings.yaml.schemas[require('custom.devops').kubernetes_schema()], 'Kubernetes schema missing')
  assert(vim.lsp.config.helm_ls.settings['helm-ls'].yamlls.enabled, 'Helm YAML integration must be enabled')
  assert(vim.lsp.config.gopls.settings.gopls.completeUnimported, 'Go completion must include unimported packages')
  assert(vim.lsp.config.dockerls.cmd, 'Docker LSP missing')
  assert(vim.lsp.config.bashls.cmd, 'Bash LSP missing')

  local conform = require 'conform'
  local buf = vim.api.nvim_create_buf(true, false)
  vim.api.nvim_set_current_buf(buf)
  vim.bo.filetype = 'yaml'
  assert(conform.formatters_by_ft.yaml[1] == 'prettier', 'YAML formatter must be Prettier')
  assert(conform.formatters_by_ft.sh[1] == 'shfmt', 'Shell formatter must be shfmt')
  assert(conform.formatters_by_ft.helm == nil, 'Helm must have no formatter')
  assert(vim.bo.shiftwidth == 2 and vim.bo.expandtab, 'YAML must use two spaces')
  vim.bo.filetype = 'dockerfile'
  vim.api.nvim_buf_set_name(buf, root .. '/Dockerfile')
  assert(vim.wait(1000, function() return package.loaded.lint ~= nil end), 'Lint configuration must load for Dockerfiles')
  assert(require('lint').linters_by_ft.dockerfile[1] == 'hadolint', 'Dockerfile linter missing')
  vim.bo.filetype = 'sh'
  assert(require('lint').linters_by_ft.sh[1] == 'shellcheck', 'ShellCheck missing')
  vim.bo.filetype = 'helm'
  assert(vim.bo.commentstring == '{{/* %s */}}', 'Helm comments must use template syntax')
  assert(vim.treesitter.language.get_lang 'helm' == 'gotmpl', 'Helm must use the Go template parser')
  vim.api.nvim_buf_delete(buf, { force = true })
  vim.fn.delete(root, 'rf')
end

local ok, err = xpcall(check, debug.traceback)
if not ok then
  io.stderr:write(err .. '\n')
  vim.cmd 'cquit 1'
end
print 'DevOps configuration checks passed'
vim.cmd 'qa!'
