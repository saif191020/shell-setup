# fzf key bindings (Ctrl-R, Ctrl-T, Alt-C) and completion from ~/.fzf,
# which install.sh clones and sets up. Plus a fuzzy `cd <Tab>` that chains into subdirectories.
[ -f ~/.fzf.bash ] && . ~/.fzf.bash
command -v fzf >/dev/null 2>&1 || return 0

_fzf_cd_complete() {
    local cur="${COMP_WORDS[COMP_CWORD]}"
    local search_dir="."
    local prefix="$cur"

    # If typing a subdirectory (e.g., "stack/"), split path and search prefix
    if [[ "$cur" == */* ]]; then
        search_dir="${cur%/*}"
        # Handle root directory edge case
        [ -z "$search_dir" ] && search_dir="/"
        prefix="${cur##*/}"
    fi

    # Exit silently if the directory doesn't exist to prevent find errors
    [ -d "$search_dir" ] || return 0

    local query=""
    if [ -n "$prefix" ]; then
        query="^$prefix"
    fi

    local selected_dir
    # --delimiter '/' --nth -1 ensures fzf only searches the actual folder name, not the full path
    selected_dir=$(find "$search_dir" -mindepth 1 -maxdepth 1 -type d 2>/dev/null | \
                   sed 's|^\./||' | \
                   fzf -1 -0 -q "$query" --delimiter '/' --nth -1 --height 40% --reverse)

    if [ -n "$selected_dir" ]; then
        # Append a trailing slash automatically for continuous tab-chaining
        COMPREPLY=( "$(printf '%q' "$selected_dir")/" )
    fi
}
# -o nospace prevents Bash from adding a space, allowing you to hit Tab again immediately
complete -F _fzf_cd_complete -o nospace cd
