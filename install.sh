#!/bin/sh
# shell-setup installer. Idempotent: run it as often as you like.
#
#   curl -fsSL https://raw.githubusercontent.com/<you>/shell-setup/main/install.sh | sh
#   sh install.sh [--dry-run] [--no-packages] [--no-binaries] [--uninstall]
#
# Environment:
#   SHELL_SETUP_REPO  git URL to clone when run via a pipe (required then,
#                     unless the default below has been edited)
#   SHELL_SETUP_DIR   where the clone lives (default ~/.local/share/shell-setup)
#   SHELL_SETUP_REF   branch/tag to track (default main)

set -eu

REPO_URL="${SHELL_SETUP_REPO:-https://github.com/saif191020/shell-setup.git}"
INSTALL_DIR="${SHELL_SETUP_DIR:-$HOME/.local/share/shell-setup}"
REF="${SHELL_SETUP_REF:-main}"
CONF_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/shell-setup"
BASHRC="$HOME/.bashrc"
MARK_BEGIN='# >>> shell-setup >>>'
MARK_END='# <<< shell-setup <<<'

DRY=0
DO_PACKAGES=1
DO_BINARIES=1
UNINSTALL=0
for arg in "$@"; do
    case "$arg" in
        --dry-run) DRY=1 ;;
        --no-packages) DO_PACKAGES=0 ;;
        --no-binaries) DO_BINARIES=0 ;;
        --uninstall) UNINSTALL=1 ;;
        -h|--help) sed -n '2,13p' "$0" 2>/dev/null | sed 's/^# \{0,1\}//'; exit 0 ;;
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

SUDO=
if [ "$(id -u)" -ne 0 ]; then
    if have sudo; then SUDO=sudo; fi
fi

PM=
if have apt-get; then PM=apt
elif have dnf; then PM=dnf
elif have pacman; then PM=pacman
elif have apk; then PM=apk
elif have brew; then PM=brew
fi

pm_install() {
    # $1 = package name. Returns non-zero if it could not be installed.
    case "$PM" in
        apt)    run $SUDO env DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends "$1" ;;
        dnf)    run $SUDO dnf install -y "$1" ;;
        pacman) run $SUDO pacman -S --needed --noconfirm "$1" ;;
        apk)    run $SUDO apk add "$1" ;;
        brew)   run brew install "$1" ;;
        *)      return 1 ;;
    esac
}

pm_has_package() {
    # Is this package available in the configured repos?
    case "$PM" in
        apt)    apt-cache show "$1" >/dev/null 2>&1 ;;
        dnf)    dnf info "$1" >/dev/null 2>&1 ;;
        pacman) pacman -Si "$1" >/dev/null 2>&1 ;;
        apk)    apk search -e "$1" 2>/dev/null | grep -q . ;;
        brew)   brew info "$1" >/dev/null 2>&1 ;;
        *)      return 1 ;;
    esac
}

# tool -> package name for this package manager
pkg_for() {
    case "$1:$PM" in
        fd:apt|fd:dnf) echo fd-find ;;
        fd:*)          echo fd ;;
        rg:*)          echo ripgrep ;;
        bash-completion:brew) echo bash-completion@2 ;;
        *)             echo "$1" ;;
    esac
}

tool_present() {
    case "$1" in
        bat)  have bat || have batcat ;;
        fd)   have fd || have fdfind ;;
        eza)  have eza || have exa ;;
        bash-completion)
            [ -r /usr/share/bash-completion/bash_completion ] || [ -r /etc/bash_completion ] \
                || [ -r /opt/homebrew/etc/profile.d/bash_completion.sh ] \
                || [ -r /usr/local/etc/profile.d/bash_completion.sh ] ;;
        *)    have "$1" ;;
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

if [ -z "$script_dir" ] || [ ! -f "$script_dir/shell/init.bash" ]; then
    case "$REPO_URL" in *saif191020*) die "set SHELL_SETUP_REPO to your repo's git URL (or edit REPO_URL in install.sh)" ;; esac
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

# ---------------------------------------------------------------------------
# ~/.bashrc managed block
# ---------------------------------------------------------------------------
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

