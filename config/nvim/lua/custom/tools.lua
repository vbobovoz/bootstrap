-- Language tool inventory shared by installation and health checks.
local M = {}

M.by_filetype = {
  dockerfile = { 'dockerfile-language-server', 'hadolint' },
  go = { 'gopls', 'goimports', 'gofumpt', 'golangci-lint' },
  helm = { 'helm-ls', 'yaml-language-server' },
  json = { 'json-lsp' },
  jsonc = { 'json-lsp' },
  lua = { 'lua-language-server', 'stylua' },
  python = { 'pyright', 'ruff' },
  yaml = { 'yaml-language-server', 'prettier', 'yamllint' },
}

M.by_filetype.sh = { 'bash-language-server', 'shellcheck', 'shfmt' }
M.by_filetype.bash = M.by_filetype.sh
M.by_filetype['yaml.helm-values'] = { 'helm-ls', 'yaml-language-server', 'prettier', 'yamllint' }

M.by_filetype['yaml.docker-compose'] = M.by_filetype.yaml
M.by_filetype['yaml.gitlab'] = M.by_filetype.yaml

M.packages = {
  ['bash-language-server'] = { label = 'Bash language server', executable = 'bash-language-server', server = 'bashls' },
  shellcheck = { label = 'ShellCheck', executable = 'shellcheck' },
  shfmt = { label = 'shfmt', executable = 'shfmt' },
  ['dockerfile-language-server'] = { label = 'Dockerfile language server', executable = 'docker-langserver', server = 'dockerls' },
  hadolint = { label = 'Hadolint', executable = 'hadolint' },
  ['helm-ls'] = { label = 'Helm language server', executable = 'helm_ls', server = 'helm_ls' },
  gopls = { label = 'gopls', executable = 'gopls', server = 'gopls' },
  goimports = { label = 'goimports', executable = 'goimports' },
  gofumpt = { label = 'gofumpt', executable = 'gofumpt' },
  ['golangci-lint'] = { label = 'golangci-lint', executable = 'golangci-lint' },
  ['json-lsp'] = { label = 'JSON language server', executable = 'vscode-json-language-server', server = 'jsonls' },
  ['lua-language-server'] = { label = 'Lua language server', executable = 'lua-language-server', server = 'lua_ls' },
  stylua = { label = 'StyLua', executable = 'stylua' },
  pyright = { label = 'Pyright', executable = 'pyright-langserver', server = 'pyright' },
  ruff = { label = 'Ruff', executable = 'ruff' },
  prettier = { label = 'Prettier', executable = 'prettier' },
  yamllint = { label = 'yamllint', executable = 'yamllint' },
  ['yaml-language-server'] = { label = 'YAML language server', executable = 'yaml-language-server', server = 'yamlls' },
}

return M
