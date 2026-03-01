function generate-completions --description "Generate and save completions for lazy-loading"
    # 1. Ensure the user passed arguments
    if test (count $argv) -eq 0
	set_color red
	echo "❌ Usage: generate-completions <cli-command> [args...]"
	set_color normal
	echo "💡 Example: generate-completions gh completion -s fish"
	echo "💡 Example: generate-completions symfony completion fish"
	return 1
    end

    # 2. Extract the app name (the first word) for the filename
    set -l app_name $argv[1]
    set -l dest_dir "$HOME/dotfiles/fish/.config/fish/completions"
    set -l comp_file "$dest_dir/$app_name.fish"

    # 3. Ensure the destination directory exists
    command mkdir -p $dest_dir

    # 4. Execute the command and write directly to the file
    echo "⏳ Generating completion for '$app_name'..."

    if $argv >$comp_file
	set_color green
	echo "✅ Saved lazy-loaded completion to:"
	set_color normal
	echo "   $comp_file"
    else
	# If the command fails (e.g., typo), delete the empty file and warn the user
	set_color red
	echo "❌ Command failed: $argv"
	set_color normal
	command rm -f $comp_file
	return 1
    end
end
