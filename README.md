# Fish Shell Configuration

The Fish shell half of the [dotfiles](https://github.com/J4VMC/supreme-dotfiles) repository, where it is the `fish` submodule and `stow fish` links it to `~/.config/fish`. It is written for macOS with Homebrew on either Apple silicon or Intel: nothing in here hardcodes the Homebrew prefix or the home directory.

Install it through the dotfiles (the order there matters: stow fish **before** the first fish shell ever starts, see the dotfiles README). To use it on its own:

```bash
git clone git@github.com:J4VMC/supreme-fish.git ~/supreme-fish
ln -s ~/supreme-fish/.config/fish ~/.config/fish
```

Everything below assumes fish 4, `starship`, `zoxide`, `direnv`, `pyenv`, `eza`, `bat`, `fzf` and `fastfetch` from Homebrew (the dotfiles Brewfile installs all of them).

## Layout

```
.config/fish/
├── config.fish          # entry point: plugin bootstrap, PATH/env, interactive setup
├── fish_plugins         # fisher's plugin list (the installed copies are gitignored)
├── conf.d/              # sourced before config.fish, in filename order
│   ├── 00-homebrew.fish     # HOMEBREW_PREFIX detection, PATH, MANPATH, completions
│   ├── direnv.fish          # empty on purpose: shadows Homebrew's vendor_conf.d hook
│   ├── direnv_hook.fish     # snapshot of `direnv hook fish` + completion-path refresh
│   ├── pyenv_init.fish      # snapshot of `pyenv init - fish`
│   ├── starship_init.fish   # snapshot of `starship init fish`
│   ├── zoxide_init.fish     # snapshot of `zoxide init fish`
│   └── rustup.fish          # sources ~/.cargo/env.fish when rustup is installed
├── functions/           # one autoloaded function per file (listed below)
└── completions/         # snapshots for CLIs that do not ship fish completions
```

`lefthook.yml` at the repository root runs `cog verify` on every commit message (Conventional Commits). Do not run `lefthook install`: the dotfiles' global git hooks dispatch to it already.

## How startup works

1. **`conf.d/00-homebrew.fish`** runs first (fish sources `conf.d` alphabetically, and all of it before `config.fish`). It detects the prefix (`/opt/homebrew` or `/usr/local`), exports `HOMEBREW_PREFIX`, puts the Homebrew `bin` and `sbin` on `PATH`, sets `MANPATH`/`INFOPATH` with the trailing colon that keeps the system pages reachable, and adds Homebrew's fish completion directories. Non-login shells on Apple silicon do not get `/opt/homebrew/bin` from `path_helper`, which is why this cannot wait for `config.fish`.
2. **The `*_init.fish` / `*_hook.fish` snapshots** load next. They are the saved output of each tool's `init fish` command, with the Homebrew prefix and home directory rewritten to `$HOMEBREW_PREFIX` and `$HOME`, so sourcing a static file replaces spawning the tool on every shell start. They drift when the tools are upgraded; `regen-shell-inits` rewrites them, and `maintain` calls it after every upgrade. Never edit them by hand.
3. **`config.fish`** then:
   - points `fisher_path` at `plugins/` (gitignored) and sources the plugins' `conf.d`; on an interactive shell without fisher it bootstraps fisher and runs `fisher update`.
   - exports `HOMEBREW_BUNDLE_DUMP_NO_NPM` so `brew bundle dump` never writes npm globals into the Brewfile (they live in `~/.npm-globals`, see `npm-globals`).
   - builds `PATH`: Homebrew's `ruby` and the gem bin directories (globbed, not version-pinned), GNU `grep`, `~/.cargo/bin`, `~/go/bin` (where the Brewfile's `go "..."` tools land), `~/.local/bin`, Coursier, then nvm's default Node (`$nvm_default_version`, which must be a concrete `vX.Y.Z`, set with `set -U nvm_default_version (node --version)` after `nvm install lts`), and finally moves the pyenv shims back to the front so they beat Homebrew's `python3`.
   - sets `EDITOR` (`emacsclient -t`), `VISUAL` (`emacsclient -c`), `JAVA_HOME` (via the stable `opt/openjdk` symlink), `PYENV_ROOT`, `PLAYWRIGHT_BROWSERS_PATH`, and `BROWSER=~/bin/chrome-route` so CLIs that open login URLs go through the Chrome profile router from the dotfiles.
   - in interactive shells only: Starship with a transient prompt, `MANPAGER=bat`, the once-a-day background `brew_daily_update`, `fastfetch` on the first real terminal of each boot, the aliases and abbreviations below, and the Gruvbox colours.

The split matters for GUI apps: everything above the `status is-interactive` guard is what `exec-path-from-shell` hands to Emacs, so Emacs sees nvm's Node, the Go tools, pyenv and the rest without any terminal involved.

## direnv

