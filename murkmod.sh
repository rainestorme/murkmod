#!/bin/bash

CURRENT_MAJOR=0
CURRENT_MINOR=3
CURRENT_VERSION=2

get_asset() {
    curl -s -f "https://api.github.com/repos/rainestorme/murkmod/contents/$1" | jq -r ".content" | base64 -d
}

get_asset_fakemurk() {
    curl -s -f "https://api.github.com/repos/MercuryWorkshop/fakemurk/contents/$1" | jq -r ".content" | base64 -d
}

get_built_asset_fakemurk() {
    curl -SLk "https://github.com/MercuryWorkshop/fakemurk/releases/latest/download/$1"
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

install_fakemurk() {
    TMP=$(mktemp)
    get_asset_fakemurk "$1" >"$TMP"
    if [ "$?" == "1" ] || ! grep -q '[^[:space:]]' "$TMP"; then
        echo "Failed to install $1 to $2"
        rm -f "$TMP"
        exit
    fi
    # Don't mv, that would break permissions
    cat "$TMP" >"$2"
    rm -f "$TMP"
}

install_built_fakemurk() {
    TMP=$(mktemp)
    get_built_asset_fakemurk "$1" >"$TMP"
    if [ "$?" == "1" ] || ! grep -q '[^[:space:]]' "$TMP"; then
        echo "failed to install $1 to $2"
        rm -f "$TMP"
        return 1
    fi
    cat "$TMP" >"$2"
    rm -f "$TMP"
}

show_logo() {
    echo -e "                      __                      .___\n  _____  __ _________|  | __ _____   ____   __| _/\n /     \|  |  \_  __ \  |/ //     \ /  _ \ / __ | \n|  Y Y  \  |  /|  | \/    <|  Y Y  (  <_> ) /_/ | \n|__|_|  /____/ |__|  |__|_ \__|_|  /\____/\____ | \n      \/                  \/     \/            \/\n"
    echo "        The fakemurk plugin manager - v$CURRENT_MAJOR.$CURRENT_MINOR.$CURRENT_VERSION"
}


install_patched_files() {
    install "fakemurk-daemon.sh" /sbin/fakemurk-daemon.sh
    install "chromeos_startup.sh" /sbin/chromeos_startup.sh
    install "mush.sh" /usr/bin/crosh
    install "pre-startup.conf" /etc/init/pre-startup.conf
    install "cr50-update.conf" /etc/init/cr50-update.conf
    install "ssd_util.sh" /usr/share/vboot/bin/ssd_util.sh
    install_built_fakemurk "image_patcher.sh" /sbin/image_patcher.sh
    chmod 777 /sbin/fakemurk-daemon.sh /sbin/chromeos_startup.sh /usr/bin/crosh /usr/share/vboot/bin/ssd_util.sh /sbin/image_patcher.sh
}

create_stateful_files() {
    # This is only here for backwards compatibility
    touch /mnt/stateful_partition/murkmod_version
    echo "$CURRENT_MAJOR $CURRENT_MINOR $CURRENT_VERSION" > /mnt/stateful_partition/murkmod_version
    
    mkdir -p /mnt/stateful_partition/murkmod/plugins
    touch /mnt/stateful_partition/murkmod/settings
    if [ ! -f /mnt/stateful_partition/murkmod/settings ]; then
        echo "# ----- murkmod settings -----" > /mnt/stateful_partition/murkmod/settings
        echo "" >> /mnt/stateful_partition/murkmod/settings
        echo "# Whether or not to show experimental features" >> /mnt/stateful_partition/murkmod/settings
        echo "show_experimental=false" >> /mnt/stateful_partition/murkmod/settings
    fi
}

check_for_emergencyshell() {
    if test -d "/home/chronos/user/Downloads/fix-mush"; then
        echo "Running from emergency shell, reverting..."
        rm -Rf /home/chronos/user/Downloads/fix-mush
    fi
}

do_policy_patch() {
    url1="https://raw.githubusercontent.com/rainestorme/murkmod/main/pollen.json"
    url2="https://raw.githubusercontent.com/MercuryWorkshop/fakemurk/main/pollen.json"
    response1=$(curl -s "$url1")
    response2=$(curl -s "$url2")

    if [ "$response1" = "$response2" ]; then
        install "pollen.json" /etc/opt/chrome/policies/managed/policy.json
    else
        read -r -p "Use murkmod reccomended pollen config? [Y/n] " choice
        case "$choice" in
            n | N) install_fakemurk "pollen.json" /etc/opt/chrome/policies/managed/policy.json ;;
            *) install "pollen.json" /etc/opt/chrome/policies/managed/policy.json ;;
        esac
    fi
}

set_chronos_password() {
    echo -en "murkmod\nmurkmod\n" | passwd chronos
}

set_sudo_perms() {
    if ! cat /etc/sudoers | grep chronos; then
        echo "Sudo permissions are not already set, setting..."
        echo "chronos ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers 
    else
        echo "Looks like sudo permissions are already set correctly."
    fi
}

murkmod() {
    show_logo
    if [ ! -f /sbin/fakemurk-daemon.sh ]; then
        echo "Either your system has a broken fakemurk installation or your system doesn't have a fakemurk installation at all. (Re)install fakemurk, then re-run this script."
        exit
    fi
    echo "Checking for emergency shell..."
    check_for_emergencyshell
    echo "Installing patched files..."
    install_patched_files
    echo "Creating stateful partition files..."
    create_stateful_files
    echo "Patching policy..."
    do_policy_patch
    echo "Setting chronos user password..."
    set_chronos_password
    echo "Checking sudo perms..."
    set_sudo_perms
    read -n 1 -s -r -p "Done. Press any key to exit."
    exit
}

if [ "$0" = "$BASH_SOURCE" ]; then
    if [ "$EUID" -ne 0 ]; then
        echo "Please run this as root from mush. Use option 1 (root shell) instead of any other method of getting to a shell."
        exit
    fi
    murkmod
fi