if [ "$UNINSTALL" -eq 1 ]; then
    say "Removing managed block from $BASHRC"
    if [ -f "$BASHRC" ] && grep -qF "$MARK_BEGIN" "$BASHRC"; then
        if [ "$DRY" -eq 1 ]; then echo "   [dry-run] rewrite $BASHRC without block"
        else
            tmp=$(mktemp); strip_block "$BASHRC" | trim_blank > "$tmp"; cat "$tmp" > "$BASHRC"; rm -f "$tmp"
        fi
    fi
    if git config --global --get-all include.path 2>/dev/null | grep -qxF "$ROOT/config/gitconfig"; then
        run git config --global --unset include.path "^$ROOT/config/gitconfig\$" || true
    fi
    say "Done. Left in place: $ROOT, $CONF_DIR (your env/local files), installed packages."
    exit 0
fi

# ---------------------------------------------------------------------------
# 1. Packages
# ---------------------------------------------------------------------------
if [ "$DO_PACKAGES" -eq 1 ]; then
    if [ -z "$PM" ]; then
        warn "no supported package manager found; skipping package install"
    elif [ -z "$SUDO" ] && [ "$(id -u)" -ne 0 ] && [ "$PM" != brew ]; then
        warn "not root and no sudo; skipping package install"
    else
        missing=
        for t in git curl fzf bat eza xclip rg fd bash-completion; do
            tool_present "$t" || missing="$missing $t"
        done
        if [ -z "$missing" ]; then
            say "All packages already installed"
        else
            say "Installing:$missing  (via $PM)"
            [ "$PM" = apt ] && { run $SUDO apt-get update -qq || warn "apt-get update failed"; }
            for t in $missing; do
                pkg=$(pkg_for "$t")
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

# ---------------------------------------------------------------------------
# 2. ~/.local/bin shims + eza fallback
# ---------------------------------------------------------------------------
run mkdir -p "$HOME/.local/bin"
# Debian renames these; give them their upstream names.
if ! have bat && have batcat && [ ! -e "$HOME/.local/bin/bat" ]; then
    run ln -s "$(command -v batcat)" "$HOME/.local/bin/bat"
fi
if ! have fd && have fdfind && [ ! -e "$HOME/.local/bin/fd" ]; then
    run ln -s "$(command -v fdfind)" "$HOME/.local/bin/fd"
fi

# eza isn't in every distro's repos (e.g. Debian 12). Fall back to the upstream
# release tarball, installed to ~/.local/bin.
if [ "$DO_BINARIES" -eq 1 ] && ! have eza && [ ! -x "$HOME/.local/bin/eza" ] && have curl; then
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
# 3. ~/.bashrc managed block
# ---------------------------------------------------------------------------
say "Wiring $BASHRC"
block="$MARK_BEGIN
# Managed by shell-setup. Edit via the repo, not here.
[ -f \"$ROOT/shell/init.bash\" ] && . \"$ROOT/shell/init.bash\"
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
    strip_block "$BASHRC" > "$tmp"
    trim_blank < "$tmp" > "$tmp.2"
    { cat "$tmp.2"; [ -s "$tmp.2" ] && echo; echo "$block"; } > "$BASHRC"
    rm -f "$tmp" "$tmp.2"
fi

# ---------------------------------------------------------------------------
# 4. Private config (dotenv + local overrides)
# ---------------------------------------------------------------------------
say "Private config in $CONF_DIR"
run mkdir -p "$CONF_DIR"
if [ ! -f "$CONF_DIR/env" ]; then
    run cp "$ROOT/config/env.example" "$CONF_DIR/env"
    run chmod 600 "$CONF_DIR/env"
fi
if [ ! -f "$CONF_DIR/local.bash" ]; then
    run cp "$ROOT/config/local.bash.example" "$CONF_DIR/local.bash"
fi

# ---------------------------------------------------------------------------
# 5. Git defaults (identity-free), via include.path
# ---------------------------------------------------------------------------
if have git; then
    if git config --global --get-all include.path 2>/dev/null | grep -qxF "$ROOT/config/gitconfig"; then
        say "Git defaults already included"
    else
        say "Including git defaults"
        run git config --global --add include.path "$ROOT/config/gitconfig"
    fi
fi

say "Done. Open a new shell, or run:  exec bash"
