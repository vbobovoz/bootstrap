-- Shared file detection and YAML schemas for infrastructure projects.
local M = {}

local function chart_file(path)
  local root = vim.fs.root(path, 'Chart.yaml')
  if not root then return end
  local relative = vim.fs.relpath(root, path)
  if relative and relative:match '^templates/' then return 'helm' end
  if vim.fs.basename(path):match '^values.*%.ya?ml$' then return 'yaml.helm-values' end
end

function M.setup()
  vim.filetype.add {
    filename = {
      ['.gitlab-ci.yml'] = 'yaml.gitlab',
      ['.gitlab-ci.yaml'] = 'yaml.gitlab',
    },
    pattern = {
      ['.*/templates/.*%.yaml'] = { chart_file, { priority = 100 } },
      ['.*/templates/.*%.yml'] = { chart_file, { priority = 100 } },
      ['.*/templates/.*%.tpl'] = { chart_file, { priority = 100 } },
      ['.*/templates/.*%.txt'] = { chart_file, { priority = 100 } },
      ['.*/values[^/]*%.yaml'] = { chart_file, { priority = 100 } },
      ['.*/values[^/]*%.yml'] = { chart_file, { priority = 100 } },
      ['.*%.gotmpl'] = 'helm',
      ['.*/Dockerfile%.[^/]+'] = 'dockerfile',
      ['.*/[^/]+%.Dockerfile'] = 'dockerfile',
      ['.*/%.gitlab/.*%.ya?ml'] = 'yaml.gitlab',
    },
  }
  vim.api.nvim_create_autocmd('FileType', {
    pattern = { 'yaml', 'yaml.*', 'helm' },
    callback = function()
      vim.bo.expandtab = true
      vim.bo.tabstop = 2
      vim.bo.softtabstop = 2
      vim.bo.shiftwidth = 2
      if vim.bo.filetype == 'helm' then vim.bo.commentstring = '{{/* %s */}}' end
    end,
  })
end

-- Override with a versioned schema URL/path per project when necessary.
function M.kubernetes_schema() return vim.env.NVIM_KUBERNETES_SCHEMA or 'kubernetes' end

function M.yaml_schemas()
  local schemas = require('schemastore').yaml.schemas()
  schemas[M.kubernetes_schema()] = {
    '**/k8s/**/*.yaml',
    '**/k8s/**/*.yml',
    '**/kubernetes/**/*.yaml',
    '**/kubernetes/**/*.yml',
    '*.k8s.yaml',
    '*.k8s.yml',
  }
  return schemas
end

return M
