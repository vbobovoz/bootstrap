-- Treesitter parsers, highlighting, indentation, and context.
-- Loaded by custom.plugins.init.

local gh = require('custom.util').gh

vim.pack.add {
  { src = gh 'nvim-treesitter/nvim-treesitter', version = 'main' },
  { src = gh 'hiphish/rainbow-delimiters.nvim' },
  { src = gh 'nvim-treesitter/nvim-treesitter-context' },
}

-- On a clean deployment this directory did not exist when Neovim built its
-- initial runtimepath. Register it explicitly so newly installed parsers load
-- in the same session rather than only after a restart.
require('nvim-treesitter').setup { install_dir = vim.fs.joinpath(vim.fn.stdpath 'data', 'site') }

local parsers = {
  'bash',
  'dockerfile',
  'gotmpl',
  'c',
  'diff',
  'html',
  'lua',
  'luadoc',
  'markdown',
  'markdown_inline',
  'query',
  'regex',
  'vim',
  'vimdoc',
  'yaml',
  'json',
  'go',
  'python',
}

-- Skip parser features for large files to keep editing responsive.
local max_treesitter_file_size = 2 * 1024 * 1024

vim.treesitter.language.register('gotmpl', 'helm')

---@param buf integer
---@return boolean
local function is_large_file(buf)
  local path = vim.api.nvim_buf_get_name(buf)
  if path == '' then return false end
  local stat = vim.uv.fs_stat(path)
  return stat ~= nil and stat.size > max_treesitter_file_size
end

---@param buf integer
---@param language string
local function treesitter_try_attach(buf, language)
  if not vim.treesitter.language.add(language) then return end
  vim.treesitter.start(buf, language)

  local has_indent_query = vim.treesitter.query.get(language, 'indents') ~= nil

  if has_indent_query then vim.bo[buf].indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()" end
end

local available_set = {}
for _, p in ipairs(require('nvim-treesitter').get_available()) do
  available_set[p] = true
end

local installed_set = {}
local function refresh_installed_set()
  installed_set = {}
  for _, p in ipairs(require('nvim-treesitter').get_installed 'parsers') do
    installed_set[p] = true
  end
end
refresh_installed_set()

vim.api.nvim_create_autocmd('VimEnter', {
  once = true,
  callback = function()
    vim.schedule(function()
      local missing = vim.tbl_filter(function(parser) return not installed_set[parser] end, parsers)
      if #missing == 0 then return end
      require('nvim-treesitter').install(missing):await(refresh_installed_set)
    end)
  end,
})

vim.api.nvim_create_autocmd('FileType', {
  callback = function(args)
    local buf, filetype = args.buf, args.match

    if is_large_file(buf) then
      vim.treesitter.stop(buf)
      return
    end

    local language = vim.treesitter.language.get_lang(filetype)
    if not language then return end

    if installed_set[language] then
      treesitter_try_attach(buf, language)
    elseif available_set[language] then
      require('nvim-treesitter').install(language):await(function()
        installed_set[language] = true
        treesitter_try_attach(buf, language)
      end)
    else
      treesitter_try_attach(buf, language)
    end
  end,
})

require('rainbow-delimiters.setup').setup {
  condition = function(buf) return not is_large_file(buf) end,
  highlight = {
    'RainbowDelimiterRed',
    'RainbowDelimiterYellow',
    'RainbowDelimiterBlue',
    'RainbowDelimiterOrange',
    'RainbowDelimiterGreen',
    'RainbowDelimiterViolet',
    'RainbowDelimiterCyan',
  },
}

require('treesitter-context').setup {
  max_lines = 2,
  on_attach = function(buf) return not is_large_file(buf) end,
}
vim.keymap.set('n', '[.', function() require('treesitter-context').go_to_context() end, { desc = 'Go to context start' })
