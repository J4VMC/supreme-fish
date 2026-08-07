# ~/dotfiles/fish/.config/fish/functions/npm-globals.fish
#
# Global npm packages as a stowed manifest, mirroring `.Brewfile` + `brew bundle`.
# The manifest lives at ~/.npm-globals, symlinked into this repository by `stow npm`.

function npm-globals --description "Install or dump the global npm package manifest (~/.npm-globals)"
    set -l manifest $HOME/.npm-globals
    set -l cmd $argv[1]
    test -z "$cmd"; and set cmd install

    if not type -q npm
        echo "❌ npm not on PATH — install Node first (nvm install lts)."
        return 1
    end

    switch $cmd
        case dump
            if not type -q jq
                echo "❌ jq required for dump (brew install jq)."
                return 1
            end

            # Keep the manifest's header comments; only the package list is rewritten.
            set -l header
            if test -e $manifest
                for line in (cat $manifest)
                    string match -qr '^\s*(#|$)' -- $line; or break
                    set -a header $line
                end
            end

            # npm ls exits non-zero on extraneous/peer complaints; the JSON is still good.
            set -l listing (npm ls -g --depth=0 --json 2>/dev/null)
            set -l packages (printf '%s\n' $listing \
                | jq -r '.dependencies // {} | keys[]' \
                | string match -rv '^(npm|corepack)$')

            if test (count $packages) -eq 0
                echo "❌ Could not read the global package list — aborting, manifest untouched."
                return 1
            end

            printf '%s\n' $header >$manifest
            printf '%s\n' $packages >>$manifest
            echo "📝 Wrote "(count $packages)" packages to $manifest"

        case install sync
            if not test -e $manifest
                echo "❌ No manifest at $manifest — run `stow npm` in ~/dotfiles first."
                return 1
            end

            set -l packages
            for line in (cat $manifest)
                set -l pkg (string trim -- (string replace -r '#.*$' '' -- $line))
                test -n "$pkg"; and set -a packages $pkg
            end

            if test (count $packages) -eq 0
                echo "ℹ️  Manifest is empty — nothing to install."
                return 0
            end

            echo "📦 Installing "(count $packages)" global packages into "(node -v)"..."
            npm install -g $packages

        case '*'
            echo "usage: npm-globals [install|dump]"
            return 1
    end
end
