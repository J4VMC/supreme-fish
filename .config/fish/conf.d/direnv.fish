# Intentionally empty: shadows Homebrew's vendor_conf.d/direnv.fish (direnv >= 2.38),
# which runs `<Cellar path>/direnv hook fish | source` on every shell start. That is
# slower than the static snapshot in direnv_hook.fish and its versioned Cellar path
# breaks any fish session left open across a `brew upgrade direnv`.
