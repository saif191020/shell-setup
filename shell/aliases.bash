# Aliases. Every tool-specific alias is guarded, so this file is safe on a bare box.

alias cls='clear'
alias reload='source ~/.bashrc'
alias refresh='source ~/.bashrc'
alias myip='curl -s ifconfig.me; echo'

alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'
alias -- -='cd -'

alias grep='grep --color=auto'
alias df='df -h'
alias du='du -h'
alias free='free -h'
alias mkdir='mkdir -p'

# --- clipboard (xclip) -----------------------------------------------------
if command -v xclip >/dev/null 2>&1; then
    alias pbcopy='xclip -selection clipboard'
    alias pbpaste='xclip -selection clipboard -o'
fi

# --- better ls (eza; exa is its unmaintained predecessor) ------------------
if command -v eza >/dev/null 2>&1; then
    _ls_bin=eza
elif command -v exa >/dev/null 2>&1; then
    _ls_bin=exa
else
    _ls_bin=
fi

if [ -n "$_ls_bin" ]; then
    alias ls="$_ls_bin --icons --group-directories-first"
    alias ll="$_ls_bin -l --icons --group-directories-first"
    alias la="$_ls_bin -la --icons --group-directories-first"
    alias lt="$_ls_bin -lT --level=2 --icons --group-directories-first"
    alias lS="$_ls_bin -l --sort=size --icons --group-directories-first"
else
    alias ls='ls --color=auto'
    alias ll='ls -l'
    alias la='ls -la'
    alias lt='ls -R'
    alias lS='ls -lS'
fi
unset _ls_bin

# --- better cat (Debian ships bat as `batcat`) -----------------------------
if command -v batcat >/dev/null 2>&1; then
    alias cat='batcat'
elif command -v bat >/dev/null 2>&1; then
    alias cat='bat'
fi

# --- git -------------------------------------------------------------------
if command -v git >/dev/null 2>&1; then
    alias g='git'
    alias gs='git status -sb'
    alias gd='git diff'
    alias gds='git diff --staged'
    alias gl='git lg'
    alias gp='git pull'
    alias gc='git commit'
    alias gco='git checkout'
fi

# --- docker (only if docker is present; this repo does not install it) -----
if command -v docker >/dev/null 2>&1; then
    alias up='docker compose up -d'
    alias down='docker compose down'
    alias pull='docker compose pull'
    alias docker-update='pull && up && docker image prune -f'
    alias dps='docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"'
fi
