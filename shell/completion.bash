# Tab completion: bash-completion + friendlier readline behaviour.

# --- bash-completion -------------------------------------------------------
if ! shopt -oq posix && ! declare -F _init_completion >/dev/null 2>&1; then
    for _c in \
        /usr/share/bash-completion/bash_completion \
        /etc/bash_completion \
        /opt/homebrew/etc/profile.d/bash_completion.sh \
        /usr/local/etc/profile.d/bash_completion.sh; do
        # shellcheck disable=SC1090
        if [ -r "$_c" ]; then . "$_c"; break; fi
    done
    unset _c
fi

# --- readline --------------------------------------------------------------
bind 'set completion-ignore-case on'        # `cd doc<TAB>` finds Documents
bind 'set completion-map-case on'           # treat - and _ as the same
bind 'set show-all-if-ambiguous on'         # one TAB lists matches, no double-TAB
bind 'set show-all-if-unmodified on'
bind 'set menu-complete-display-prefix on'
bind 'set colored-stats on'                 # colour completions like ls
bind 'set colored-completion-prefix on'
bind 'set mark-symlinked-directories on'
bind 'set visible-stats on'                 # append / * @ markers
bind 'set completion-query-items 200'
bind 'set page-completions off'
bind 'set skip-completed-text on'
bind 'set bell-style none'

# TAB completes the common prefix, then cycles through matches on repeat.
bind 'TAB:menu-complete'
bind '"\e[Z":menu-complete-backward'        # Shift-TAB goes back

# Up/Down search history for what you've already typed.
bind '"\e[A":history-search-backward'
bind '"\e[B":history-search-forward'
bind '"\e[1;5C":forward-word'               # Ctrl-Right / Ctrl-Left
bind '"\e[1;5D":backward-word'

# Make the `g` git alias complete like git (git completion loads lazily).
declare -F _completion_loader >/dev/null 2>&1 && _completion_loader git 2>/dev/null
if declare -F __git_complete >/dev/null 2>&1; then
    __git_complete g __git_main 2>/dev/null
fi
