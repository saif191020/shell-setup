# fzf key bindings (Ctrl-R, Ctrl-T, Alt-C) and completion from ~/.fzf,
# which install.sh clones and sets up. Plus a one-level fuzzy `cd <Tab>`.
[ -f ~/.fzf.bash ] && . ~/.fzf.bash
command -v fzf >/dev/null 2>&1 || return 0

_fzf_cd_complete() {
    local cur="${COMP_WORDS[COMP_CWORD]}"
    local selected_dir

    # Prefix query with ^ so only folders starting with $cur are matched initially
    local query=""
    if [ -n "$cur" ]; then
        query="^$cur"
    fi

    selected_dir=$(find . -mindepth 1 -maxdepth 1 -type d 2>/dev/null | sed 's|^\./||' | fzf -1 -0 -q "$query" --height 40% --reverse)

    if [ -n "$selected_dir" ]; then
        COMPREPLY=( "$(printf '%q' "$selected_dir")" )
    fi
}
complete -F _fzf_cd_complete cd
