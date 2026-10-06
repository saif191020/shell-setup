# Prompt: [exit-code] user@host:dir (git-branch*) $
# Skipped if a prompt framework (starship, etc.) already took over.

[ -n "$STARSHIP_SHELL" ] && return 0

__ss_prompt() {
    local rc=$?
    local reset='\[\e[0m\]' red='\[\e[1;31m\]' green='\[\e[1;32m\]'
    local blue='\[\e[1;34m\]' yellow='\[\e[0;33m\]' dim='\[\e[2m\]'
    local who="$green\\u@\\h$reset"
    [ "$(id -u)" -eq 0 ] && who="$red\\u@\\h$reset"   # root stands out

    local branch=
    if command -v git >/dev/null 2>&1; then
        branch=$(git symbolic-ref --short -q HEAD 2>/dev/null || git rev-parse --short HEAD 2>/dev/null)
        if [ -n "$branch" ]; then
            git diff --quiet --ignore-submodules 2>/dev/null && git diff --cached --quiet 2>/dev/null \
                || branch="$branch*"
            branch=" $yellow($branch)$reset"
        fi
    fi

    local status=
    [ "$rc" -ne 0 ] && status="$red[$rc]$reset "

    PS1="${debian_chroot:+($debian_chroot)}${status}${who}:${blue}\\w${reset}${branch}\\n${dim}\\\$${reset} "
}

case ";$PROMPT_COMMAND;" in
    *";__ss_prompt;"*|*"__ss_prompt;"*) ;;
    *) PROMPT_COMMAND="__ss_prompt${PROMPT_COMMAND:+;$PROMPT_COMMAND}" ;;
esac
