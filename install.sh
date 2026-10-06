#!/bin/sh
# shell-setup installer: installs the tools the aliases need and sources
# aliases.sh from ~/.bashrc. Idempotent: run it as often as you like.
#
#   curl -fsSL https://raw.githubusercontent.com/saif191020/shell-setup/main/install.sh | sh
#   sh install.sh [--dry-run] [--no-packages] [--no-binaries] [--no-fzf] [--uninstall]
#
# Environment:
#   SHELL_SETUP_REPO  git URL to clone when run via a pipe
#   SHELL_SETUP_DIR   where the clone lives (default ~/.local/share/shell-setup)
#   SHELL_SETUP_REF   branch/tag to track (default main)

set -eu

REPO_URL="${SHELL_SETUP_REPO:-https://github.com/saif191020/shell-setup.git}"
INSTALL_DIR="${SHELL_SETUP_DIR:-$HOME/.local/share/shell-setup}"
REF="${SHELL_SETUP_REF:-main}"
BASHRC="$HOME/.bashrc"
MARK_BEGIN='# >>> shell-setup >>>'
MARK_END='# <<< shell-setup <<<'

DRY=0
DO_PACKAGES=1
DO_BINARIES=1
DO_FZF=1
UNINSTALL=0
for arg in "$@"; do
    case "$arg" in
        --dry-run) DRY=1 ;;
        --no-packages) DO_PACKAGES=0 ;;
        --no-binaries) DO_BINARIES=0 ;;
        --no-fzf) DO_FZF=0 ;;
        --uninstall) UNINSTALL=1 ;;
        -h|--help) sed -n '2,11p' "$0" 2>/dev/null | sed 's/^# \{0,1\}//'; exit 0 ;;
        *) echo "unknown option: $arg" >&2; exit 2 ;;
    esac
done

say()  { printf '\033[1;34m==>\033[0m %s\n' "$*"; }
warn() { printf '\033[1;33mwarn:\033[0m %s\n' "$*" >&2; }
die()  { printf '\033[1;31merror:\033[0m %s\n' "$*" >&2; exit 1; }
have() { command -v "$1" >/dev/null 2>&1; }

# Run a command, or just print it under --dry-run.
run() {
    if [ "$DRY" -eq 1 ]; then printf '   [dry-run] %s\n' "$*"; else "$@"; fi
}

# sudo is usable if it needs no password or we have a terminal to prompt on.
SUDO=
if [ "$(id -u)" -ne 0 ] && have sudo; then
    if sudo -n true 2>/dev/null || ( : </dev/tty ) 2>/dev/null; then SUDO=sudo; fi
fi

PM=
if have apt-get; then PM=apt
elif have dnf; then PM=dnf
elif have pacman; then PM=pacman
elif have apk; then PM=apk
fi

pm_install() {
    case "$PM" in
        apt)    run $SUDO env DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends "$1" ;;
        dnf)    run $SUDO dnf install -y "$1" ;;
        pacman) run $SUDO pacman -S --needed --noconfirm "$1" ;;
        apk)    run $SUDO apk add "$1" ;;
        *)      return 1 ;;
    esac
}

pm_has_package() {
    case "$PM" in
        apt)    apt-cache show "$1" >/dev/null 2>&1 ;;
        dnf)    dnf info "$1" >/dev/null 2>&1 ;;
        pacman) pacman -Si "$1" >/dev/null 2>&1 ;;
        apk)    apk search -e "$1" 2>/dev/null | grep -q . ;;
        *)      return 1 ;;
    esac
}

tool_present() {
    case "$1" in
        bat) have bat || have batcat ;;
        eza) have eza || have exa ;;
        *)   have "$1" ;;
    esac
}

# ---------------------------------------------------------------------------
# Bootstrap: when piped from curl there is no checkout next to this script, so
# clone (or update) one and re-run the installer from it.
# ---------------------------------------------------------------------------
script_dir=
if [ -f "$0" ]; then
    script_dir=$(cd "$(dirname "$0")" 2>/dev/null && pwd) || script_dir=
fi

