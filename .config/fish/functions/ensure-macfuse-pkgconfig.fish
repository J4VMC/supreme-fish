# ~/dotfiles/fish/.config/fish/functions/ensure-macfuse-pkgconfig.fish
#
# Formulae from the gromgit/fuse tap (sshfs-mac, rclone-mac, …) locate macFUSE
# through pkg-config. The tap's MacfuseRequirement appends
#
#     <brew repository>/Library/Homebrew/os/mac/pkgconfig/fuse
#
# to PKG_CONFIG_PATH, but Homebrew stopped shipping that directory — only the
# per-OS-version ones survive. The tap stages its own copy of the .pc files
# instead, except that path is guarded by `need_alt_fuse?`, i.e.
# HOMEBREW_PREFIX != /usr/local, so on Intel it never runs. The result is a
# source build that cannot find fuse3 even though macFUSE ships
# /usr/local/lib/pkgconfig/fuse3.pc, which is what kept `brew upgrade` failing.
#
# Exporting PKG_CONFIG_PATH from the shell does not help: Homebrew's superenv
# assigns the variable outright rather than extending it, so the tap's env block
# is the only injection point. Recreating the directory as symlinks to macFUSE's
# real .pc files restores exactly the lookup the tap expects.
#
# The directory lives inside Homebrew's own git checkout, so `brew update-reset`
# (and some `brew update` paths) will wipe it. maintain and brew_daily_update
# call this before every upgrade to put it back.

function ensure-macfuse-pkgconfig --description "Relink macFUSE's pkg-config files where the gromgit/fuse tap expects them"
    # brew_daily_update resolves brew by absolute path because it runs without an
    # interactive PATH, so accept the command it already found.
    set -l brew_cmd $argv[1]
    test -n "$brew_cmd"; or set brew_cmd brew
    type -q $brew_cmd; or return 0

    # macFUSE always installs under /usr/local, whatever the Homebrew prefix is.
    set -l src /usr/local/lib/pkgconfig
    test -d $src; or return 0

    set -l dest ($brew_cmd --repository)/Library/Homebrew/os/mac/pkgconfig/fuse
    set -l relinked

    for pc in fuse.pc fuse3.pc
        test -e $src/$pc; or continue

        set -l current (readlink $dest/$pc 2>/dev/null)
        test "$current" = "$src/$pc"; and continue

        mkdir -p $dest; or return 1
        ln -sf $src/$pc $dest/$pc; or return 1
        set -a relinked $pc
    end

    test (count $relinked) -gt 0
    and echo "   🔗 Relinked macFUSE pkg-config for the gromgit/fuse tap: $relinked"

    return 0
end
