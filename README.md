# shell-setup

One command to make any Linux box feel like home: fuzzy-everything with
[fzf](https://github.com/junegunn/fzf), proper Tab completion, nicer `ls`/`cat`,
sane history, a git-aware prompt, and a private dotenv file for secrets.

The installer is **idempotent**. Run it again any time to update or repair.

## Install

```sh
curl -fsSL https://raw.githubusercontent.com/saif191020/shell-setup/main/install.sh | sh
```

The repo must be public for this one-liner to work. While it is private, clone it with
your GitHub credentials instead (below).

Prefer to read it first (recommended for any `curl | sh`)?

```sh
git clone https://github.com/saif191020/shell-setup.git ~/.local/share/shell-setup
sh ~/.local/share/shell-setup/install.sh --dry-run   # show what would happen
sh ~/.local/share/shell-setup/install.sh
```

Then open a new shell or run `exec bash`.

### Options

| Flag | Effect |
|---|---|
| `--dry-run` | Print every action, change nothing |
| `--no-packages` | Don't touch the package manager |
| `--no-binaries` | Don't download any release binaries (eza fallback) |
| `--uninstall` | Remove the `~/.bashrc` block and git include (keeps packages and your private files) |

| Env var | Default |
|---|---|
| `SHELL_SETUP_REPO` | URL in `install.sh` |
| `SHELL_SETUP_DIR` | `~/.local/share/shell-setup` |
| `SHELL_SETUP_REF` | `main` |

## What the installer does

1. **Installs packages** that aren't already present, using apt, dnf, pacman, apk
   or brew (with `sudo` if you aren't root): `git curl fzf bat eza xclip ripgrep fd bash-completion`.
   Anything the repos don't have is skipped with a warning, not a failure. Docker is deliberately *not* installed.
2. Creates `~/.local/bin/bat` and `fd` shims on Debian/Ubuntu (they ship as `batcat`/`fdfind`).
   If `eza` isn't packaged (Debian 12), downloads the upstream release to `~/.local/bin`.
3. Adds one marked block to `~/.bashrc` that sources `shell/init.bash`. The first
   run saves your original as `~/.bashrc.pre-shell-setup`. Your own `.bashrc` content is never rewritten.
4. Creates `~/.config/shell-setup/env` (mode 600) and `local.bash` from the examples, only if missing.
5. Adds `config/gitconfig` to your global git config via `include.path`. It sets no name or email.

Updating is the same command again (`git pull` + re-link), or just `git pull` in the clone.

## What you get

### Keys (fzf)

| Key | Action |
|---|---|
| `Ctrl-R` | Fuzzy history search (`Ctrl-Y` copies the entry) |
| `Ctrl-T` | Fuzzy file picker with `bat` preview |
| `Alt-C` | Fuzzy `cd` with tree preview |
| `**<Tab>` | Fuzzy path completion: `vim **<Tab>`, `cd ~/**<Tab>` |
| `kill <Tab>`, `ssh **<Tab>`, `export **<Tab>` | Fuzzy process / host / variable pickers |
| `Ctrl-/` | Toggle preview inside any fzf window |

### Tab completion

`bash-completion` is loaded, matching is case-insensitive, one Tab lists
matches, repeated Tab cycles through them, Shift-Tab goes back, and Up/Down
search history by the prefix you've typed.

### Functions

| Command | Does |
|---|---|
| `fe [query]` | Pick files, open in `$EDITOR` |
| `fcd [dir]` | Pick a subdirectory and `cd` into it |
| `frg <pattern>` | Live ripgrep, open the hit at its line |
| `fkill [sig]` | Pick processes to kill |
| `fman` | Fuzzy man-page search |
| `fssh` | Pick a host from `~/.ssh/config` |
| `fenv`, `fpath` | Browse env var names / PATH entries |
| `fbr` | Checkout a branch, with log preview |
| `fgl` | Browse `git log` graph |
| `fgs` | Stage files interactively |
| `z <dir>`, `zi` | [rupa/z](https://github.com/rupa/z) frecent-directory jump / fzf picker (vendored in `vendor/`) |
| `mkcd`, `extract`, `serve`, `path`, `lports` | Small utilities |
| `shell-setup-help` | Cheat sheet in your terminal |

### Aliases

`ls ll la lt lS` (eza with icons, falls back to plain `ls`), `cat` (bat),
`cls reload myip pbcopy pbpaste`, `g gs gd gds gl gp gc gco`, `.. ... ....`, and
`up down pull docker-update dps` when `docker` exists. Icons need a
[Nerd Font](https://www.nerdfonts.com/) in your terminal emulator.

### Git defaults

`push.autoSetupRemote`, `pull.ff=only`, `fetch.prune`, `rebase.autoStash`,
`merge.conflictStyle=zdiff3`, `rerere`, plus aliases `lg st last undo unstage amend branches`.
Your `~/.gitconfig` still wins for anything it sets.

## Private config (not in this repo)

Everything under `~/.config/shell-setup/` stays on the machine:

- **`env`**: a dotenv file (`KEY=value`), exported into every interactive shell. Put tokens and API keys here.
- **`local.bash`**: per-machine aliases and functions, sourced last.

## Layout

```
install.sh            idempotent bootstrap/installer (POSIX sh)
shell/init.bash       entrypoint sourced from ~/.bashrc
shell/*.bash          path, options, completion, aliases, functions, fzf, z, prompt
vendor/z.sh           rupa/z, pinned (see vendor/README.md)
config/               gitconfig + env/local examples (copied, never edited in place)
scripts/check-secrets.sh, .githooks/pre-commit   secret scan on commit
```

## Contributing / keeping it public safely

After cloning to work on it, enable the secret-scan hook once:

```sh
git config core.hooksPath .githooks
scripts/check-secrets.sh --all   # scan the whole tree by hand
```

The hook blocks private-looking filenames (`.env`, keys, `local.bash`) and common token
patterns. It's a safety net, not a replacement for [gitleaks](https://github.com/gitleaks/gitleaks).
No hostnames, IPs or personal config belong in this repo; use `local.bash`.

## Scope

Linux, bash. macOS/zsh are not targeted.
