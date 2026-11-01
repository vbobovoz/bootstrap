-- Automatic bracket and quote pairing.
-- Loaded by custom.plugins.init.

local gh = require('custom.util').gh

vim.pack.add { gh 'windwp/nvim-autopairs' }

require('nvim-autopairs').setup {
  check_ts = true,
  ts_config = {
    lua = { 'string', 'source' },
    go = { 'string', 'raw_string' },
    python = { 'string' },
    javascript = { 'string', 'template_string' },
  },
  enable_afterquote = true,
  enable_check_bracket_line = true,
  enable_bracket_in_quote = true,
  fast_wrap = {
    map = '<M-e>',
    chars = { '{', '[', '(', '"', "'", '`' },
    pattern = [=[[%'%"%>%]%)%}%,]]=],
    end_key = '$',
    before_key = 'h',
    after_key = 'l',
    keys = 'qwertyuiopzxcvbnmasdfghjkl',
  },
}
