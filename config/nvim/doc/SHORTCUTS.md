# Neovim Shortcuts

Keybindings reference for the current configuration (`~/.config/nvim`).

**Leader** and **localleader**: `<Space>` (spacebar).

Prefix hints: press leader and wait — **which-key** will open (`delay = 200`).

Full list at runtime: `<Space>fk` (Snacks → keymaps) or `:WhichKey`.

---

## Dashboard

The Snacks dashboard opens when Neovim starts without a file or directory argument.

| Key | Action |
|---------|----------|
| `f` | Find file |
| `g` | Grep project |
| `r` | Recent files |
| `p` | Projects |
| `s` | Load session |
| `c` | Browse Neovim config |
| `o` | Open Yazi |
| `q` | Quit |

It also shows up to five recent sessions on `1`–`5`, up to five recent files on `6`–`0`, and the measured configuration startup time. The full projects picker remains available on `p`.

---

## General

| Key | Mode | Action |
|---------|-------|----------|
| `<Esc>` | n | Clear search highlight (`nohlsearch`) |
| `<Space>w` | n | Save file |
| `<Space>q` | n | Quit (`:q`) |
| `<Space>Q` | n | Force-quit all windows (`:qa!`) |
| `<Space>v` | n | Open a vertical split |
| `<Space>m` | n | Open the Snacks dashboard |

**Saving** (regular files on disk): manually via `<Space>w`. On focus loss from Neovim (`FocusLost` — switching to another app), only the current buffer is saved; other modified buffers are left untouched. Saving triggers `format_on_save` and other `:w` hooks. Terminal, Snacks picker, and unnamed buffers are ignored.

| `<C-h>` / `<C-j>` / `<C-k>` / `<C-l>` | n | Focus left / bottom / top / right window |
| `<Esc><Esc>` | t | Exit terminal mode (instead of `<C-\><C-n>`) |

Commented out (inactive): `<C-S-hjkl>` — swap splits.

---

## File Navigation

### Go to Line

| Key | Mode | Action |
|---------|-------|----------|
| `:N` | n | Go to line N (e.g., `:42`) |

### Search in Buffer

| Key | Mode | Action |
|---------|-------|----------|
| `/` / `?` | n | Search forward / backward, `n` / `N` — next match |
| `<Space>/` | n | Snacks: search in **current** buffer |
| `*` / `#` | n | All occurrences of the word under cursor |

### LSP, Diagnostics, Git (in current file)

| Key | Mode | Action |
|---------|-------|----------|
| `gd` | n | Go to definition (LSP) |
| `gr` | n | References (LSP) |
| `<C-t>` | n | Jump back (jumplist) |
| `[d` / `]d` | n | Prev./next diagnostic (float on jump) |
| `[c` / `]c` | n | Prev./next git hunk (in git repo) |

### Basic (Vim)

| Key | Action |
|---------|----------|
| `gg` / `G` | First / last line (standard Vim) |
| `0` / `$` / `^` | Start / end / first non-blank character of line |
| `%` | Matching bracket |
| `{` / `}` | Previous / next paragraph |
| `[.` | Go to the beginning of the current Treesitter context |
| `<Space>j` | Flash jump to a visible location |

---

## File Manager (Snacks Explorer)

