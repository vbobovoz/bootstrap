# Bootstrap

A terminal and development environment for macOS and Ubuntu, with Ghostty, Zsh,
Starship, Neovim, Lazygit, Yazi, and everyday CLI tools. Configuration lives in
this repository and can be applied as a complete setup or one component at a time.

## Supported platforms

- **macOS** with [Homebrew](https://brew.sh/).
- **Ubuntu 24.04 and 26.04 LTS**, with amd64 and arm64 binaries.

Other package-manager backends are included but have not been validated for the
complete setup. See [platform validation](tests/VALIDATION.md) for test coverage.

## Set up a new machine

### macOS prerequisites

Install the Xcode Command Line Tools and wait for installation to finish:

```bash
xcode-select --install
```

Install [Homebrew](https://brew.sh/) and follow its instructions to add
`brew shellenv` to your shell environment. Bootstrap expects Homebrew to be
available; it does not install it.

### Ubuntu prerequisites

Use an account with `sudo` access and enable the Ubuntu `universe` repository.
Install curl, Git, and CA certificates:

```bash
sudo apt-get update
sudo apt-get install -y curl git ca-certificates
```

The full setup includes Ghostty and is intended for a graphical desktop.
For a server, install only the components you need.

### Install

After completing the prerequisites, run the full installer with one command:

```bash
bash -c "$(curl -fsSL https://raw.githubusercontent.com/vbobovoz/bootstrap/main/bootstrap.sh)" --
```

This downloads the `main` branch into a temporary directory, runs the installer,
and removes the temporary files afterward. It requires the repository to be
publicly accessible. You can pass the same options as `install.sh`, for example:

```bash
bash -c "$(curl -fsSL https://raw.githubusercontent.com/vbobovoz/bootstrap/main/bootstrap.sh)" -- --only neovim
```

Alternatively, keep a local checkout for editing configuration and pulling updates:

```bash
git clone https://github.com/vbobovoz/bootstrap.git
cd bootstrap
bash install.sh
```

Run the installer as your normal user. It requests elevated privileges for system
operations. A full installation installs packages, applies configuration with
backups, sets global Git preferences, and makes Zsh your login shell.

On macOS, packages are managed through Homebrew. On Ubuntu, the installer uses
APT and checksum-verified release downloads for tools that need newer versions.
Downloaded tools are installed under `/opt/bootstrap` and `/usr/local/bin`.
Neovim requires **0.12 or later**; Node.js requires a stable **26.13.0 or later**.

After installation:

1. Open a new login shell, then launch Ghostty.
2. Start `nvim` and open a project file. The first launch downloads plugins and
   parsers; language tools are installed as their file types are opened.
3. Use `:Mason` to inspect language-tool installation, then run
   `:checkhealth custom` and `:checkhealth vim.lsp`.
4. Run `bash install.sh --check` to verify the installed tools.

Set up your Git identity, SSH keys, cloud credentials, kubeconfig, and any AI
service authentication separately.

## Install or configure individual components

Run commands from the repository root. `--only` installs a component and applies
its configuration where available. `--config` applies configuration without
installing packages.

| Task | Command |
| --- | --- |
| Install the full environment | `bash install.sh` |
| Install Neovim, its dependencies, and its configuration | `bash install.sh --only neovim` |
| Install Ghostty and its configuration | `bash install.sh --only ghostty` |
| Install or update Node.js and npm | `bash install.sh --only node` |
| Install the terminal font | `bash install.sh --only fonts` |
| Apply Neovim configuration | `bash install.sh --config nvim` |
| Apply Ghostty configuration | `bash install.sh --config ghostty` |
| Apply Zsh configuration | `bash install.sh --config zsh` |
| Apply Starship configuration | `bash install.sh --config starship` |
| Apply global Git preferences | `bash install.sh --config git` |
| Apply Neovim and Ghostty configurations | `bash install.sh --editor-config-only` |
| Apply Neovim, Ghostty, Zsh, and Starship configurations | `bash install.sh --configs-only` |
| Verify installed tools | `bash install.sh --check` |
| Show all options | `bash install.sh --help` |

Available modules: `base`, `git`, `zsh`, `starship`, `fonts`, `lazygit`, `yazi`,
`node`, `neovim`, and `ghostty`. Select one module per invocation.
`--only zsh` also changes the login shell; `--config zsh` only copies the file.
`--only neovim` leaves Ghostty, fonts, Lazygit, and Yazi to their own modules.

## Update your setup

Edit the source files in `config/`, test your changes, and commit them to this
repository. To apply the current configuration on another machine:

```bash
cd bootstrap
git pull --ff-only
bash install.sh --configs-only
```

This applies the four file-based configurations without installing packages,
changing the login shell, or changing Git preferences. Run the relevant
`--only` module when you also need to install dependencies.

Restart Neovim and open a new shell after applying changes. Reload Ghostty with
**Cmd+Shift+,** on macOS or **Ctrl+Shift+,** on Linux. Reset any manual font zoom
with **Cmd+0** or **Ctrl+0**.

### Neovim plugin versions

Plugin revisions are recorded in `config/nvim/nvim-pack-lock.json`. After applying
an updated configuration to an existing installation, close other Neovim instances,
open Neovim, and synchronize plugins with the lockfile:

```vim
:lua vim.pack.update(nil, { target = 'lockfile' })
```

Review and confirm the changes, then restart Neovim.

To intentionally update plugin versions, run `:lua vim.pack.update()`, test the
result, and copy the installed `nvim-pack-lock.json` back into `config/nvim/`
before committing.

## What's included

- **Ghostty:** Lilex Nerd Font at 13 pt, with a consistent initial font size.
- **Zsh:** Zinit, fzf-tab completion, autosuggestions, syntax highlighting,
  zoxide, and eza/Git aliases. Shell plugins download on the first interactive run.
- **Starship:** a shared prompt configuration for both platforms.
- **Neovim:** Kanagawa Wave, rainbow brackets, completion, a project-relative file
  path in the status line, file navigation, Git integration, and persistent sessions.
- **Language support:** Go, Python, Lua, JSON, YAML, GitLab CI, Docker Compose,
  Kubernetes manifests, Helm templates, Dockerfiles, and Bash. Language tools
  include LSP servers, schema validation, formatters, and linters.
- **Editing:** format on save for Go, Python, and Lua; manual formatting for YAML
  and Bash; autosave when the editor loses focus. Python virtual environments
  are not automatically activated.
- **CLI tools:** Lazygit, Yazi, ripgrep, fd, fzf, jq, eza, zoxide, btop, and tools
  for previews and archives.

### Essential Neovim shortcuts

The leader key is **Space**. Press the keys in sequence for leader shortcuts.

| Action | Keys |
| --- | --- |
| Find a file | `Space f f` |
| Search project text | `Space f g` |
| Search the word or selection | `Space f w` |
| Open Lazygit | `Space Space` |
| Open Yazi | `Space o` |
| Format the current file | `Space F` |
| Select text | `Shift` + arrow keys |
| Move by word | `Ctrl` + `←` / `→` |
| Select by word | `Ctrl` + `Shift` + `←` / `→` |
| Copy the selection to the clipboard | `y` |
| Create or open a file | `:edit path/to/file` |
| Save the file | `:write` |

See the [Neovim configuration guide](config/nvim/README.md) and
[full shortcut reference](config/nvim/doc/SHORTCUTS.md) for more details.

## Configuration and backups

Configuration files are copied into place. Changes made to installed files do
not automatically propagate back to this repository.

| Component | Destination |
| --- | --- |
| Neovim | `${XDG_CONFIG_HOME:-$HOME/.config}/nvim/` |
| Ghostty | `${XDG_CONFIG_HOME:-$HOME/.config}/ghostty/config` |
| Starship | `${XDG_CONFIG_HOME:-$HOME/.config}/starship.toml` |
| Zsh | `${ZDOTDIR:-$HOME}/.zshrc` |

Before replacement, existing configuration is backed up beside its destination
with a `.bak.DATE_TIME` suffix. Neovim is replaced as a complete directory so
that leftover configuration files do not interfere. Close Neovim before applying
its configuration. Plugin data, undo history, and saved sessions are retained.

To restore a backup, close the application, move the current configuration aside,
and put the backup at the original path.

On macOS, a Ghostty configuration under
`~/Library/Application Support/com.mitchellh.ghostty/` can override the settings
installed here. Keep font and theme settings consistent if both locations exist.

## Development checks

```bash
bash tests/run.sh
make -C config/nvim check
```

The shell tests cover CLI routing, backups, repeated configuration application,
and platform logic without installing system packages. Neovim checks require
Neovim 0.12+, cached plugins, and StyLua, which can be installed through Mason.
Desktop behavior and clipboard integration also need verification in a real
terminal session.
