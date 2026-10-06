# fzf: key bindings, fuzzy completion, previews, and handy pickers.

command -v fzf >/dev/null 2>&1 || return 0

# Prefer fd/fdfind for listing files (fast, respects .gitignore), else ripgrep.
_fd=
command -v fd >/dev/null 2>&1 && _fd=fd
[ -z "$_fd" ] && command -v fdfind >/dev/null 2>&1 && _fd=fdfind
_bat=
command -v bat >/dev/null 2>&1 && _bat=bat
[ -z "$_bat" ] && command -v batcat >/dev/null 2>&1 && _bat=batcat
_tree='ls -la'
if command -v eza >/dev/null 2>&1; then _tree='eza --tree --level=2 --icons --color=always'
elif command -v exa >/dev/null 2>&1; then _tree='exa --tree --level=2 --icons --color=always'; fi

if [ -n "$_fd" ]; then
    export FZF_DEFAULT_COMMAND="$_fd --type f --hidden --follow --exclude .git"
    export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
    export FZF_ALT_C_COMMAND="$_fd --type d --hidden --follow --exclude .git"
elif command -v rg >/dev/null 2>&1; then
    export FZF_DEFAULT_COMMAND="rg --files --hidden --follow --glob '!.git'"
    export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
fi

_file_preview='cat {}'
[ -n "$_bat" ] && _file_preview="$_bat --style=numbers --color=always --line-range=:300 {}"

export FZF_DEFAULT_OPTS="
  --height=45% --layout=reverse --border=rounded --info=inline
  --bind=ctrl-/:toggle-preview --bind=ctrl-u:preview-half-page-up --bind=ctrl-d:preview-half-page-down
  --color=fg:#c0caf5,bg:-1,hl:#7aa2f7,fg+:#ffffff,bg+:#283457,hl+:#7dcfff
  --color=info:#e0af68,prompt:#7aa2f7,pointer:#f7768e,marker:#9ece6a,spinner:#bb9af7,header:#565f89,border:#3b4261"
export FZF_CTRL_T_OPTS="--preview '$_file_preview' --preview-window=right:55%:wrap"
export FZF_ALT_C_OPTS="--preview '$_tree {} | head -100' --preview-window=right:50%"
export FZF_CTRL_R_OPTS="--preview 'echo {}' --preview-window=down:3:wrap --bind='ctrl-y:execute-silent(echo -n {2..} | xclip -selection clipboard 2>/dev/null)+abort' --header='Ctrl-Y copies'"

# Plain <Tab> opens fzf for cd/ls/vim/ssh/kill/... (a unique match completes
# instantly). Set FZF_COMPLETION_TRIGGER='**' in your env file to go back to `**<Tab>`.
: "${FZF_COMPLETION_TRIGGER=}"
export FZF_COMPLETION_TRIGGER

# --- shell integration -----------------------------------------------------
# fzf >= 0.48 can print its own integration; older distro packages ship files.
if fzf --bash >/dev/null 2>&1; then
    eval "$(fzf --bash)"
else
    for _f in \
        /usr/share/doc/fzf/examples/key-bindings.bash \
        /usr/share/doc/fzf/examples/completion.bash \
        /usr/share/bash-completion/completions/fzf \
        /usr/share/fzf/key-bindings.bash \
        /usr/share/fzf/completion.bash \
        /opt/homebrew/opt/fzf/shell/key-bindings.bash \
        /opt/homebrew/opt/fzf/shell/completion.bash \
        "$HOME/.fzf/shell/key-bindings.bash" \
        "$HOME/.fzf/shell/completion.bash"; do
        # shellcheck disable=SC1090
        [ -r "$_f" ] && . "$_f"
    done
    unset _f
fi

# Fuzzy completion for cd, vim, kill, ssh, export, ... With plain <Tab> the
# listings show only the current level (depth 1, no symlink following) so
# `cd /<Tab>` can't crawl a whole filesystem. Override with FZF_COMPLETION_MAX_DEPTH.
if [ -z "$FZF_COMPLETION_TRIGGER" ]; then
    _fzf_depth="${FZF_COMPLETION_MAX_DEPTH:-1}"
else
    _fzf_depth=
fi
if [ -n "$_fd" ]; then
    _fzf_compgen_path() { "$_fd" --hidden --exclude .git ${_fzf_depth:+--max-depth "$_fzf_depth"} . "$1"; }
    _fzf_compgen_dir()  { "$_fd" --type d --hidden --exclude .git ${_fzf_depth:+--max-depth "$_fzf_depth"} . "$1"; }
