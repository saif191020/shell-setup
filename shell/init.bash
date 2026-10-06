# shell-setup entrypoint. Sourced from ~/.bashrc by the managed block that
# install.sh writes. Safe to source more than once.

# Interactive shells only.
case $- in *i*) ;; *) return 0 2>/dev/null || exit 0 ;; esac

SHELL_SETUP_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SHELL_SETUP_CONF="${XDG_CONFIG_HOME:-$HOME/.config}/shell-setup"
export SHELL_SETUP_ROOT SHELL_SETUP_CONF

# Private dotenv file: secrets and per-machine variables. Lives outside the repo.
if [ -f "$SHELL_SETUP_CONF/env" ]; then
    set -a
    # shellcheck disable=SC1091
    . "$SHELL_SETUP_CONF/env"
    set +a
fi

for _f in path options completion aliases functions fzf z prompt; do
    # shellcheck disable=SC1090
    [ -f "$SHELL_SETUP_ROOT/shell/$_f.bash" ] && . "$SHELL_SETUP_ROOT/shell/$_f.bash"
done
unset _f

# Per-machine overrides (not tracked): extra aliases, work-specific bits, etc.
# shellcheck disable=SC1091
[ -f "$SHELL_SETUP_CONF/local.bash" ] && . "$SHELL_SETUP_CONF/local.bash"
