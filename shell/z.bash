# z (https://github.com/rupa/z): jump to frecent directories.
#   z foo      cd to the best match     z -l foo   list matches
#   zi [foo]   pick from the list with fzf (needs fzf)
# Vendored in vendor/z.sh. Data file: ~/.z (set _Z_DATA to move it).

[ -r "$SHELL_SETUP_ROOT/vendor/z.sh" ] || return 0
# shellcheck disable=SC1091
. "$SHELL_SETUP_ROOT/vendor/z.sh"

# zi [query]: fuzzy-pick from z's database and cd there
zi() {
    command -v fzf >/dev/null 2>&1 || { echo "zi: fzf not installed" >&2; return 1; }
    local dir
    dir=$(_z -l "$@" 2>&1 | sed 's/^[0-9.]* *//' \
        | fzf --tac --no-sort --query="${*:-}" --preview "${_tree:-ls -la} {} | head -100") \
        && cd -- "$dir" || return
}
