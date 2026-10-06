# shell-setup

One command to set up a Linux shell: fzf, Tab completion, `z` directory jumping,
nicer `ls`/`cat`, a git-aware prompt, and a private dotenv file. Safe to re-run.

## Install

```sh
curl -fsSL https://raw.githubusercontent.com/saif191020/shell-setup/main/install.sh | sh
```

Or clone and run it (preview first with `--dry-run`):

```sh
git clone https://github.com/saif191020/shell-setup.git ~/.local/share/shell-setup
sh ~/.local/share/shell-setup/install.sh --dry-run
sh ~/.local/share/shell-setup/install.sh
```

Open a new shell, or run `exec bash`. To update, run the installer again.

Supports Linux with bash and apt, dnf, pacman, apk or brew. It installs
`git curl fzf bat eza xclip ripgrep fd bash-completion` if missing (using `sudo`
when not root) and adds one block to `~/.bashrc`. Your original `.bashrc` is saved as
`~/.bashrc.pre-shell-setup`.

| Flag | Effect |
|---|---|
| `--dry-run` | Print actions, change nothing |
| `--no-packages` | Don't install packages |
| `--no-binaries` | Don't download release binaries |
| `--uninstall` | Remove the `~/.bashrc` block and git include |

## Use

| Key / command | Does |
|---|---|
| `Ctrl-R` / `Ctrl-T` / `Alt-C` | fuzzy history / files / cd |
| `<Tab>` | completion in fzf, current level only (one match completes straight away) |
| `**<Tab>` | recursive fuzzy path search (`vim **<Tab>`) |
| `z foo`, `zi` | jump to a frequent directory, or pick one with fzf |
| `fe`, `fcd`, `frg`, `fkill`, `fssh`, `fman` | fuzzy open file, cd, grep, kill, ssh, man |
| `fbr`, `fgl`, `fgs` | fuzzy git branch, log, stage |
| `mkcd`, `extract`, `serve`, `lports` | small utilities |
| `shell-setup-help` | cheat sheet |

Aliases: `ls ll la lt lS` (eza), `cat` (bat), `g gs gd gl gp gc gco`, `cls`, `reload`,
`pbcopy`, `pbpaste`, `myip`, and `up down pull dps` if docker is installed.
Icons need a [Nerd Font](https://www.nerdfonts.com/).

## Your own config

Kept outside the repo in `~/.config/shell-setup/`:

- `env`: dotenv file (`KEY=value`), exported into every interactive shell. Put secrets here.
- `local.bash`: your per-machine aliases and functions, loaded last.

Put `SHELL_SETUP_FZF_TAB=0` in `env` to keep plain bash Tab completion instead of fzf.
