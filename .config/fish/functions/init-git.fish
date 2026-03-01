function init-git --description "Initialize a git repository with Lefthook & Conventional Commits"
    # 1. Initialize the git repository
    git init

    # 2. Check if lefthook is installed on the system
    if not command -v lefthook >/dev/null
	set_color red
	echo "❌ Lefthook is not installed. Run: brew install lefthook"
	set_color normal
	return 1
    end

    # 3. Create the lefthook.yml file if it doesn't already exist
    if not test -f lefthook.yml
	# NOTE: Using 'cog verify --file {1}' to safely parse Emacs/Magit commit comments
	echo "commit-msg:
  commands:
    conventional-check:
      run: cog verify --file {1}" >lefthook.yml

	set_color green
	echo "✅ Created lefthook.yml with Cocogitto (cog) template."
	set_color normal
    else
	set_color yellow
	echo "⚠️ lefthook.yml already exists. Skipping creation."
	set_color normal
    end

    # 4. Install the hooks into the local .git/hooks directory
    lefthook install

    set_color blue --bold
    echo "🎉 Repository initialized and ready for Conventional Commits!"
    set_color normal
end
