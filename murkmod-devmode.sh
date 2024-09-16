#!/bin/bash

CURRENT_MAJOR=6
CURRENT_MINOR=1
CURRENT_VERSION=1
show_logo() {
    clear
    echo -e "                      __                      .___\n  _____  __ _________|  | __ _____   ____   __| _/\n /     \|  |  \_  __ \  |/ //     \ /  _ \ / __ | \n|  Y Y  \  |  /|  | \/    <|  Y Y  (  <_> ) /_/ | \n|__|_|  /____/ |__|  |__|_ \__|_|  /\____/\____ | \n      \/                  \/     \/            \/\n"
    echo "The fakemurk plugin manager - v$CURRENT_MAJOR.$CURRENT_MINOR.$CURRENT_VERSION - Developer mode installer"
}

lsbval() {
  local key="$1"
  local lsbfile="${2:-/etc/lsb-release}"

  if ! echo "${key}" | grep -Eq '^[a-zA-Z0-9_]+$'; then
    return 1
  fi

  sed -E -n -e \
    "/^[[:space:]]*${key}[[:space:]]*=/{
      s:^[^=]+=[[:space:]]*::
      s:[[:space:]]+$::
      p
    }" "${lsbfile}"
}

get_asset() {
    curl -s -f "https://api.github.com/repos/rainestorme/murkmod/contents/$1" | jq -r ".content" | base64 -d
}

install() {
    TMP=$(mktemp)
    get_asset "$1" >"$TMP"
    if [ "$?" == "1" ] || ! grep -q '[^[:space:]]' "$TMP"; then
        echo "Failed to install $1 to $2"
        rm -f "$TMP"
        exit
    fi
    # Don't mv, that would break permissions
    cat "$TMP" >"$2"
    rm -f "$TMP"
}

get_largest_cros_blockdev() {
    local largest size dev_name tmp_size remo
    size=0
    for blockdev in /sys/block/*; do
        dev_name="${blockdev##*/}"
        echo "$dev_name" | grep -q '^\(loop\|ram\)' && continue
        tmp_size=$(cat "$blockdev"/size)
        remo=$(cat "$blockdev"/removable)
        if [ "$tmp_size" -gt "$size" ] && [ "${remo:-0}" -eq 0 ]; then
            case "$(sfdisk -l -o name "/dev/$dev_name" 2>/dev/null)" in
                *STATE*KERN-A*ROOT-A*KERN-B*ROOT-B*)
                    largest="/dev/$dev_name"
                    size="$tmp_size"
                    ;;
            esac
        fi
    done
    echo "$largest"
}

get_booted_kernnum() {
    if (($(cgpt show -n "$dst" -i 2 -P) > $(cgpt show -n "$dst" -i 4 -P))); then
        echo -n 2
    else
        echo -n 4
    fi
}

opposite_num() {
    if [ "$1" == "2" ]; then
        echo -n 4
    elif [ "$1" == "4" ]; then
        echo -n 2
    elif [ "$1" == "3" ]; then
        echo -n 5
    elif [ "$1" == "5" ]; then
        echo -n 3
    else
        return 1
    fi
}

defog() {
    futility gbb --set --flash --flags=0x8091 || true # we use futility here instead of the commented out command below because we expect newer chromeos versions and don't want to wait 30 seconds
    # /usr/share/vboot/bin/set_gbb_flags.sh 0x8091
    crossystem block_devmode=0 || true
    vpd -i RW_VPD -s block_devmode=0 || true
    vpd -i RW_VPD -s check_enrollment=1 || true
}


