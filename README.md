# shell-setup

My shell aliases, plus the tools they use (`eza`, `bat`, `xclip`, `curl`).
Safe to re-run.

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

Then open a new shell or run `exec bash`. To update, run the installer again.

It installs any missing tools (apt, dnf, pacman or apk, using `sudo` when not root)
and adds one block to `~/.bashrc` that sources `aliases.sh`. The original is saved
as `~/.bashrc.pre-shell-setup`.

| Flag | Effect |
|---|---|
| `--dry-run` | Print actions, change nothing |
| `--no-packages` | Don't install packages |
| `--no-binaries` | Don't download the eza release binary (used when eza isn't packaged) |
| `--uninstall` | Remove the `~/.bashrc` block |

## Aliases

| Alias | Runs |
|---|---|
| `ls` `ll` `la` `lt` `lS` | eza (or exa) with icons; plain `ls` if neither is installed |
| `cat` | bat / batcat |
| `pbcopy` `pbpaste` | xclip clipboard |
| `myip` | `curl ifconfig.me` |
| `up` `down` `pull` `docker-update` | docker compose |
| `cls` `reload` `refresh` | clear, re-source `~/.bashrc` |

Icons need a [Nerd Font](https://www.nerdfonts.com/).