if [ -z "$script_dir" ] || [ ! -f "$script_dir/aliases.sh" ]; then
    if ! have git; then
        [ "$UNINSTALL" -eq 1 ] && die "git is required to bootstrap"
        say "git is needed to fetch the repo"
        [ "$PM" = apt ] && run $SUDO apt-get update -qq
        pm_install git || die "could not install git"
    fi
    if [ -d "$INSTALL_DIR/.git" ]; then
        say "Updating $INSTALL_DIR"
        run git -C "$INSTALL_DIR" fetch --quiet origin "$REF"
        run git -C "$INSTALL_DIR" checkout --quiet "$REF"
        run git -C "$INSTALL_DIR" merge --ff-only --quiet "origin/$REF" \
            || warn "could not fast-forward $INSTALL_DIR (local changes?); using it as-is"
    else
        say "Cloning $REPO_URL into $INSTALL_DIR"
        run mkdir -p "$(dirname "$INSTALL_DIR")"
        run git clone --quiet --branch "$REF" "$REPO_URL" "$INSTALL_DIR"
    fi
    [ "$DRY" -eq 1 ] && { say "dry-run: stopping before re-exec of the cloned installer"; exit 0; }
    exec sh "$INSTALL_DIR/install.sh" "$@"
fi

ROOT="$script_dir"

strip_block() {
    # Print $1 with any existing managed block removed.
    awk -v b="$MARK_BEGIN" -v e="$MARK_END" '
        $0 == b {skip=1; next}
        $0 == e {skip=0; next}
        !skip {print}' "$1"
}

trim_blank() {
    # Drop trailing blank lines so repeated runs don't grow the file.
    awk 'NF {for (i=0;i<n;i++) print ""; n=0; print; next} {n++}'
}

# Older versions of this repo added a git include; remove it if present.
remove_legacy_git_include() {
    have git || return 0
    git config --global --get-all include.path 2>/dev/null | grep -q 'shell-setup/config/gitconfig$' || return 0
    run git config --global --unset-all include.path 'shell-setup/config/gitconfig$' || true
    if [ "$DRY" -eq 0 ] && ! git config --global --get-regexp '^include\.' >/dev/null 2>&1; then
        git config --global --remove-section include 2>/dev/null || true
    fi
}

if [ "$UNINSTALL" -eq 1 ]; then
    say "Removing managed block from $BASHRC"
    if [ -f "$BASHRC" ] && grep -qF "$MARK_BEGIN" "$BASHRC"; then
        if [ "$DRY" -eq 1 ]; then echo "   [dry-run] rewrite $BASHRC without block"
        else
            tmp=$(mktemp); strip_block "$BASHRC" | trim_blank > "$tmp"; cat "$tmp" > "$BASHRC"; rm -f "$tmp"
        fi
    fi
    remove_legacy_git_include
    say "Done. Left in place: $ROOT, ~/.fzf and installed packages."
    [ -d "$HOME/.fzf" ] && say "To remove fzf too:  rm -rf ~/.fzf ~/.fzf.bash ~/.fzf.zsh"
    exit 0
fi

# ---------------------------------------------------------------------------
# 1. Packages the aliases use
# ---------------------------------------------------------------------------
if [ "$DO_PACKAGES" -eq 1 ]; then
    if [ -z "$PM" ]; then
        warn "no supported package manager found; skipping package install"
    elif [ -z "$SUDO" ] && [ "$(id -u)" -ne 0 ]; then
        warn "need root: no sudo, or sudo has no terminal for a password. Re-run in a terminal to install packages"
    else
        missing=
        for t in curl bat eza xclip; do
            tool_present "$t" || missing="$missing $t"
        done
        if [ -z "$missing" ]; then
            say "All packages already installed"
        else
            say "Installing:$missing  (via $PM)"
            [ "$PM" = apt ] && { run $SUDO apt-get update -qq || warn "apt-get update failed"; }
            for pkg in $missing; do
                if [ "$DRY" -eq 0 ] && ! pm_has_package "$pkg"; then
                    warn "$pkg is not available from $PM repos; skipping"
                    continue
                fi
                pm_install "$pkg" || warn "failed to install $pkg"
            done
        fi
    fi
else
    say "Skipping packages (--no-packages)"
