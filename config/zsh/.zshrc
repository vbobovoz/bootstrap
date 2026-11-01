# ---------------------------------------------------------
# Zinit
# ---------------------------------------------------------

# Homebrew may not be in PATH in a fresh macOS shell.
if [[ "$OSTYPE" == darwin* ]] && ! command -v brew >/dev/null 2>&1; then
    if [[ -x /opt/homebrew/bin/brew ]]; then
        eval "$(/opt/homebrew/bin/brew shellenv)"
    elif [[ -x /usr/local/bin/brew ]]; then
        eval "$(/usr/local/bin/brew shellenv)"
    fi
fi

ZINIT_HOME="${XDG_DATA_HOME:-$HOME/.local/share}/zinit/zinit.git"

if [[ ! -d "$ZINIT_HOME" ]]; then
    mkdir -p "${ZINIT_HOME:h}"
    git clone --depth=1 https://github.com/zdharma-continuum/zinit.git "$ZINIT_HOME"
fi

source "$ZINIT_HOME/zinit.zsh"

# ---------------------------------------------------------
# Environment
# ---------------------------------------------------------

export PATH="$HOME/go/bin:$PATH"
if ! command -v go >/dev/null 2>&1 && [[ -x /usr/local/go/bin/go ]]; then
    export PATH="/usr/local/go/bin:$PATH"
fi

export EDITOR="nvim"
export VISUAL="$EDITOR"

# ---------------------------------------------------------
# Zsh options
# ---------------------------------------------------------

setopt AUTO_CD
setopt INTERACTIVE_COMMENTS
setopt NO_BEEP

# ---------------------------------------------------------
# History
# ---------------------------------------------------------

HISTFILE="${ZDOTDIR:-$HOME}/.zsh_history"
HISTSIZE=50000
SAVEHIST=50000

setopt APPEND_HISTORY
setopt INC_APPEND_HISTORY
setopt SHARE_HISTORY

setopt HIST_IGNORE_DUPS
setopt HIST_IGNORE_ALL_DUPS
setopt HIST_SAVE_NO_DUPS
setopt HIST_FIND_NO_DUPS
setopt HIST_REDUCE_BLANKS
setopt HIST_IGNORE_SPACE

# ---------------------------------------------------------
# Completion
# ---------------------------------------------------------

autoload -Uz compinit

ZCOMPDUMP="${ZDOTDIR:-$HOME}/.zcompdump"

if [[ -n "$ZCOMPDUMP"(#qN.mh-24) ]]; then
    compinit -C -d "$ZCOMPDUMP"
else
    compinit -d "$ZCOMPDUMP"
fi

if [[ -s "$ZCOMPDUMP" &&
      (! -s "$ZCOMPDUMP.zwc" || "$ZCOMPDUMP" -nt "$ZCOMPDUMP.zwc") ]]; then
    zcompile "$ZCOMPDUMP"
fi

zstyle ':completion:*' matcher-list 'm:{a-z}={A-Za-z}'
zstyle ':completion:*' menu no
zstyle ':completion:*' group-name ''
zstyle ':completion:*' verbose yes

# ---------------------------------------------------------
# Zinit plugins
# ---------------------------------------------------------

zinit ice wait lucid
zinit snippet OMZP::sudo

zinit ice wait lucid
zinit snippet OMZP::extract

zinit light Aloxaf/fzf-tab
zinit light zsh-users/zsh-autosuggestions

zinit ice wait lucid
zinit light zdharma-continuum/fast-syntax-highlighting

# ---------------------------------------------------------
# fzf-tab
# ---------------------------------------------------------

zstyle ':fzf-tab:*' fzf-flags --height=50% --border
zstyle ':fzf-tab:*' switch-group ',' '.'

if (( $+commands[eza] )); then
    zstyle ':fzf-tab:complete:cd:*' \
        fzf-preview 'eza -1 --icons --color=always $realpath 2>/dev/null'
else
    zstyle ':fzf-tab:complete:cd:*' \
        fzf-preview 'ls -la $realpath 2>/dev/null'
fi

# ---------------------------------------------------------
# History prefix search
# ---------------------------------------------------------

autoload -Uz up-line-or-beginning-search
autoload -Uz down-line-or-beginning-search

zle -N up-line-or-beginning-search
zle -N down-line-or-beginning-search

WORDCHARS='*?[]~=&;!#$%^(){}<>'

bindkey '^[[1;5D' backward-word
bindkey '^[[1;5C' forward-word

bindkey '^[[A' up-line-or-beginning-search
bindkey '^[[B' down-line-or-beginning-search
bindkey '^[OA' up-line-or-beginning-search
bindkey '^[OB' down-line-or-beginning-search

# ---------------------------------------------------------
# Tools
# ---------------------------------------------------------

if (( $+commands[zoxide] )); then
    eval "$(zoxide init zsh --cmd cd)"
fi

if (( $+commands[starship] )); then
    eval "$(starship init zsh)"
fi

# ---------------------------------------------------------
# General aliases
# ---------------------------------------------------------

alias v="nvim"
alias c="clear"
alias q="exit"

(( $+commands[yazi] )) && alias y="yazi"
(( $+commands[lazygit] )) && alias lg="lazygit"
if (( $+commands[ddgr] )); then
    alias d="ddgr"
    alias в="ddgr"
fi

# ---------------------------------------------------------
# Git aliases
# ---------------------------------------------------------

alias g="git"
alias gst="git status"

alias ga="git add"
alias gaa="git add --all"

alias gcmsg="git commit -m"

alias gp="git push"
alias gpf="git push --force-with-lease"
alias gl="git pull"

git_default_branch() {
    git symbolic-ref refs/remotes/origin/HEAD 2>/dev/null \
        | sed 's@^refs/remotes/origin/@@'
}

alias gcm='git switch $(git_default_branch)'
alias gco="git checkout"
alias gcb="git switch -c"

alias gb="git branch"
alias gbD="git branch -D"

alias gsta="git stash"
alias gstp="git stash pop"
alias gstc="git stash clear"

# ---------------------------------------------------------
# eza aliases
# ---------------------------------------------------------

if (( $+commands[eza] )); then
    alias ls="eza --icons"
    alias l="eza --icons"

    alias ll="eza -l --icons --git --group-directories-first"
    alias la="eza -la --icons --git"

    alias lt="eza --tree --icons --level=2"
    alias lta="eza --tree --icons --level=3 --all"

    alias lsize="eza -l --sort=size --icons --group-directories-first"
    alias ldate="eza -l --sort=modified --icons --group-directories-first"
else
    alias ll="ls -lah"
    alias la="ls -la"
fi
