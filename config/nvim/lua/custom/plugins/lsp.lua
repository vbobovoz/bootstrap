-- Lazy LSP and Mason setup for supported languages.

local project = require 'custom.project'
local gh = require('custom.util').gh
local windows = require 'custom.features.windows'
local tools = require 'custom.tools'

vim.pack.add({ { src = gh 'saghen/blink.cmp', version = vim.version.range '1.*' } }, { load = function() end })

local lsp_initialized = false
local lsp_lazy_group = vim.api.nvim_create_augroup('custom-lsp-lazy-setup', { clear = true })
local mason_tool_installer
local tools_requested = {}
local tools_queue = {}
local active_tools_filetype

local tools_by_filetype = tools.by_filetype

-- Keep LSP actions under <leader>l instead of Neovim's default prefixes.
for _, mapping in ipairs {
  { 'n', 'grn' },
  { 'n', 'gra' },
  { 'x', 'gra' },
  { 'n', 'gri' },
  { 'n', 'grr' },
  { 'n', 'grt' },
  { 'n', 'grx' },
  { 'n', 'gO' },
  { 'i', '<C-s>' },
  { 's', '<C-s>' },
} do
  pcall(vim.keymap.del, mapping[1], mapping[2])
end

vim.keymap.set('n', '<leader>lr', vim.lsp.buf.rename, { desc = 'Rename symbol' })
vim.keymap.set({ 'n', 'x' }, '<leader>la', vim.lsp.buf.code_action, { desc = 'Code action' })
vim.keymap.set('n', '<leader>ld', function() Snacks.picker.lsp_definitions() end, { desc = 'Go to definition' })
vim.keymap.set('n', '<leader>lR', function() Snacks.picker.lsp_references() end, { desc = 'Find references' })
vim.keymap.set('n', '<leader>li', function() Snacks.picker.lsp_implementations() end, { desc = 'Go to implementation' })
vim.keymap.set('n', '<leader>lt', function() Snacks.picker.lsp_type_definitions() end, { desc = 'Go to type definition' })
vim.keymap.set('n', '<leader>lo', function() Snacks.picker.lsp_symbols() end, { desc = 'Find document symbols' })
vim.keymap.set('n', '<leader>lh', vim.lsp.buf.hover, { desc = 'Show hover documentation' })
vim.keymap.set('n', '<leader>ls', vim.lsp.buf.signature_help, { desc = 'Show signature help' })
vim.keymap.set('n', '<leader>lx', function() vim.lsp.codelens.run() end, { desc = 'Run CodeLens action' })

-- Ignore late highlight responses for buffers that have already closed.
local document_highlight_handler = vim.lsp.handlers['textDocument/documentHighlight']
vim.lsp.handlers['textDocument/documentHighlight'] = function(err, result, ctx, config)
  if not ctx or not vim.api.nvim_buf_is_valid(ctx.bufnr) then return end
  return document_highlight_handler(err, result, ctx, config)
end

---@type table<string, vim.lsp.Config>
local servers = {
  dockerls = {},
  gopls = {
    root_dir = function(bufnr, on_dir)
      local path = vim.api.nvim_buf_get_name(bufnr)
      if path == '' then return on_dir(vim.fn.getcwd()) end
      on_dir(vim.fs.root(path, { 'go.work', 'go.mod', '.git' }) or vim.fs.dirname(path))
    end,
    settings = {
      gopls = {
        completeUnimported = true,
        usePlaceholders = true,
        staticcheck = true,
      },
    },
  },

  jsonls = {},

  lua_ls = {
    settings = {
      Lua = {
        diagnostics = {
          globals = { 'vim', 'Snacks' },
        },
        workspace = {
          checkThirdParty = false,
          library = { vim.env.VIMRUNTIME },
        },
        telemetry = {
          enable = false,
        },
      },
    },
  },

  pyright = {
    root_markers = project.python_root_markers,
    settings = {
      python = {
        analysis = {
          autoImportCompletions = true,
          autoSearchPaths = true,
          useLibraryCodeForTypes = true,
          diagnosticMode = 'openFilesOnly',
        },
      },
    },
  },

  yamlls = {
    -- Helm owns chart templates and values, including its embedded YAML server.
    filetypes = { 'yaml', 'yaml.gitlab', 'yaml.docker-compose' },
    settings = {
      yaml = {
        format = { enable = false },
        validate = true,
        completion = true,
        hover = true,
        customTags = { '!reference sequence' },
        schemaStore = { enable = false, url = '' },
      },
    },
  },

  helm_ls = {
    settings = {
      ['helm-ls'] = {
        yamlls = {
          enabled = true,
          path = 'yaml-language-server',
          config = {
            schemas = { [require('custom.devops').kubernetes_schema()] = 'templates/**' },
            format = { enable = false },
            completion = true,
            hover = true,
          },
        },
      },
    },
  },

  bashls = {},
}

