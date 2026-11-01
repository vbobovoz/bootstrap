-- Inline AI suggestions with sensitive-file and gitignore filtering.
local M = {}

local sensitive_names = {
  ['.authinfo'] = true,
  ['.envrc'] = true,
  ['.git-credentials'] = true,
  ['.netrc'] = true,
  ['.npmrc'] = true,
  ['.pgpass'] = true,
  ['.pypirc'] = true,
  ['auth.json'] = true,
  ['credentials'] = true,
  ['credentials.json'] = true,
  ['htpasswd'] = true,
  ['kubeconfig'] = true,
  ['service-account.json'] = true,
  ['service_account.json'] = true,
  ['terraform.tfstate'] = true,
}

local sensitive_extensions = {
  age = true,
  gpg = true,
  jks = true,
  kdbx = true,
  key = true,
  keytab = true,
  keystore = true,
  p12 = true,
  pem = true,
  pfx = true,
  ppk = true,
  tfstate = true,
  tfvars = true,
}

local sensitive_directories = {
  ['.aws'] = true,
  ['.azure'] = true,
  ['.docker'] = true,
  ['.gnupg'] = true,
  ['.kube'] = true,
  ['.password-store'] = true,
  ['.secrets'] = true,
  ['.ssh'] = true,
  secrets = true,
}

---@type table<string, boolean>
local gitignore_cache = {}

---@param name string lowercase basename
---@return boolean
local function is_sensitive_name(name)
  if sensitive_names[name] then return true end

  local extension = name:match '%.([^%.]+)$'
  if extension and sensitive_extensions[extension] then return true end

  -- SSH private/public keys: id_rsa, id_ed25519.pub, id_ecdsa_sk, …
  if name:match '^id_[%w_-]+$' or name:match '^id_[%w_-]+%.pub$' then return true end

  if name == '.env' or name:match '^%.env[._-]' or name:match '%.env$' then return true end

  -- credential(s) anywhere in the basename (my-credentials.json, app_credential, …)
  if name:find('credential', 1, true) then return true end

  -- secret(s) as whole name or separated token
  if name == 'secret' or name == 'secrets' then return true end
  if name:match '[._-]secrets?[._-]' or name:match '^secrets?[._-]' or name:match '[._-]secrets?$' then return true end
  if name:match '[._-]tokens?[._-]' or name:match '^tokens?[._-]' or name:match '[._-]tokens?$' then return true end

  return false
end

---@param path string
---@return boolean
local function is_sensitive_path(path)
  local normalized = vim.fs.normalize(path):gsub('\\', '/')
  local name = vim.fs.basename(normalized):lower()

  if is_sensitive_name(name) then return true end

  for component in normalized:gmatch '[^/]+' do
    if sensitive_directories[component:lower()] then return true end
  end
  return false
end

---@param path string
---@return boolean
local function is_gitignored(path)
  if vim.fn.executable 'git' ~= 1 then return false end
  local normalized = vim.fs.normalize(path)
  local cached = gitignore_cache[normalized]
  if cached ~= nil then return cached end

  local root = vim.fs.root(normalized, '.git')
  if not root then
    gitignore_cache[normalized] = false
    return false
  end
  local relative = vim.fs.relpath(root, normalized) or normalized
  local out = vim.system({ 'git', '-C', root, 'check-ignore', '-q', '--', relative }, { text = true }):wait()
  local ignored = out.code == 0
  gitignore_cache[normalized] = ignored
  return ignored
end

local function clear_gitignore_cache() gitignore_cache = {} end

local gitignore_cache_group = vim.api.nvim_create_augroup('custom-codeium-gitignore-cache', { clear = true })

vim.api.nvim_create_autocmd({ 'DirChanged' }, {
  group = gitignore_cache_group,
  callback = clear_gitignore_cache,
  desc = 'Clear cached gitignore results after changing directory',
})

vim.api.nvim_create_autocmd('BufWritePost', {
  group = gitignore_cache_group,
  callback = function(args)
    local path = vim.fs.normalize(vim.api.nvim_buf_get_name(args.buf)):gsub('\\', '/')
    if path:match '/%.gitignore$' or path:match '/%.git/info/exclude$' then clear_gitignore_cache() end
  end,
  desc = 'Clear cached gitignore results after ignore rules change',
})

vim.api.nvim_create_autocmd('User', {
  group = gitignore_cache_group,
  pattern = 'ResessionLoadPost',
  callback = clear_gitignore_cache,
  desc = 'Clear cached gitignore results after switching sessions',
})

function M.filter(buf)
  if not vim.api.nvim_buf_is_valid(buf) or vim.b[buf].custom_inline_ai == false then return false end
  local path = vim.api.nvim_buf_get_name(buf)
  return path ~= '' and not is_sensitive_path(path) and not is_gitignored(path)
end

function M.map_keys()
  local neo = package.loaded.neocodeium
  if not neo then return end

  vim.keymap.set('i', '<Tab>', function()
    if neo.visible() then
      neo.accept()
      return
    end
    if vim.snippet.active { direction = 1 } then
      vim.snippet.jump(1)
      return
    end
    vim.api.nvim_feedkeys(vim.keycode '<Tab>', 'n', false)
  end, { silent = true, desc = 'Accept suggestion, jump snippet, or insert tab' })

  vim.keymap.set('i', '<C-]>', neo.clear, { desc = 'Dismiss AI suggestion' })
  vim.keymap.set('i', '<M-]>', function() neo.cycle(1) end, { desc = 'Show next AI suggestion' })
  vim.keymap.set('i', '<M-[>', function() neo.cycle(-1) end, { desc = 'Show previous AI suggestion' })
  vim.keymap.set('i', '<M-l>', neo.accept_word, { desc = 'Accept AI suggestion word' })
  vim.keymap.set('i', '<M-j>', neo.accept_line, { desc = 'Accept AI suggestion line' })
end

-- Keep headless checks free of AI server jobs and downloads.
if #vim.api.nvim_list_uis() == 0 then return M end

local gh = require('custom.util').gh
vim.pack.add { gh 'monkoose/neocodeium' }
require('neocodeium').setup {
  max_lines = 0,
  filter = M.filter,
  filetypes = { bigfile = false },
}

vim.api.nvim_create_autocmd('User', {
  group = vim.api.nvim_create_augroup('custom-neocodeium-session', { clear = true }),
  pattern = 'ResessionLoadPost',
  callback = function()
    vim.cmd 'doautoall <nomodeline> neocodeium BufAdd'
    vim.cmd 'doautocmd <nomodeline> neocodeium DirChanged'
  end,
})

return M
