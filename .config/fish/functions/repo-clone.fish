function repo-clone --description "Clone a git repository and auto-configure hooks"
    if test (count $argv) -eq 0
	set_color red
	echo "❌ Usage: repo-clone <git-repo-url>"
	set_color normal
	return 1
    end

    set -l repo_url $argv[1]

    # 1. Clone the repository
    command git clone $repo_url
    if test $status -ne 0
	return 1
    end

    # 2. Extract the directory name from the URL and cd into it
    # e.g., https://github.com/user/repo.git -> repo
    set -l repo_dir (basename $repo_url .git)
    cd $repo_dir

    echo ""
    set_color blue --bold
    echo "🔍 Inspecting repository for hook managers..."
    set_color normal

    # 3. Intelligence: Decide what to do based on the repo's contents
    if test -f lefthook.yml; or test -f lefthook.yaml
	set_color yellow
	echo "⚠️ Found existing Lefthook configuration. Installing project hooks..."
	set_color normal
	lefthook install

    else if test -f .pre-commit-config.yaml
	set_color yellow
	echo "⚠️ Project uses 'pre-commit'. Respecting project defaults."
	echo "💡 Run 'pre-commit install' if you want to activate them."
	set_color normal

    else if test -f package.json; and grep -q '"husky"' package.json
	set_color yellow
	echo "⚠️ Project uses 'husky'. Respecting project defaults."
	echo "💡 Run 'npm install' or 'yarn' to activate them."
	set_color normal

    else
	# 4. No hook manager found. Inject our personal default!
	# NOTE: Using 'cog verify --file {1}' to safely parse Emacs/Magit commit comments
	echo "commit-msg:
  commands:
    conventional-check:
      run: cog verify --file {1}" >lefthook.yml

	set_color green
	echo "✅ No existing hooks found. Injected personal lefthook.yml."
	set_color normal

	# Verify lefthook is installed before trying to run it
	if command -v lefthook >/dev/null
	    lefthook install
	else
	    set_color red
	    echo "❌ Lefthook binary not found. Cannot install hooks."
	    set_color normal
	end
    end
end
