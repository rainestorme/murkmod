#!/bin/bash

# crossystem.sh v3.0.0
# made by r58Playz and stackoverflow
# emulates crossystem but with static values to trick chromeos and google
# version history:
# v3.0.0 - implemented mutable crossystem values
# v2.0.0 - implemented all functionality
# v1.1.1 - hotfix for stupid crossystem
# v1.1.0 - implemented <var>?<value> functionality (searches for value in var)
# v1.0.0 - basic functionality implemented

# script gutted by rainestorme for murkmod

. /usr/share/misc/chromeos-common.sh || :

csys() {
    if [ "$COMPAT" == "1" ]; then
        crossystem "$@"
    elif test -f "$ROOT/usr/bin/crossystem.old"; then
        "$ROOT/usr/bin/crossystem.old" "$@"
    else
        "$ROOT/usr/bin/crossystem" "$@"
    fi
}

sed_escape() {
    echo -n "$1" | while read -n1 ch; do
        if [[ "$ch" == "" ]]; then
            echo -n "\n"
            # dumbass shellcheck not expanding is the entire point
        fi
        echo -n "\\x$(printf %x \'"$ch")"
    done
}

# the only reason this blob is still here is because i don't want to add network dependency for a boot-time script
raw_crossystem_sh() {
    base64 -d <<-EOF | bunzip2 -dc
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
bzVPfi2mxFTkn/F3JFOFCQFdrstw
EOF
}


drop_crossystem_sh() {
    # this weird space replacement is used because "read" has odd behaviour with spaces and newlines
    # i don't need to worry about the jank because crossystem will never have user controlled data
    vals=$(sed "s/ /THIS_IS_A_SPACE_DUMBASS/g" <<<"$(crossystem_values)")
    raw_crossystem_sh | sed -e "s/#__SED_REPLACEME_CROSSYSTEM_VALUES#/$(sed_escape "$vals")/g" | sed -e "s/THIS_IS_A_SPACE_DUMBASS/ /g" >"$ROOT/usr/bin/crossystem"
    chmod 777 "$ROOT/usr/bin/crossystem"
}

escape() {
    case $1 in
    '' | *[!0-9]*) echo -n "\"$1\"" ;;
    *) echo -n "$1" ;;
    esac
}

crossystem_values() {
    readarray -t csys_lines <<<"$(csys)"
    for element in "${csys_lines[@]}"; do
        line_stripped=$(echo "$element" | sed -e "s/#.*//g" | sed -e 's/ .*=/=/g')
        # sed 1: cuts out all chars after the #
        # sed 2: cuts out all spaces before =
        IFS='=' read -r -a pair <<<"$line_stripped"

        key=${pair[0]}
        # cut out all characters after an instance of 2 spaces in a row
        val="$(echo ${pair[1]} | sed -e 's/  .*//g')"
        if [ "$key" == "devsw_cur" ]; then
            val=0
        fi
        if [ "$key" == "devsw_boot" ]; then
            val=0
        fi
        if [ "$key" == "mainfw_type" ]; then
            val="normal"
        fi
        if [ "$key" == "mainfw_act" ]; then
            val="A"
        fi
        if [ "$key" == "cros_debug" ]; then
            val=1
        fi
        if [ "$key" == "dev_boot_legacy" ]; then
            val=0
        fi
        if [ "$key" == "dev_boot_signed_only" ]; then
            val=0
        fi
        if [ "$key" == "dev_boot_usb" ]; then
            val=0
        fi
        if [ "$key" == "dev_default_boot" ]; then
            val="disk"
        fi
        if [ "$key" == "dev_enable_udc" ]; then
            val=0
        fi
        if [ "$key" == "alt_os_enabled" ]; then
            val=0
        fi
        if [ "$key" == "recoverysw_boot" ]; then
            val=0
        fi
        if [ "$key" == "recoverysw_cur" ]; then
            val=0
        fi
        echo "$key=$(escape "$val")"
    done
}

mv "$ROOT/usr/bin/crossystem" "$ROOT/usr/bin/crossystem.old"
drop_crossystem_sh