local function install_next_tools()
  if active_tools_filetype or #tools_queue == 0 then return end
  local filetype = table.remove(tools_queue, 1)
  active_tools_filetype = filetype

  -- Keep installer settings unchanged until its asynchronous check completes.
  local ok, err = pcall(function()
    mason_tool_installer.setup {
      ensure_installed = tools_by_filetype[filetype],
      run_on_start = false,
    }
    mason_tool_installer.check_install(false)
  end)
  if not ok then
    tools_requested[filetype] = nil
    active_tools_filetype = nil
    vim.notify('Mason: ' .. tostring(err), vim.log.levels.WARN)
    vim.schedule(install_next_tools)
  end
end

-- Install and enable language tooling only when a supported buffer is opened.
local function setup_lsp()
  if lsp_initialized then return end
  lsp_initialized = true
  pcall(vim.api.nvim_del_user_command, 'Mason')

  vim.pack.add {
    gh 'neovim/nvim-lspconfig',
    gh 'mason-org/mason.nvim',
    gh 'WhoIsSethDaniel/mason-tool-installer.nvim',
    gh 'b0o/SchemaStore.nvim',
  }

  servers.yamlls.settings.yaml.schemas = require('custom.devops').yaml_schemas()

  windows.prepend_path({ vim.fs.joinpath(vim.fn.stdpath 'data', 'mason', 'bin') }, { only_existing = false })
  require('mason').setup { PATH = 'skip' }

  mason_tool_installer = require 'mason-tool-installer'
  pcall(vim.api.nvim_del_user_command, 'MasonToolsClean')
  mason_tool_installer.setup {
    ensure_installed = {},
    run_on_start = false,
    integrations = {
      ['mason-lspconfig'] = false,
    },
  }

  vim.cmd.packadd 'blink.cmp'
  local blink_caps = require('blink.cmp').get_lsp_capabilities()

  for name, server in pairs(servers) do
    server.capabilities = vim.tbl_deep_extend('force', blink_caps, server.capabilities or {})
    local ok, err = pcall(function()
      vim.lsp.config(name, server)
      vim.lsp.enable(name)
    end)
    if not ok then vim.notify('LSP: setup error ' .. name .. ': ' .. tostring(err), vim.log.levels.WARN) end
  end

  vim.api.nvim_create_autocmd('User', {
    group = lsp_lazy_group,
    pattern = 'MasonToolsUpdateCompleted',
    callback = function(args)
      for _, package in ipairs(args.data or {}) do
        local server = tools.packages[package] and tools.packages[package].server
        if server then
          -- Already-enabled configs retry missing executables on subsequent files.
          -- Newly installed servers can attach immediately without killing live clients.
          vim.lsp.enable(server)
        end
      end

      if active_tools_filetype then
        local registry = require 'mason-registry'
        for _, name in ipairs(tools_by_filetype[active_tools_filetype]) do
          local ok, package = pcall(registry.get_package, name)
          if not ok or not package:is_installed() then
            -- A failed installation can be requested again by a later FileType event.
            tools_requested[active_tools_filetype] = nil
            break
          end
        end
        active_tools_filetype = nil
        vim.schedule(install_next_tools)
      end
    end,
    desc = 'Start newly installed language servers',
  })
end

---@param filetype string
local function ensure_tools(filetype)
  if tools_requested[filetype] then return end
  if not tools_by_filetype[filetype] then return end
  tools_requested[filetype] = true
  table.insert(tools_queue, filetype)
  install_next_tools()
end

-- Initialize before FileType for existing files; FileType covers new buffers.
vim.api.nvim_create_autocmd('BufReadPre', {
  group = lsp_lazy_group,
  pattern = {
    '*.go',
    '*.json',
    '*.jsonc',
    '*.lua',
    '*.py',
    '*.pyi',
    '*.yaml',
    '*.yml',
    'Dockerfile',
    'Dockerfile.*',
    '*.dockerfile',
    '*.Dockerfile',
    '*.tpl',
    '*.gotmpl',
    '*.sh',
    '*.bash',
    'Containerfile',
    'Containerfile.*',
  },
  callback = setup_lsp,
  desc = 'Initialize LSP on the first supported file',
})
vim.api.nvim_create_autocmd('FileType', {
  group = lsp_lazy_group,
  pattern = vim.tbl_keys(tools_by_filetype),
  callback = function(args)
    setup_lsp()
    ensure_tools(vim.bo[args.buf].filetype)
  end,
  desc = 'Initialize LSP for new supported buffers',
})
vim.api.nvim_create_user_command('Mason', function()
  setup_lsp()
  vim.cmd.Mason()
end, { desc = 'Initialize LSP tooling and open Mason' })