else
    _fzf_compgen_path() { find "$1" ${_fzf_depth:+-maxdepth "$_fzf_depth"} -mindepth 1 -not -path '*/.git/*' 2>/dev/null; }
    _fzf_compgen_dir()  { find "$1" ${_fzf_depth:+-maxdepth "$_fzf_depth"} -mindepth 1 -type d -not -path '*/.git/*' 2>/dev/null; }
fi

# --- pickers ---------------------------------------------------------------

# fe [query]: pick file(s) and open them in $EDITOR
fe() {
    local files
    mapfile -t files < <(fzf --query="$1" --multi --select-1 --exit-0 \
        --preview "$_file_preview")
    [ "${#files[@]}" -gt 0 ] && ${EDITOR:-vi} "${files[@]}"
}

# fcd [dir]: pick a subdirectory and cd into it
fcd() {
    local base="${1:-.}" dir
    if [ -n "$_fd" ]; then
        dir=$("$_fd" --type d --hidden --exclude .git . "$base")
    else
        dir=$(find "$base" -type d -not -path '*/.git/*' 2>/dev/null)
    fi
    dir=$(printf '%s\n' "$dir" | fzf --preview "$_tree {} | head -100") && cd -- "$dir" || return
}

# frg <pattern>: live ripgrep, pick a hit, open it in $EDITOR at that line
frg() {
    command -v rg >/dev/null 2>&1 || { echo "frg: ripgrep not installed" >&2; return 1; }
    local sel file line
    sel=$(rg --line-number --no-heading --color=always --smart-case "${*:-}" 2>/dev/null \
        | fzf --ansi --delimiter=: \
              --preview "${_bat:-cat} --color=always --highlight-line {2} {1}" \
              --preview-window='right:55%:+{2}-10') || return
    file=${sel%%:*}; line=${sel#*:}; line=${line%%:*}
    ${EDITOR:-vi} "+$line" "$file"
}

# fkill [signal]: pick processes to kill (default SIGTERM)
fkill() {
    local pids
    pids=$(ps -eo pid,user,%cpu,%mem,etime,args --sort=-%cpu \
        | fzf --header-lines=1 --multi --preview 'echo {}' --preview-window=down:3:wrap \
        | awk '{print $1}')
    [ -n "$pids" ] && echo "$pids" | xargs kill -"${1:-15}"
}

# fman: fuzzy-search man pages
fman() {
    man -k . 2>/dev/null | fzf --prompt='man> ' --preview 'man {1} 2>/dev/null | head -100' \
        | awk '{print $1}' | xargs -r man
}

# fssh: pick a host from ~/.ssh/config and connect
fssh() {
    local host
    host=$(awk '/^[Hh]ost / {for (i=2;i<=NF;i++) if ($i !~ /[*?]/) print $i}' \
        ~/.ssh/config ~/.ssh/config.d/* 2>/dev/null | sort -u | fzf --prompt='ssh> ') \
        && ssh "$host" "$@"
}

# fenv: browse environment variable names; the value shows only in the preview
fenv() { compgen -e | sort | fzf --preview 'printenv {}' --preview-window=down:3:wrap; }

# fpath: browse PATH directories
fpath() { path | fzf --preview 'ls -A {} | head -100'; }

# --- git pickers (only inside a repo) --------------------------------------

# fbr: checkout a branch (local or remote)
fbr() {
    git rev-parse --git-dir >/dev/null 2>&1 || { echo "not a git repo" >&2; return 1; }
    local branch
    branch=$(git for-each-ref --sort=-committerdate --format='%(refname:short)' refs/heads refs/remotes \
        | grep -v 'HEAD$' \
        | fzf --preview 'git log --oneline --graph --color=always -20 {}') || return
    git checkout "${branch#origin/}"
}

# fgl: browse git log, Enter shows the commit
fgl() {
    git rev-parse --git-dir >/dev/null 2>&1 || { echo "not a git repo" >&2; return 1; }
    git log --graph --color=always --format='%C(auto)%h%d %s %C(black)%C(bold)%cr' "$@" \
        | fzf --ansi --no-sort --reverse --tiebreak=index \
              --preview 'git show --color=always $(echo {} | grep -o "[a-f0-9]\{7,\}" | head -1)' \
              --bind 'enter:execute(git show --color=always $(echo {} | grep -o "[a-f0-9]\{7,\}" | head -1) | less -R)'
}

# fgs: stage/unstage files interactively (Tab selects, Enter stages)
fgs() {
    git rev-parse --git-dir >/dev/null 2>&1 || { echo "not a git repo" >&2; return 1; }
    local files
    files=$(git -c color.status=false status --short | fzf --multi \
        --preview 'git diff --color=always -- {2}' | awk '{print $2}')
    [ -n "$files" ] && echo "$files" | xargs git add -- && git status -sb
}