| Key | Mode | Action |
|---------|-------|----------|
| `\` | n | Open or close Snacks Explorer |
| `\` | in explorer window | Close explorer |

The explorer follows the current file and shows Git and diagnostic status. Press `?` inside it for all file-operation mappings.

### Yazi

| Key | Mode | Action |
|---------|-------|----------|
| `<Space>o` | n | Open Yazi for the current file or directory |

This mapping is available only when the `yazi` executable is installed.

---

## Buffers

| Key | Mode | Action |
|---------|-------|----------|
| `H` | n | Previous buffer (`bprevious`) |
| `L` | n | Next buffer (`bnext`) |
| `<Space>c` | n | Close buffer while preserving the window layout |
| `<Space>C` | n | Close other regular file buffers |

Bottom tabs — **bufferline** (mouse switching / standard Neovim commands).

---

## Search (Snacks Picker) — prefix `<Space>f`

| Key | Mode | Action |
|---------|-------|----------|
| `<Space>fb` | n | List of open buffers |
| `<Space>ff` | n | Files in project |
| `<Space>fg` | n | Grep in project (literal search by default) |
| `<Space>fw` | n, v | Grep word under cursor / selection |
| `<Space>f/` | n | Search in open buffers |
| `<Space>/` | n | Search in current buffer |
| `<Space>fd` | n | Diagnostics (picker) |
| `<Space>fH` | n | Help tags |
| `<Space>fk` | n | All keymaps |
| `<Space>fs` | n | List of Snacks pickers |
| `<Space>fr` | n | Resume last picker |
| `<Space>f.` | n | Recent files |
| `<Space>fh` | n | Vim search history (`/`) |
| `<Space>fc` | n | Vim commands |
| `<Space>fn` | n | Neovim config files |
| `<Space>fp` | n | Recent projects; selection changes the tab working directory and opens its files |

### In Snacks picker

| Key | Action |
|---------|----------|
| `<C-Up>` / `<C-Down>` | Previous / next query from history |
| `<Esc>` | Close picker |
| `<Tab>` / `<S-Tab>` | Toggle selection and move to the next / previous item |
| `<C-a>` | Select all results, or clear selection when all are selected |
| `<C-q>` | Send selected results—or all results when none are selected—to quickfix |
| `<C-s>` / `<C-v>` / `<C-t>` | Open in split / vertical split / tab |
| `?` | Show picker shortcuts in normal mode |

Project search uses **ripgrep**. Literal matching is the default; `<M-r>` toggles regular expressions in the picker.

---

## LSP (only when LSP is attached to the buffer)

### Navigation and Edits

| Key | Mode | Action |
|---------|-------|----------|
| `gd` | n | Go to definition |
| `gr` | n | References |

After jumping "back": `<C-t>` (Neovim standard). Definitions and references are shown through the Snacks LSP picker.

Highlighting references to the word under cursor is automatic on `CursorHold` (no separate shortcut).

---

## Diagnostics

| Key | Mode | Action |
|---------|-------|----------|
| `[d` | n | Previous diagnostic (built-in Neovim) |
| `]d` | n | Next diagnostic; opens float on jump |

---

## Formatting

| Key | Mode | Action |
|---------|-------|----------|
| `<Space>F` | n, v | Format buffer / selection (organize imports, fix, format) |

Additionally, format-on-save uses Ruff for Python, goimports/gofumpt for Go, and StyLua for Lua. Other filetypes are formatted only through the manual mapping.

---

## Tests (Neotest) — prefix `<Space>t`

Python tests run with pytest; Go tests run with the Go toolchain.

| Key | Mode | Action |
|---------|-------|----------|
| `<Space>tn` | n | Run the nearest test |
| `<Space>tf` | n | Run all tests in the current file |
| `<Space>tl` | n | Repeat the last test run |
| `<Space>ts` | n | Open or close the test summary |
| `<Space>to` | n | Open the output of the nearest test |

---

## Git

### LazyGit / Repository Operations

| Key | Action |
|---------|----------|
| `<Space><Space>` | Open LazyGit |
| `<Space>gc` | Show the commit for the line under the cursor |
| `<Space>gb` | Git branches |
| `<Space>gl` | Git log |
| `<Space>gs` | Git status |
| `<Space>gd` | Git diff |
| `<Space>go` | Open the current file/lines in the Git web interface |

### In LazyGit (`<Space><Space>`)

LazyGit shortcuts depend on the active panel. Press `?` to show contextual help and `q` to close the current view.

### Gitsigns (in git repository, on buffer)

| Key | Mode | Action |
|---------|-------|----------|
| `]c` | n | Next hunk (in diff — standard `]c`) |
| `[c` | n | Previous hunk |

---

## Sessions — prefix `<Space>s`

| Key | Action |
|---------|----------|
| `<Space>ss` | Save named session |
| `<Space>sl` | Load (picker) |
| `<Space>sd` | Delete (picker) |
| `<Space>sx` | Detach current session |

Auto-save on exit — only if session is already attached (`resession`).

---

## Terminal (Snacks)

| Key | Action |
|---------|----------|
| `<C-\>` | Open / close terminal (horizontal, 15 lines) |

Starts in the current project directory without activating virtual environments or running Poetry.

---

## AI CLI (Sidekick) — prefix `<Space>a`

| Key | Mode | Action |
|---------|-------|----------|
| `<Space>aa` | n, t | Open or close the current AI CLI |
| `<Space>as` | n | Select an installed AI CLI |
| `<Space>ad` | n | Detach and close the current AI CLI session |
| `<Space>at` | n, v | Send the item under the cursor or selection |
| `<Space>af` | n | Send the current file |
| `<Space>ap` | n, v | Open the prompt picker |

---

## Autocompletion (blink.cmp + LSP)

Import, function, type hints, etc. come from LSP (e.g., pyright) via blink.cmp.

| Key | Action |
|---------|----------|
| `<CR>` | Accept the selected Blink item; otherwise insert a newline |
| `<Tab>` | Accept a NeoCodeium inline suggestion when present; otherwise insert a tab |
| `<C-]>` | Dismiss the current NeoCodeium suggestion |
| `<M-]>` / `<M-[>` | Next / previous NeoCodeium suggestion |
| `<M-l>` | Accept the next word of a NeoCodeium suggestion |
| `<M-j>` | Accept the next line of a NeoCodeium suggestion |
| `<C-y>` | Accept (preset `default`) |
| `<C-n>` / `<C-p>` | Next / previous item |
| `<C-e>` | Close menu |
| `<C-space>` | Show / hide documentation |

See `:help blink-cmp-config-keymap`.

---

## Text Objects and Surround (mini.nvim)

### mini.ai

| Pattern | Action |
|---------|----------|
| `aa` / `ii` | Around / inside the next text object |

Examples: `vaa)`, `ciq`, `yaiw`.

### mini.surround

| Pattern | Action |
|---------|----------|
| `sa…` | Add surround |
| `sd…` | Delete surround |
| `sr…` | Replace surround |

Example: `saiw)` — surround add inner word paren.

---

## nvim-autopairs

| Key | Action |
|---------|----------|
| `<M-e>` | Fast wrap — jump after closing bracket/quote |

Auto-insertion of `()`, `""`, `` ` ``, etc. — on typing, no separate shortcut.

