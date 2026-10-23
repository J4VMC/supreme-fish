# AGENTS.md — supreme-fish

Instructions for AI coding agents working in this repository. [README.md](README.md) describes how the configuration works; this file is the rules.

## Context

This is the `fish` submodule of [J4VMC/supreme-dotfiles](https://github.com/J4VMC/supreme-dotfiles), which stows `.config/fish/` to `~/.config/fish`. Install it **through the dotfiles**, following that repository's `AGENTS.md`; the only standalone install is a symlink of `.config/fish` into `~/.config`. It targets fish 4 on macOS with Homebrew, on Apple silicon or Intel.

If `~/dotfiles/fish` is where you are working, you are inside a submodule checkout: run `git checkout main && git pull --ff-only` before committing (a parent `git pull` leaves it on a detached HEAD), push here first, then bump the pointer in the parent.

## Hard rules

1. **Never hand-edit the snapshots** `conf.d/starship_init.fish`, `conf.d/zoxide_init.fish`, `conf.d/pyenv_init.fish`, or the generated part of `conf.d/direnv_hook.fish`. They are the output of each tool's `init fish`, with the Homebrew prefix and home directory rewritten to `$HOMEBREW_PREFIX` / `$HOME`. Regenerate with `regen-shell-inits` (which `maintain` runs). **Known gap:** `direnv_hook.fish` currently also carries a hand-written `__direnv_update_fish_complete_path` function (vendor-completion refresh on every export) that `regen-shell-inits` does not know about; a regen overwrites the file wholesale and drops it. Until `regen-shell-inits` re-applies that addition itself, check `git diff conf.d/direnv_hook.fish` after every regen and restore the function before committing.
2. **Never hardcode `/opt/homebrew` or `/usr/local`.** Use `$HOMEBREW_PREFIX`, which `conf.d/00-homebrew.fish` sets before anything else loads. Never hardcode a home directory either.
3. **Do not delete or rename `conf.d/direnv.fish`.** It is empty on purpose: it shadows the hook Homebrew's direnv ships in `vendor_conf.d/`.
4. **Do not reorder `conf.d` by accident.** fish sources it alphabetically and before `config.fish`; `00-homebrew.fish` must stay first, and anything that depends on `$HOMEBREW_PREFIX` must sort after it.
5. **Keep `config.fish` split** between the universal section (exported in every shell, including the login shell `exec-path-from-shell` spawns for Emacs) and the `status is-interactive` section. Anything a GUI app needs goes above the guard; prompts, aliases, colours and one-shot banners go below it.
6. **One function per file** in `functions/`, named after the function, with a `--description`. Indent with 4 spaces (`.editorconfig`).
7. **Nothing client-specific.** Private helpers match the gitignored patterns `conf.d/*_autosync.fish` and `functions/*_daily_sync.fish`; anything that names a client, a private host or an account stays on disk and out of commits. `fish_variables`, `plugins/` and `private.fish` are gitignored too; do not force-add them.
8. **Completions:** only snapshot a CLI into `completions/` (via `generate-completions`) when its Homebrew formula ships none. If `$HOMEBREW_PREFIX/share/fish/vendor_completions.d/<cmd>.fish` exists, do not duplicate it.
9. **Node comes only from `nvm.fish`.** Do not add Homebrew's `node` to `PATH` or install npm globals outside the `~/.npm-globals` manifest (`npm-globals dump` / `install`).
10. **Commits follow Conventional Commits** (`lefthook.yml` runs `cog verify`). Do not run `lefthook install`; the dotfiles' global git hooks dispatch to lefthook already. No AI attribution trailers.

## Testing a change

- Syntax: `fish -n <file>` for every edited file.
- Startup: `fish -c 'echo $HOMEBREW_PREFIX; echo $PATH' | head` from a non-interactive shell, and `fish -ic 'type maintain'` for the interactive path. Startup time: `time fish -ic exit`; the snapshots exist to keep this low, so a regression there is a bug.
- A function: `fish -c 'source functions/<name>.fish; <name> --help'` or the function's own usage line.
- After touching `maintain`, `brew_daily_update` or `npm-globals`, read their header comments first: the lock sharing, the daily marker semantics and the manifest header preservation are deliberate and have regressed before.

## Where things are documented

| Topic | Where |
| ----- | ----- |
| Startup order, what each file does, every function | `README.md` |
| Why Homebrew detection lives in `conf.d` | header of `conf.d/00-homebrew.fish` |
| Why `direnv.fish` is empty | the file itself |
| Why npm globals stay out of the Brewfile | comment above `HOMEBREW_BUNDLE_DUMP_NO_NPM` in `config.fish` |
| Install order and the whole machine setup | `AGENTS.md` and `README.md` in the dotfiles repository |