fi

# eza isn't in every distro's repos (e.g. Debian 12). Fall back to the upstream
# release binary in ~/.local/bin, unless exa is already there.
if [ "$DO_BINARIES" -eq 1 ] && ! have eza && ! have exa && [ ! -x "$HOME/.local/bin/eza" ] && have curl; then
    case "$(uname -m)" in
        x86_64|amd64)  eza_arch=x86_64 ;;
        aarch64|arm64) eza_arch=aarch64 ;;
        *)             eza_arch= ;;
    esac
    if [ -n "$eza_arch" ] && [ "$(uname -s)" = Linux ]; then
        say "Fetching eza release binary into ~/.local/bin"
        url="https://github.com/eza-community/eza/releases/latest/download/eza_${eza_arch}-unknown-linux-gnu.tar.gz"
        if [ "$DRY" -eq 1 ]; then
            echo "   [dry-run] curl -fsSL $url | tar xz -C ~/.local/bin"
        else
            mkdir -p "$HOME/.local/bin"
            tmp=$(mktemp -d)
            if curl -fsSL "$url" | tar xz -C "$tmp" && [ -f "$tmp/eza" ]; then
                install -m 0755 "$tmp/eza" "$HOME/.local/bin/eza"
            else
                warn "could not fetch eza; ls aliases will fall back to plain ls"
            fi
            rm -rf "$tmp"
        fi
    fi
fi

# ---------------------------------------------------------------------------
# 2. fzf from upstream git (distro packages are often old). All install
#    questions are answered by flags and stdin is /dev/null, so it never prompts.
#    --no-update-rc: our ~/.bashrc block sources ~/.fzf.bash instead.
# ---------------------------------------------------------------------------
FZF_DIR="$HOME/.fzf"
if [ "$DO_FZF" -eq 0 ]; then
    say "Skipping fzf (--no-fzf)"
elif ! have git; then
    warn "git not found; skipping fzf"
elif [ -e "$FZF_DIR" ] && [ ! -d "$FZF_DIR/.git" ]; then
    warn "$FZF_DIR exists but is not a git clone; leaving it alone"
else
    if [ -d "$FZF_DIR/.git" ]; then
        say "Updating $FZF_DIR"
        run git -C "$FZF_DIR" pull --quiet --ff-only || warn "could not update $FZF_DIR; using it as-is"
    else
        say "Cloning fzf into $FZF_DIR"
        run git clone --quiet --depth 1 https://github.com/junegunn/fzf.git "$FZF_DIR"
    fi
    if [ "$DRY" -eq 1 ]; then
        echo "   [dry-run] $FZF_DIR/install --key-bindings --completion --no-update-rc --no-zsh --no-fish </dev/null"
    else
        "$FZF_DIR/install" --key-bindings --completion --no-update-rc --no-zsh --no-fish </dev/null \
            || warn "fzf install failed"
    fi
fi

# ---------------------------------------------------------------------------
# 3. ~/.bashrc managed block
# ---------------------------------------------------------------------------
say "Wiring $BASHRC"
block="$MARK_BEGIN
# Managed by shell-setup. Edit via the repo, not here.
[ -f \"$ROOT/aliases.sh\" ] && . \"$ROOT/aliases.sh\"
[ -f \"$ROOT/fzf.bash\" ] && . \"$ROOT/fzf.bash\"
$MARK_END"

if [ "$DRY" -eq 1 ]; then
    echo "   [dry-run] ensure this block is in $BASHRC:"; echo "$block" | sed 's/^/      /'
else
    [ -f "$BASHRC" ] || : > "$BASHRC"
    if [ ! -f "$BASHRC.pre-shell-setup" ]; then
        cp -p "$BASHRC" "$BASHRC.pre-shell-setup"
        say "Backed up original to $BASHRC.pre-shell-setup"
    fi
    tmp=$(mktemp)
    strip_block "$BASHRC" | trim_blank > "$tmp"
    { cat "$tmp"; [ -s "$tmp" ] && echo; echo "$block"; } > "$BASHRC"
    rm -f "$tmp"
fi

remove_legacy_git_include

say "Done. Open a new shell, or run:  exec bash"
