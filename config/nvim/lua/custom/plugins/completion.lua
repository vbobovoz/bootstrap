-- Blink completion UI and snippet behavior.
-- Loaded by custom.plugins.init after LSP capabilities are available.

-- Delay completion setup until insert mode is used for the first time.
vim.api.nvim_create_autocmd('InsertEnter', {
  once = true,
  callback = function()
    require('blink.cmp').setup {
      keymap = {
        ['<C-Space>'] = { 'show', 'show_documentation', 'hide_documentation' },
        ['<C-n>'] = { 'select_next', 'fallback' },
        ['<C-p>'] = { 'select_prev', 'fallback' },
        ['<CR>'] = { 'accept', 'fallback' },
        ['<Tab>'] = false,
        ['<S-Tab>'] = false,
      },

      appearance = {
        nerd_font_variant = 'mono',
      },

      completion = {
        menu = { auto_show = true },
        documentation = { auto_show = true, auto_show_delay_ms = 500 },
        trigger = {
          prefetch_on_insert = true,
          show_on_keyword = true,
          show_on_trigger_character = true,
        },
        list = {
          selection = {
            preselect = function() return not require('blink.cmp').snippet_active { direction = 1 } end,
            auto_insert = false,
          },
        },
      },

      sources = {
        default = { 'lsp', 'snippets', 'path', 'buffer' },
      },

      snippets = { preset = 'default' },

      fuzzy = { implementation = 'prefer_rust_with_warning' },

      signature = { enabled = true },
    }
    require('custom.plugins.inline').map_keys()
  end,
})
