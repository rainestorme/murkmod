#!/bin/bash
# menu_plugin
PLUGIN_NAME="Stateful Cleaner"
PLUGIN_FUNCTION="Clean stateful"
PLUGIN_DESCRIPTION="Cleans up unneccecary files on stateful to free up space"
PLUGIN_AUTHOR="rainestorme"
PLUGIN_VERSION=0

doas() {
    ssh -t -p 1337 -i /rootkey -oStrictHostKeyChecking=no root@127.0.0.1 "$@"
}

doas "rm -Rf /mnt/stateful_partition/cros_sign_backups
rm -Rf /mnt/stateful_partition/unencrypted/apkcache/*
rm -Rf /mnt/stateful_partition/unencrypted/cache/vpd/*
rm -f /mnt/stateful_partition/murkmod/kern_backup.img
rm -f /mnt/stateful_partition/murkmod/root_backup.img"