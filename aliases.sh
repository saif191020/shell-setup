# Shell aliases. Sourced from ~/.bashrc by the block install.sh adds.

# install.sh may put eza in ~/.local/bin; make sure it's found.
case ":$PATH:" in
    *":$HOME/.local/bin:"*) ;;
    *) [ -d "$HOME/.local/bin" ] && PATH="$HOME/.local/bin:$PATH" ;;
esac

alias cls='clear'

# ---------------------------------------------------------------- docker ----
alias up='docker compose up -d'
alias down='docker compose down'
alias pull='docker compose pull'
alias docker-update='pull && up && docker image prune -f'

# ----------------------------------------------------------------- shell ----
alias reload='source ~/.bashrc'
alias refresh='source ~/.bashrc'

alias pbcopy='xclip -selection clipboard'
alias pbpaste='xclip -selection clipboard -o'

alias myip='curl ifconfig.me'

# -------------------------------------------------------------- better ls ----
# `exa` is unmaintained and was dropped from Debian 13; `eza` is its successor.
if command -v eza >/dev/null 2>&1; then
    _LS_BIN=eza
elif command -v exa >/dev/null 2>&1; then
    _LS_BIN=exa
else
    _LS_BIN=
fi

if [ -n "$_LS_BIN" ]; then
    alias ls="$_LS_BIN --icons --group-directories-first"
    alias ll="$_LS_BIN -l --icons --group-directories-first"
    alias la="$_LS_BIN -la --icons --group-directories-first"
    alias lt="$_LS_BIN -lT --level=2 --icons --group-directories-first"
    alias lS="$_LS_BIN -l --sort=size --icons --group-directories-first"
else
    # graceful fallback so ll/la still work on a bare box
    alias ll='ls -l'
    alias la='ls -la'
    alias lt='ls -R'
    alias lS='ls -lS'
fi
unset _LS_BIN

# ------------------------------------------------------------- better cat ----
# Debian ships bat as `batcat` (name clash); upstream/other distros use `bat`.
if command -v batcat >/dev/null 2>&1; then
    alias cat='batcat'
elif command -v bat >/dev/null 2>&1; then
    alias cat='bat'
fi