`direnv_hook.fish` is the snapshot of `direnv hook fish`. Since direnv 2.38 that hook does one more thing after every export: it appends each `vendor_completions.d` directory that the `.envrc` added to `XDG_DATA_DIRS` to `fish_complete_path` (and drops the ones it withdrew), so project-local completions work without opening a new shell. The snapshot carries that logic verbatim, and `regen-shell-inits` reproduces it exactly, so it needs no special handling.

`direnv.fish` is intentionally empty. Since direnv 2.38 the Homebrew formula ships `vendor_conf.d/direnv.fish`, which runs `<Cellar path>/direnv hook fish | source` on every shell start — slower than the snapshot, and the versioned Cellar path breaks every fish session left open across a `brew upgrade direnv`. A file of the same name in the user `conf.d` takes precedence, which turns the vendor hook off.

The hook only fires at a fish prompt. Non-interactive zsh (the Claude desktop app's tool shell) gets the same `.envrc` through `zsh/.zshenv` in the dotfiles.

## Functions

| Function | What it does |
| -------- | ------------ |
| `maintain [--force]` | The one maintenance entry point: `brew update`/`upgrade`/`cleanup` (each step checked; shares the lock with `brew_daily_update` instead of racing it, and relinks the macFUSE pkg-config first), `fisher update` at most weekly (`--force` runs it now), `brew bundle dump --global --force`, `npm update -g` + `npm-globals dump`, then `regen-shell-inits`. Stamps `~/.brew_last_update` only when the Homebrew steps all succeeded, so a failed upgrade is retried by the background job. |
| `brew_daily_update` | What `config.fish` launches in the background once a day: update, upgrade, cleanup, logged to `~/.brew-update.log`, guarded by a PID lock in `~/.brew_update.lock` that cleans itself up. |
| `regen-shell-inits` | Re-snapshots `starship`, `zoxide`, `direnv` and `pyenv` into `conf.d/`, replacing the absolute Homebrew prefix and home directory with `$HOMEBREW_PREFIX` and `$HOME`. |
| `npm-globals [install\|dump]` | `install` (the default) installs every package in `~/.npm-globals` into the active Node version; `dump` rewrites the package list from `npm ls -g` and keeps the manifest's header comments. Needs `jq` for `dump`. |
| `generate-completions <cmd> [args…]` | Runs the given completion generator and saves its output to `completions/<cmd>.fish`. Only for CLIs whose Homebrew formula ships no completions (`jules`, `ngrok`, `symfony` are the current snapshots); `gh`, `docker` and friends are picked up from `vendor_completions.d` and must not be duplicated here. |
| `init-git` | `git init` plus a `lefthook.yml` with the `cog verify` Conventional Commits check, unless one exists. |
| `repo-clone <url>` | `git clone`, `cd` in, and add the same `lefthook.yml` unless the project already uses lefthook, pre-commit or husky. |
| `ensure-macfuse-pkgconfig` | Relinks macFUSE's `.pc` files where the `gromgit/fuse` tap looks for them; Homebrew removes that directory on update, so `maintain` and `brew_daily_update` call this before upgrading. |
| `s3mount <bucket> [dir]` / `s3unmount <dir>` | Mount an S3 bucket in the current directory with `rclone-mac` (`gromgit/fuse` tap, needs `macfuse`) using `AWS_PROFILE`, full VFS cache, 5 s write-back. |
| `start-n8n` / `stop-n8n` | Run n8n as a detached Docker container on port 5678 with a persistent `n8n_data` volume. |

## Aliases and abbreviations

| Name | Expands to |
| ---- | ---------- |
| `ls` / `ll` / `lt` | `eza --icons` / `eza -l --icons` / `eza -T --icons` |
| `cat` | `bat --paging=never` |
| `python` | `python3` |
| `brewed` | `brew bundle dump --global --force` |
| `brewup` | `maintain` |

## Plugins (`fish_plugins`)

Managed by [fisher](https://github.com/jorgebucaran/fisher), installed into the gitignored `plugins/` directory so the repository only tracks the list:

- `jorgebucaran/nvm.fish` — Node version manager; the only source of Node in this setup.
- `patrickf1/fzf.fish` — fuzzy search keybindings (`Ctrl-R` history, `Ctrl-Alt-F` files, …).
- `nickeb96/puffer-fish` — expands `!!`, `!$`, `$$` and `...`.
- `meaningful-ooo/sponge` — keeps failed commands out of history.
- `gazorby/fish-abbreviation-tips` — reminds you when an alias or abbreviation exists for what you typed.
- `edc/bass` — runs bash utilities that only know how to export to bash.

## Not tracked

`.config/fish/.gitignore` keeps these out of the repository: `fish_variables` (universal variables, per machine), `plugins/` (fisher's installs, rebuilt from `fish_plugins`), `private.fish` (reserved for secrets; nothing tracked sources it, so add a `source` line locally if you use it), `*.cache`, and the client-specific `conf.d/*_autosync.fish` / `functions/*_daily_sync.fish` helpers, which name private infrastructure and stay on disk only.
