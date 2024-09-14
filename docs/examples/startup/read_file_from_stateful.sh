#!/bin/bash
# startup_plugin
PLUGIN_NAME="Example Startup Plugin"
PLUGIN_FUNCTION="" # PLUGIN_FUNCTION can be left empty for a startup plugin
PLUGIN_DESCRIPTION="Reads a value from stateful, then exits."
PLUGIN_AUTHOR="rainestorme"
PLUGIN_VERSION=1

# Find stateful
. /usr/share/misc/chromeos-common.sh
DST=/dev/$(get_largest_nvme_namespace) # TODO: replace with get_largest_cros_blockdev
if [ -z $DST ]; then
    DST=/dev/mmcblk0
fi

# Now that we know where stateful is on the drive, we have to mount it
stateful_dev=${DST}p1
mount_dir=$(mktemp -d)
mount "$stateful_dev" "$mount_dir"
echo "Mounted stateful on $mount_dir, reading value..."

echo "You're using murkmod version: $(cat /mnt/stateful_partition/murkmod_version)" # note that although we can access unencrypted files here, we cannot modify user data without booting into the system fully and letting chromeos handle authentication

# Unmount
umount "$stateful_dev"
rm -Rf "$mount_dir"
