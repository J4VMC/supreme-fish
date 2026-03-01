# =============================================================================
# fish_config --- Main configuration for the Fish Shell
# =============================================================================
#
# Commentary:
# This is the entry point for the Fish shell. It handles path setup, 
# environment variables, and interactive features like prompts and aliases.
#
# The file is split into two main parts:
# 1. Universal Setup: Always runs (important for GUI apps like Emacs).
# 2. Interactive Setup: Runs only when you are actually typing in a terminal.
# =============================================================================
# PLUGIN MANAGEMENT (FISHER)
# =============================================================================
set -gx fisher_path $HOME/.config/fish/plugins

if not contains $fisher_path/functions $fish_function_path
    set -gp fish_function_path $fisher_path/functions
end

if not contains $fisher_path/completions $fish_complete_path
    set -gp fish_complete_path $fisher_path/completions
end

for file in $fisher_path/conf.d/*.fish
    if test -f $file
        source $file
    end
end

if status is-interactive; and not type -q fisher
    echo "🎣 Fisher not found. Bootstrapping..."
    curl -sL https://raw.githubusercontent.com/jorgebucaran/fisher/main/functions/fisher.fish | source
    fisher update
end

# =============================================================================
# 1. CORE ENVIRONMENT (PATH & VARIABLES)
# =============================================================================

set -U fish_greeting

# --- Fast Homebrew Initialization ---
if test -d /opt/homebrew # Apple Silicon
    set -gx HOMEBREW_PREFIX /opt/homebrew
    set -gx HOMEBREW_CELLAR /opt/homebrew/Cellar
    set -gx HOMEBREW_REPOSITORY /opt/homebrew
    fish_add_path -g /opt/homebrew/bin /opt/homebrew/sbin
    set -gx MANPATH /opt/homebrew/share/man $MANPATH
    set -gx INFOPATH /opt/homebrew/share/info $INFOPATH
else if test -d /usr/local/Homebrew # Intel Mac
    set -gx HOMEBREW_PREFIX /usr/local
    set -gx HOMEBREW_CELLAR /usr/local/Cellar
    set -gx HOMEBREW_REPOSITORY /usr/local/Homebrew
    fish_add_path -g /usr/local/bin /usr/local/sbin
    set -gx MANPATH /usr/local/share/man $MANPATH
    set -gx INFOPATH /usr/local/share/info $INFOPATH
end

# --- Homebrew Completions ---
if test -d "$HOMEBREW_PREFIX/share/fish/completions"
    set -p fish_complete_path "$HOMEBREW_PREFIX/share/fish/completions"
end
if test -d "$HOMEBREW_PREFIX/share/fish/vendor_completions.d"
    set -p fish_complete_path "$HOMEBREW_PREFIX/share/fish/vendor_completions.d"
end

# --- Custom PATH Additions ---
fish_add_path -g \
    $HOMEBREW_PREFIX/opt/grep/libexec/gnubin \
    $HOME/.cargo/bin \
    "$HOME/Library/Application Support/Coursier/bin" \
    $HOME/.local/bin

# -t opens the buffer directly inside your terminal window (perfect for git commits)
# -a '' automatically starts the daemon in the background if it isn't running yet
set -gx EDITOR "emacsclient -t -a ''"

# VISUAL is used by some GUI-aware tools. -c opens a new graphical window.
set -gx VISUAL "emacsclient -c -a emacs"

# =============================================================================
# 2. INTERACTIVE-ONLY SETUP
# =============================================================================

if status is-interactive

    set -gx GPG_TTY (tty)

    # Syntax-highlighted man pages
    set -gx MANPAGER "bat -l man -p"

    # --- Starship Prompt ---
    # We keep this dynamic because it handles transience, but it's now the ONLY dynamic init
    if command -q starship
        function starship_transient_prompt_func
            starship module character
        end
        enable_transience
    end

    # -------------------------------------------------------------------------
    # BACKGROUND UPDATES
    # -------------------------------------------------------------------------
    set -l last_update (cat ~/.brew_last_update 2>/dev/null)
    set -l today (date +%Y-%m-%d)

    if test "$last_update" != "$today"
        nohup fish -c brew_daily_update >/dev/null 2>&1 &
    end

    # --- System Info ---
    # NOTE: Fastfetch probes hardware. If your terminal is still slightly slow after 
    # applying this config, comment out fastfetch to see if it's the culprit.
    if command -q fastfetch
        fastfetch
    end

    # -------------------------------------------------------------------------
    # ALIASES & ABBREVIATIONS
    # -------------------------------------------------------------------------
    alias python=python3
    abbr -a -g brewed 'brew bundle dump --file=~/dotfiles/homebrew/.Brewfile --force'
    abbr -a -g brewup 'brew update && brew upgrade && brew cleanup'

    if command -q eza
        alias ls='eza --icons'
        alias ll='eza -l --icons'
        alias lt='eza -T --icons'
    end

    if command -q bat
        alias cat='bat --paging=never'
    end

    # -------------------------------------------------------------------------
    # PLUGIN CONFIGURATIONS & THEME
    # -------------------------------------------------------------------------
    set -g puffer_fish_color 8ec07c
    set -g __fish_abbreviation_tips_enable_on_command_execution 1

    set -g fish_color_normal ebdbb2
    set -g fish_color_command b8bb26
    set -g fish_color_quote d79921
    set -g fish_color_redirection d3869b
    set -g fish_color_end 83a598
    set -g fish_color_error fb4934
    set -g fish_color_param 8ec07c
    set -g fish_color_comment 928374
end