murkmod() {
    show_logo
    if [ -f /sbin/fakemurk-daemon.sh ]; then
        echo "!!! Your system already has a fakemurk installation! Continuing anyway, but emergency revert will not work correctly. !!!"
        echo "Instead, consider upgrading your fakemurk installation to murkmod or reinstalling CrOS from scratch."
    fi
    if [ -f /sbin/murkmod-daemon.sh ]; then
        echo "!!! Your system already has a murkmod installation! Continuing anyway, but emergency revert will not work correctly. !!!"
    fi
    echo "What version of murkmod do you want to install?"
    echo "If you're not sure, choose pheonix (v118) or the latest version. If you know what your original enterprise version was, specify that manually."
    echo " 1) og      (chromeOS v105)"
    echo " 2) mercury (chromeOS v107)"
    echo " 3) john    (chromeOS v117)"
    echo " 4) pheonix (chromeOS v118)"
    echo " 5) latest version"
    echo " 6) custom milestone"
    read -p "(1-6) > " choice

    case $choice in
        1) VERSION="105" ;;
        2) VERSION="107" ;;
        3) VERSION="117" ;;
        4) VERSION="118" ;;
        5) VERSION="latest" ;;
        6) read -p "Enter milestone to target (e.g. 105, 107, 117, 118): " VERSION ;;
        *) echo "Invalid choice, exiting." && exit ;;
    esac
    show_logo
    read -p "Do you want to use the default ChromeOS bootsplash? [y/N] " use_orig_bootsplash
    case "$use_orig_bootsplash" in
        [yY][eE][sS]|[yY]) 
            USE_ORIG_SPLASH="1"
            ;;
        *)
            USE_ORIG_SPLASH="0"
            ;;
    esac
    show_logo
    echo "Finding recovery image..."
    local release_board=$(lsbval CHROMEOS_RELEASE_BOARD)
    #local release_board="hatch"
    local board=${release_board%%-*}
    if [ $VERSION == "latest" ]; then
        local builds=$(curl -ks "https://chromiumdash.appspot.com/cros/fetch_serving_builds?deviceCategory=Chrome%20OS\\")
        local hwid=$(jq "(.builds.$board[] | keys)[0]" <<<"$builds")
        local hwid=${hwid:1:-1}
        local milestones=$(jq ".builds.$board[].$hwid.pushRecoveries | keys | .[]" <<<"$builds")
        local VERSION=$(echo "$milestones" | tail -n 1 | tr -d '"')
        echo "Latest version is $VERSION"
    fi
    local url="https://raw.githubusercontent.com/rainestorme/chrome100-json/main/boards/$board.json"
    local json=$(curl -ks "$url")
    chrome_versions=$(echo "$json" | jq -r '.pageProps.images[].chrome')
    echo "Found $(echo "$chrome_versions" | wc -l) versions of chromeOS for your board on chrome100."
    echo "Searching for a match..."
    MATCH_FOUND=0
    for cros_version in $chrome_versions; do
        platform=$(echo "$json" | jq -r --arg version "$cros_version" '.pageProps.images[] | select(.chrome == $version) | .platform')
        channel=$(echo "$json" | jq -r --arg version "$cros_version" '.pageProps.images[] | select(.chrome == $version) | .channel')
        mp_token=$(echo "$json" | jq -r --arg version "$cros_version" '.pageProps.images[] | select(.chrome == $version) | .mp_token')
        mp_key=$(echo "$json" | jq -r --arg version "$cros_version" '.pageProps.images[] | select(.chrome == $version) | .mp_key')
        last_modified=$(echo "$json" | jq -r --arg version "$cros_version" '.pageProps.images[] | select(.chrome == $version) | .last_modified')
        # if $cros_version starts with $VERSION, then we have a match
        if [[ $cros_version == $VERSION* ]]; then
            echo "Found a $VERSION match on platform $platform from $last_modified."
            MATCH_FOUND=1
            #https://dl.google.com/dl/edgedl/chromeos/recovery/chromeos_15117.112.0_hatch_recovery_stable-channel_mp-v6.bin.zip
            FINAL_URL="https://dl.google.com/dl/edgedl/chromeos/recovery/chromeos_${platform}_${board}_recovery_${channel}_${mp_token}-v${mp_key}.bin.zip"
            break
        fi
    done
    if [ $MATCH_FOUND -eq 0 ]; then
        echo "No match found on chrome100. Falling back to Chromium Dash."
        local builds=$(curl -ks "https://chromiumdash.appspot.com/cros/fetch_serving_builds?deviceCategory=Chrome%20OS\\")
        local hwid=$(jq "(.builds.$board[] | keys)[0]" <<<"$builds")
        local hwid=${hwid:1:-1}

        # Get all milestones for the specified hwid
        milestones=$(jq ".builds.$board[].$hwid.pushRecoveries | keys | .[]" <<<"$builds")

        # Loop through all milestones
        echo "Searching for a match..."
        for milestone in $milestones; do
            milestone=$(echo "$milestone" | tr -d '"')
            if [[ $milestone == $VERSION* ]]; then
                MATCH_FOUND=1
                FINAL_URL=$(jq -r ".builds.$board[].$hwid.pushRecoveries[\"$milestone\"]" <<<"$builds")
                echo "Found a match!"
                break
            fi
        done
    fi

    if [ $MATCH_FOUND -eq 0 ]; then
        echo "No recovery image found for your board and target version. Exiting."
        exit
    fi

    echo "Installing unzip (this may take up to 2 minutes)..."
    dev_install --reinstall <<EOF > /dev/null
