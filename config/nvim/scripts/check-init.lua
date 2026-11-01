-- Test-only entry point. Production startup continues to use init.lua directly.
local mode = assert(vim.env.CUSTOM_NVIM_CHECK_MODE)
local config = mode == 'bootstrap' and vim.fn.stdpath 'config' or vim.fn.getcwd()
vim.opt.runtimepath:prepend(config)

if mode == 'bootstrap' then
  -- Explicit clean-deployment check: downloads only into the temporary data dir.
  local add = vim.pack.add
  vim.pack.add = function(specs, opts)
    opts = vim.tbl_extend('force', opts or {}, { confirm = false })
    return add(specs, opts)
  end
else
  local site = assert(vim.env.CUSTOM_NVIM_INSTALLED_SITE)
  local plugins = vim.fs.joinpath(site, 'pack', 'core', 'opt')
  local lock = vim.json.decode(table.concat(vim.fn.readfile(vim.fs.joinpath(config, 'nvim-pack-lock.json')), '\n'))
  for name in pairs(lock.plugins) do
    assert(
      vim.fn.isdirectory(vim.fs.joinpath(plugins, name)) == 1,
      'Missing installed plugin: ' .. name .. '. Install plugins normally before running quick checks.'
    )
  end
  vim.opt.packpath:prepend(site)
  vim.opt.runtimepath:append(site)

  -- Use :packadd against existing checkouts; never let quick checks invoke the
  -- package manager or change the production lockfile/plugin directories.
  local seen, initializing = {}, true
  vim.pack.add = function(specs, opts)
    for _, spec in ipairs(specs) do
      spec = type(spec) == 'string' and { src = spec } or spec
      local name = spec.name or spec.src:match '([^/]+)$'
      local path = vim.fs.joinpath(plugins, name)
      assert(vim.fn.isdirectory(path) == 1, 'Missing installed plugin: ' .. name)
      if not seen[name] then
        seen[name] = true
        local load = opts and opts.load
        if load == nil then load = not initializing end
        if type(load) == 'function' then
          load { spec = spec, path = path }
        else
          vim.cmd.packadd { name, bang = not load }
        end
      end
    end
  end

  -- These checks exercise setup and behavior without starting real servers.
  vim.lsp.enable = function() end
  vim.opt.runtimepath:remove(vim.fs.joinpath(vim.fn.stdpath 'data', 'site'))
  package.preload['mason-tool-installer'] = function()
    return { setup = function() end, check_install = function() end, run_on_start = function() end }
  end
  dofile(vim.fs.joinpath(config, 'init.lua'))
  initializing = false
  -- Missing parsers are allowed in quick checks; installation is a separate task.
  require('nvim-treesitter').install = function()
    return { await = function(_, callback) callback(nil, false) end }
  end
  return
end

dofile(vim.fs.joinpath(config, 'init.lua'))
