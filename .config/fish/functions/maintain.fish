# ~/dotfiles/fish/.config/fish/functions/maintain.fish

function maintain --description "Full maintenance pass: Homebrew, fisher, manifests, shell snapshots"
    argparse f/force -- $argv; or return 2

    set -l marker ~/.brew_last_update
    set -l lock_file ~/.brew_update.lock
    set -l brew_ok 1

    echo "🔄 1. Updating System Software..."

    # config.fish launches brew_daily_update in the background on the first shell
    # of the day, and it holds this lock for its whole update/upgrade/cleanup run.
    # Racing it just trips Homebrew's own lockf: `brew update` returns non-zero, the
    # rest of the chain is skipped, and nothing on the Homebrew side gets updated.
    # Share the lock instead of fighting over it.
    set -l lock_pid ""
    test -f $lock_file; and read lock_pid <$lock_file

    if test -n "$lock_pid"; and kill -0 $lock_pid 2>/dev/null
        echo "   ⏭  brew_daily_update is already running (PID $lock_pid) — skipping Homebrew."
        set brew_ok 0
    else
        test -n "$lock_pid"; and echo "   🧹 Clearing stale lock from dead PID $lock_pid."
        echo $fish_pid >$lock_file

        # Source builds from the gromgit/fuse tap need macFUSE's .pc files where
        # the tap looks for them, and Homebrew wipes that directory on update-reset.
        ensure-macfuse-pkgconfig

        # Each step is checked on its own. The old `brew update; and brew upgrade;
        # and brew cleanup` chain swallowed a failing step: the run reported success
        # while upgrade and cleanup had never executed.
        for step in update upgrade cleanup
            if not brew $step
                echo "   ❌ 'brew $step' failed — see the output above." >&2
                set brew_ok 0
                break
            end
        end

        rm -f $lock_file
    end

    echo "🎣 2. Updating Fisher Plugins..."

    # `fisher update` with no arguments has no version check: every installed
    # plugin goes into its update list, gets re-fetched from the repo's HEAD
    # tarball, and is removed and reinstalled — whether or not anything changed.
    # Run daily that is seven GitHub API calls and a full reinstall to land
    # byte-identical files, and fisher itself bails out on an API rate limit.
    # Once a week is plenty for HEAD-tracking plugins; `maintain --force` runs it
    # on demand.
    set -l fisher_marker $HOME/.local/state/fisher-last-update
    set -l fisher_interval 604800 # 7 days, in seconds
    set -l fisher_last 0
    test -f $fisher_marker; and read fisher_last <$fisher_marker
    string match -qr '^\d+$' -- "$fisher_last"; or set fisher_last 0

    set -l now (date +%s)
    if set -q _flag_force; or test (math "$now - $fisher_last") -ge $fisher_interval
        if fisher update
            mkdir -p (path dirname $fisher_marker)
            echo $now >$fisher_marker
        else
            echo "   ❌ 'fisher update' failed — marker left alone so the next run retries." >&2
        end
    else
        set -l days (math -s0 "($now - $fisher_last) / 86400")
        echo "   ⏭  Updated $days day(s) ago — skipping. Run 'maintain --force' to update now."
    end

    echo "📝 3. Updating Brewfile..."
    # Dumps current state to the symlinked .Brewfile in your repo.
    # Descriptions are the default since Homebrew 6; --describe is deprecated.
    brew bundle dump --global --force

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

    # Only claim the day when Homebrew actually finished. Stamping the marker
    # unconditionally tells the background job there is nothing left to do, so a
    # failed upgrade would sit unnoticed until tomorrow.
    if test $brew_ok -eq 1
        date +%Y-%m-%d >$marker
        echo "✅ System Synced!"
    else
        echo "⚠️  Everything except Homebrew is synced. Marker left untouched so brew_daily_update retries." >&2
        return 1
    end
end