---

## Which-Key Prefix Summary

| Prefix | Group |
|---------|--------|
| `<Space>a` | AI CLI (Sidekick) |
| `<Space>f` | Find (Snacks) |
| `<Space>g` | Git |
| `<Space>s` | Session |
| `<Space>t` | Tests |
| `gr` | LSP actions (group hint) |

---

## Where to Edit

| Area | File |
|---------|------|
| Options and platform bootstrap | `lua/custom/options.lua` |
| Global keymaps and autocommands | `lua/custom/keymaps.lua`, `lua/custom/autocmds.lua` |
| Plugin loading order | `lua/custom/plugins/init.lua` |
| UI integration and components | `lua/custom/plugins/ui.lua`, `lua/custom/ui/` |
| Editor behavior and workspace | `lua/custom/plugins/editor.lua`, `workspace.lua` |
| Picker, explorer, notifications, and utilities | `lua/custom/plugins/snacks.lua` |
| LSP, completion, formatting | `lua/custom/plugins/lsp.lua`, `completion.lua`, `formatting.lua` |
| Gitsigns and Snacks LazyGit mapping | `lua/custom/plugins/git.lua` |
| Sessions | `lua/custom/plugins/sessions.lua` |
| Treesitter and autopairs | `lua/custom/plugins/treesitter.lua`, `autopairs.lua` |
| Tests (Neotest) | `lua/custom/plugins/neotest.lua` |
| Reusable feature logic | `lua/custom/features/` |
| Optional lint setup | `lua/custom/plugins/lint.lua` |

---

*Generated from current configuration state. For actual list in Neovim session: `<Space>fk`.*


## Arrow selection

| Key | Action |
|-----|--------|
| `Shift` + arrows | Start or extend a characterwise selection (also from Insert mode) |
| `Ctrl` + Left / Right | Jump between words |
| `Ctrl` + `Shift` + Left / Right | Extend or shrink the selection by words |
| `y` while selecting | Copy selection to the system clipboard |
| Plain arrows / `Esc` | End selection |

Selection ends before the cursor, as in an IDE. Press `i` to resume typing after copying.
Ghostty forwards these keys to Neovim; terminal split navigation uses `Cmd+Ctrl` + arrows.


## Дополнительные команды объединённого конфига

| Клавиши | Действие |
|---|---|
| `Space b` | Список открытых буферов (дополнительно к `Space f b`) |
| `Space l r` | Переименовать символ |
| `Space l a` | Code action |
| `Space l d/R/i/t` | Определение / использования / реализации / определение типа |
| `Space l o` | Символы текущего файла |
| `Space l h/s/x` | Документация / сигнатура / CodeLens |
| `Space u a` | Автосохранение при потере фокуса |
| `Space u f` | Форматирование при сохранении |
| `Space u d` | Диагностика |
| `Space u v` | Ошибки отдельными строками под курсором / прежний текст справа |
| `Space u r` | Относительные номера текущего окна |
| `Space u c` | Treesitter-контекст |
| `Space u n` | AI-подсказки текущего буфера |
| `Space g a` | Stage/unstage текущего Git hunk; в Visual — выделенных строк |
| `Space g r/h` | Reset/preview Git hunk |
| `Space g f` | История текущего файла |
| `Space g L` | История текущей строки |
| `Alt+h/j/k/l` | mini.move: переместить строку в Normal или текст в Visual |
| `f/F/t/T` | mini.jump: переход к символу с повторением |

`Space o` по-прежнему открывает Yazi, `Space j` — Flash, `H/L` переключают буферы.
Поэтому переключатели из внешнего конфига перенесены с `Space o …` на `Space u …`.
