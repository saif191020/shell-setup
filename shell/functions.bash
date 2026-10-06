# Small helper functions.

# mkdir + cd
mkcd() { mkdir -p -- "$1" && cd -- "$1" || return; }

# Extract almost any archive.
extract() {
    local f
    for f in "$@"; do
        [ -f "$f" ] || { echo "extract: '$f' is not a file" >&2; continue; }
        case "$f" in
            *.tar.bz2|*.tbz2) tar xjf "$f" ;;
            *.tar.gz|*.tgz)   tar xzf "$f" ;;
            *.tar.xz|*.txz)   tar xJf "$f" ;;
            *.tar.zst)        tar --zstd -xf "$f" ;;
            *.tar)            tar xf "$f" ;;
            *.bz2)            bunzip2 "$f" ;;
            *.gz)             gunzip "$f" ;;
            *.xz)             unxz "$f" ;;
            *.zip)            unzip "$f" ;;
            *.7z)             7z x "$f" ;;
            *.rar)            unrar x "$f" ;;
            *) echo "extract: don't know how to extract '$f'" >&2 ;;
        esac
    done
}

# Quick local web server for the current directory: serve [port]
serve() { python3 -m http.server "${1:-8000}"; }

# Show PATH one entry per line.
path() { printf '%s\n' "${PATH//:/$'\n'}"; }

# Which ports are listening, and who owns them.
lports() { ss -tulpn 2>/dev/null | sed 's/  */ /g' | column -t -s' ' | head -n "${1:-50}"; }

# Open a quick reminder of what this setup provides.
shell-setup-help() {
    cat <<'EOF'
Keys:   Ctrl-R history   Ctrl-T files   Alt-C cd   **<TAB> fuzzy path completion
Funcs:  fe fcd frg fkill fbr fgl fgs fman fssh fenv fpath   (see shell/fzf.bash)
Misc:   mkcd extract serve path lports   z <dir> / zi (jump)
Config: ~/.config/shell-setup/env (secrets/dotenv), local.bash (per-machine)
EOF
}