y
n
EOF
    emerge unzip > /dev/null

    mkdir -p /usr/local/tmp
    pushd /mnt/stateful_partition
        set -e
        echo "Downloading recovery image from '$FINAL_URL'..."
        curl --progress-bar -k "$FINAL_URL" -o recovery.zip
        echo "Unzipping image... (this may take a while)"
        unzip -o recovery.zip
        rm recovery.zip
        FILENAME=$(find . -maxdepth 2 -name "chromeos_*.bin") # 2 incase the zip format changes
        echo "Found recovery image from archive at $FILENAME"
        pushd /usr/local/tmp # /usr/local is mounted as exec, so we can run scripts from here
            echo "Installing image_patcher.sh..."
            install "image_patcher.sh" ./image_patcher.sh
            chmod 777 ./image_patcher.sh
            echo "Installing ssd_util.sh..."
            mkdir -p ./lib
            install "ssd_util.sh" ./lib/ssd_util.sh
            chmod 777 ./lib/ssd_util.sh
            echo "Installing common_minimal.sh..."
            install "common_minimal.sh" ./lib/common_minimal.sh
            chmod 777 ./lib/common_minimal.sh
        popd
        echo "Invoking image_patcher.sh..."
        if [ "$USE_ORIG_SPLASH" == 0 ]; then
            bash /usr/local/tmp/image_patcher.sh "$FILENAME"
        else
            bash /usr/local/tmp/image_patcher.sh "$FILENAME" cros
        fi
        echo "Patching complete. Determining target partitions..."
        local dst=$(get_largest_cros_blockdev)
        if [[ $dst == /dev/sd* ]]; then
            echo "WARNING: get_largest_cros_blockdev returned $dst - this doesn't seem correct!"
            echo "Press enter to view output from fdisk - find the correct drive and enter it below"
            read -r
            fdisk -l | more
            echo "Enter the target drive to use:"
            read dst
        fi
        local tgt_kern=$(opposite_num $(get_booted_kernnum))
        local tgt_root=$(( $tgt_kern + 1 ))
        local kerndev=${dst}p${tgt_kern}
        local rootdev=${dst}p${tgt_root}
        echo "Targeting $kerndev and $rootdev"
        local loop=$(losetup -f | tr -d '\r')
        losetup -P "$loop" "$FILENAME"
        echo "Press enter if nothing broke, otherwise press Ctrl+C"
        read -r
        printf "Nuking partitions in 3 (this is your last chance to cancel)..."
        sleep 1
        printf "2..."
        sleep 1
        echo "1..."
        sleep 1
        echo "Bomb has been planted! Overwriting ChromeOS..."
        echo "Installing kernel patch to ${kerndev}..."
        dd if="${loop}p4" of="$kerndev" status=progress
        echo "Installing root patch to ${rootdev}..."
        dd if="${loop}p3" of="$rootdev" status=progress
        echo "Setting kernel priority..."
        cgpt add "$dst" -i 4 -P 0
        cgpt add "$dst" -i 2 -P 0
        cgpt add "$dst" -i "$tgt_kern" -P 1
        echo "Defogging... (if write-protect is disabled, this will set GBB flags to 0x8091)"
        defog
        echo "Cleaning up..."
        losetup -d "$loop"
        rm -f "$FILENAME"
    popd

    read -n 1 -s -r -p "Done! Press any key to continue and your system will reboot automatically."
    reboot
    echo "Bye!"
    sleep 10
    echo "Your system should have rebooted. If it didn't, please perform an EC reset (Refresh+Power)."
    sleep 1d
    exit
}

if [ "$0" = "$BASH_SOURCE" ]; then
    if [ "$EUID" -ne 0 ]; then
        echo "Please run as root."
        exit
    fi
    murkmod
fi
