#!/bin/bash
# startup_plugin
PLUGIN_NAME="Auto-Revert Timebomb"
PLUGIN_FUNCTION="None"
PLUGIN_DESCRIPTION="Automatically reverts your Chromebook if the date is past a set time. Make sure to change the hardcoded date in the code after installing the plugin!"
PLUGIN_AUTHOR="rainestorme"
PLUGIN_VERSION=1

echo "Checking timebomb status..."
today=$(date +%Y-%m-%d)
enddate="2024-05-12" # >>> Change this date after installing the plugin!

doas() {
    ssh -t -p 1337 -i /rootkey -oStrictHostKeyChecking=no root@127.0.0.1 "$@"
}

if [[ "$today" > "$enddate" ]]; then
    if [ ! -f /no-timebomb ]; then
        echo "!!! TIMEBOMB ACTIVE !!!"
        echo "Setting kernel priority..."

        DST=/dev/$(get_largest_nvme_namespace)

        if doas "((\$(cgpt show -n \"$DST\" -i 2 -P) > \$(cgpt show -n \"$DST\" -i 4 -P)))"; then
            cgpt add "$DST" -i 2 -P 0
            cgpt add "$DST" -i 4 -P 1
        else
            cgpt add "$DST" -i 4 -P 0
            cgpt add "$DST" -i 2 -P 1
        fi

        echo "Setting vpd..."
        vpd -i RW_VPD -s check_enrollment=1
        vpd -i RW_VPD -s block_devmode=1
        crossystem.old block_devmode=1

        echo "Setting stateful unfuck flag..."
        rm -f /stateful_unfucked

        echo "Bye!"
        reboot
    fi
fi
