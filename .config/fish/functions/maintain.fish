# ~/dotfiles/fish/.config/fish/functions/maintain.fish

function maintain
    echo "🔄 1. Updating System Software..."
    brew update; and brew upgrade; and brew cleanup

    echo "🎣 2. Updating Fisher Plugins..."
    fisher update

    echo "📝 3. Updating Brewfile..."
    # Dumps current state to the symlinked .Brewfile in your repo
    brew bundle dump --global --describe --force

    echo "📦 4. Updating global npm packages..."
    if type -q npm
        npm update -g
        # Dumps current state to the symlinked .npm-globals in your repo
        npm-globals dump
    else
        echo "   ⏭  npm not on PATH — skipped."
    end

    echo "🐟 5. Regenerating shell init snapshots..."
    # Refresh the committed conf.d snapshots so they don't drift after the upgrade above.
    regen-shell-inits

    # Update the timestamp so the background job doesn't run today
    date +%Y-%m-%d >~/.brew_last_update

    echo "✅ System Synced!"
end
