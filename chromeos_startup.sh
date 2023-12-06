#!/bin/bash

exec >/fakemurk_startup_log
exec 2>/fakemurk_startup_err
chmod 644 /fakemurk_startup_log /fakemurk_startup_err

run_plugin() {
    bash "$1"
}

runjob() {
    clear
    trap 'kill -2 $! >/dev/null 2>&1' INT
    (
        # shellcheck disable=SC2068
        $@
    )
    trap '' INT
    clear
}

. /usr/share/misc/chromeos-common.sh
DST=/dev/$(get_largest_nvme_namespace)
if [ -z $DST ]; then
    DST=/dev/mmcblk0
fi

# we stage sshd and mkfs as a one time operation in startup instead of in the bootstrap script
# this is because ssh-keygen was introduced somewhere around R80, where many shims are still stuck on R73
# filesystem unfuck can only be done before stateful is mounted, which is perfectly fine in a shim but not if you run it while booted
# because mkfs is mean and refuses to let us format

# note that this will lead to confusing behaviour, since it will appear as if it crashed as a result of fakemurk

# startup plugins are also launched here, for low-level control over 

# funny boot messages
echo "Oh fuck - ChromeOS is trying to kill itself." >/usr/share/chromeos-assets/text/boot_messages/en/block_devmode_virtual.txt
echo "ChromeOS detected developer mode and is trying to disable it to" >>/usr/share/chromeos-assets/text/boot_messages/en/block_devmode_virtual.txt
echo "comply with FWMP. This is most likely a bug and should be reported to" >>/usr/share/chromeos-assets/text/boot_messages/en/block_devmode_virtual.txt
echo "the murkmod GitHub issues page." >>/usr/share/chromeos-assets/text/boot_messages/en/block_devmode_virtual.txt

echo "i sure hope you did that on purpose (powerwashing system)" >/usr/share/chromeos-assets/text/boot_messages/en/power_wash.txt

echo "oops UwU i did a little fucky wucky and your system is trying to repair" >/usr/share/chromeos-assets/text/boot_messages/en/self_repair.txt
echo "itself~ sorry OwO" >>/usr/share/chromeos-assets/text/boot_messages/en/self_repair.txt

if [ ! -f /sshd_staged ]; then
    # thanks rory! <3
    echo "Staging sshd..."
    mkdir -p /ssh/root
    chmod -R 777 /ssh/root

    echo "Generating ssh keypair..."
    ssh-keygen -f /ssh/root/key -N '' -t rsa >/dev/null
    cp /ssh/root/key /rootkey
    chmod 600 /ssh/root
    chmod 644 /rootkey

    echo "Creating config..."
    cat >/ssh/config <<-EOF
AuthorizedKeysFile /ssh/%u/key.pub
StrictModes no
HostKey /ssh/root/key
Port 1337
EOF

    touch /sshd_staged
    echo "Staged sshd."
fi

if [ -f /population_required ]; then
    echo "Populating crossystem..."
    /sbin/crossystem_boot_populator.sh
    echo "Done. Setting check_enrollment..."
    vpd -i RW_VPD -s check_enrollment=1
    echo "Removing flag..."
    rm -f /population_required
fi

echo "Launching sshd..."
/usr/sbin/sshd -f /ssh/config &

if [ -f /logkeys/active ]; then
    echo "Found logkeys flag, launching..."
    /usr/bin/logkeys -s -m /logkeys/keymap.map -o /mnt/stateful_partition/keylog
fi

if [ ! -f /stateful_unfucked ]; then
    echo "Unfucking stateful..."
    yes | mkfs.ext4 "${DST}p1"
    touch /stateful_unfucked
    echo "Done, rebooting..."
    reboot
else
    echo "Stateful already unfucked, doing temp stateful mount..."
    stateful_dev=${DST}p1
    first_mount_dir=$(mktemp -d)
    mount "$stateful_dev" "$first_mount_dir"
    echo "Mounted stateful on $first_mount_dir, looking for startup plugins..."

    plugin_dir="$first_mount_dir/murkmod/plugins"
    temp_dir=$(mktemp -d)

    cp -r "$plugin_dir"/* "$temp_dir"
    echo "Copied files to $temp_dir, unmounting and cleaning up..."

    umount "$stateful_dev"
    rmdir "$first_mount_dir"
    rm -rf "$temp_dir"

    echo "Finding startup plugins..."
    for file in "$temp_dir"/*.sh; do
        if grep -q "startup_plugin" "$file"; then
            echo "Starting plugin $file..."
            runjob run_plugin $file
        fi
    done

    echo "Plugins run. Waiting for boot splash to finish..."
    i=0
    while ! test -f "/bootsplash-complete"; do
        sleep 0.1
        if [ ! -f /disable-bootsplash-failsafe ]; then # allow disabling failsafe if, say, i don't know, you wanted to set the entire bee movie as your boot splash
            if [[ "$i" -gt 600 ]]; then # 1 minute failsafe
                echo "Boot splash reached 1 minute failsafe. Exiting..."
                break
            fi
        fi
        ((i++))
    done
    echo "Boot splash finished. Handing over to real startup."
    rm -f /bootsplash-complete
    exec /sbin/chromeos_startup.sh.old
fi
