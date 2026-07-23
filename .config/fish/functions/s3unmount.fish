function s3unmount --description "Unmount an S3 bucket mounted with s3mount"
    if test (count $argv) -lt 1
	echo "Usage: s3unmount <local-folder-name>"
	return 1
    end

    set -l mount_path (realpath $argv[1] 2>/dev/null)

    if test -z "$mount_path"
	echo "s3numount: '$argv[1]' does not exist" >&2
	return 1
    end

    if not mount | grep -qF " $mount_path "
	echo "s3unmount: $mount_path is not a mountpoint" >&2
	return 1
    end

    # Try plain umount first; falls back to diskutil, which asks
    # apps holding files to release them before detaching
    if not umount $mount_path 2>/dev/null
	if not diskutil unmount $mount_path
	    echo "s3unmount: unmount failed — something still using files. Try: diskutil unmount force $mount_path" >&2
	    return 1
	end
    end

    # Remove the leftover empty dir so the folder doesn't look mountable
    rmdir $mount_path 2>/dev/null
    echo "Unmounted '$mount_path'"
end
