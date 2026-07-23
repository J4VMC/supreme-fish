function s3mount --description "Mount an S3 bucket for the current active client profile"
    if test (count $argv) -lt 1
	echo "Usage: s3mount <bucket-name> [local-folder-name]"
	return 1
    end

    if not command -q rclone-mac
	echo "s3mount: rclone-mac not found in PATH" >&2
	return 127
    end

    set -l bucket $argv[1]
    set -l target_dir $argv[2]
    test -z "$target_dir"; and set target_dir $bucket

    set -l profile default
    set -q AWS_PROFILE; and set profile $AWS_PROFILE

    set -l mount_path (pwd)/$target_dir

    if mount | grep -q " $mount_path "
	echo "s3mount: $mount_path already mounted" >&2
	return 1
    end

    mkdir -p $mount_path

    rclone-mac mount :s3:$bucket $mount_path \
	--s3-provider AWS \
	--s3-env-auth true \
	--s3-profile $profile \
	--vfs-cache-mode full \
	--vfs-write-back 5s \
	--daemon

    if test $status -ne 0
	echo "s3mount: mount failed for '$bucket' (profile '$profile')" >&2
	rmdir $mount_path 2>/dev/null
	return 1
    end

    echo "Mounted '$bucket' using profile '$profile' at '$mount_path'"
end
