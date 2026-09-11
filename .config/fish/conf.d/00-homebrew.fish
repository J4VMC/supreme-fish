# =============================================================================
# 00-homebrew.fish --- Homebrew environment, architecture-agnostic
# =============================================================================
#
# Homebrew's prefix depends on the CPU, not on anything we control:
#   * Apple silicon: /opt/homebrew
#   * Intel:         /usr/local
#
# This lives in conf.d, not config.fish, and its name sorts first on purpose:
# fish sources conf.d in filename order, and all of conf.d BEFORE config.fish.
# The generated snapshots that follow (pyenv_init.fish, starship_init.fish,
# direnv_hook.fish) reference "$HOMEBREW_PREFIX/..." instead of a hardcoded
# prefix, and pyenv_init.fish runs `pyenv rehash` at load time, so both the
# variable and the Homebrew bin dir must already be in place when they load.
# Non-login shells do not run path_helper, so /opt/homebrew/bin is not on PATH
# by default on Apple silicon -- unlike /usr/local/bin, which /etc/paths
# provides everywhere. That asymmetry is why "it works on Intel" was never a
# guarantee for Apple silicon.
#
# NOTE on MANPATH/INFOPATH: the trailing '' element exports a trailing colon
# (e.g. "/opt/homebrew/share/man:"), which tells man/info "ALSO search the
# system defaults". Without it, setting MANPATH at all makes it exclusive --
# `man ls` and every other system man page silently stopped resolving.
# (`brew shellenv` emits the same trailing colon for the same reason.)
if test -d /opt/homebrew # Apple silicon
    set -gx HOMEBREW_PREFIX /opt/homebrew
    set -gx HOMEBREW_CELLAR /opt/homebrew/Cellar
    set -gx HOMEBREW_REPOSITORY /opt/homebrew
else if test -d /usr/local/Homebrew # Intel
    set -gx HOMEBREW_PREFIX /usr/local
    set -gx HOMEBREW_CELLAR /usr/local/Cellar
    set -gx HOMEBREW_REPOSITORY /usr/local/Homebrew
end

if set -q HOMEBREW_PREFIX
    fish_add_path -g $HOMEBREW_PREFIX/bin $HOMEBREW_PREFIX/sbin
    set -gx MANPATH $HOMEBREW_PREFIX/share/man $MANPATH ''
    set -gx INFOPATH $HOMEBREW_PREFIX/share/info $INFOPATH ''

    # --- Homebrew Completions ---
    if test -d "$HOMEBREW_PREFIX/share/fish/completions"
        set -p fish_complete_path "$HOMEBREW_PREFIX/share/fish/completions"
    end
    if test -d "$HOMEBREW_PREFIX/share/fish/vendor_completions.d"
        set -p fish_complete_path "$HOMEBREW_PREFIX/share/fish/vendor_completions.d"
    end
end
