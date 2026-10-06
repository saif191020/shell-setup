# Shell behaviour: history, shopts, environment.

# --- history ---------------------------------------------------------------
HISTSIZE=100000
HISTFILESIZE=200000
HISTCONTROL=ignoreboth:erasedups
HISTTIMEFORMAT='%F %T  '
shopt -s histappend cmdhist
# Flush each command to the history file so parallel shells share history.
case ";$PROMPT_COMMAND;" in
    *";history -a;"*) ;;
    *) PROMPT_COMMAND="history -a${PROMPT_COMMAND:+;$PROMPT_COMMAND}" ;;
esac

# --- shopts ----------------------------------------------------------------
shopt -s checkwinsize   # keep LINES/COLUMNS correct after resize
shopt -s globstar 2>/dev/null   # ** matches recursively
shopt -s cdspell dirspell 2>/dev/null   # fix small typos in cd / completion
shopt -s autocd 2>/dev/null   # type a directory name to cd into it

# --- environment -----------------------------------------------------------
export TERM="${TERM:-xterm-256color}"
case "$TERM" in xterm) export TERM=xterm-256color ;; esac

if [ -z "$EDITOR" ]; then
    for _e in nvim vim vi nano; do
        if command -v "$_e" >/dev/null 2>&1; then export EDITOR="$_e"; break; fi
    done
    unset _e
fi
export VISUAL="${VISUAL:-$EDITOR}"

export LESS='-R -F -X -i -M'          # colours, quit if one screen, smart-case search
export LS_OPTIONS='--color=auto'
command -v dircolors >/dev/null 2>&1 && eval "$(dircolors -b)"
export GREP_COLORS='mt=1;32'
