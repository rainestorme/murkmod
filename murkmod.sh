#!/bin/bash

CURRENT_VERSION=1

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

show_logo() {
    echo "                          __                      .___\n  _____  __ _________\|  \| __ _____   ____   __\| _/\n /     \\\|  \|  \\_  __ \\  \|/ //     \\ /  _ \\ / __ \| \n\|  Y Y  \\  \|  /\|  \| \\/    \<\|  Y Y  \(  \<_\> \) /_/ \| \n\|__\|_\|  /____/ \|__\|  \|__\|_ \\__\|_\|  /\\____/\\____ \| \n      \\/                  \\/     \\/            \\/ "
    echo
    echo "        The fakemurk plugin manager - v0.1:1"
}

install_patched_files() {
    install "fakemurk-daemon.sh" /sbin/fakemurk-daemon.sh
    install "chromeos_startup.sh" /sbin/chromeos_startup.sh
    install "mush.sh" /usr/bin/crosh
    install "pre-startup.conf" /etc/init/pre-startup.conf
}

create_stateful_files() {
    mkdir -p /mnt/stateful_partition/murkmod/plugins
    touch /mnt/stateful_partition/murkmod_version
    echo $CURRENT_VERSION > /mnt/stateful_partition/murkmod_version  
}

check_for_murkmod() {
    if [ -f /mnt/stateful_partition/murkmod_version ]; then
        FILE_VERSION=$(cat /mnt/stateful_partition/murkmod_version)
        if [ $FILE_VERSION -ge $CURRENT_VERSION ]; then
            # Exit if the file version is greater than or equal to the current version
            echo "Nothing to do, exiting..."
            exit 0
        fi
        echo "Found pre-existing install. Will update files accordingly."
    fi
}

murkmod() {
    show_logo
    if [ ! -f /sbin/fakemurk-daemon.sh ] then
        echo "Either your system has a broken fakemurk installation or your system doesn't have a fakemurk installation at all. (Re)install fakemurk, then re-run this script."
        exit
    fi
    echo "Checking for pre-existing murkmod install..."
    check_for_murkmod
    echo "Installing patched files..."
    install_patched_files
    echo "Creating stateful partition files..."
    create_stateful_files
    read -n 1 -s -r -p "Done. Press any key to exit."
    exit
}

if [ "$0" = "$BASH_SOURCE" ]; then
    if [ "$EUID" -ne 0 ] then
        echo "Please run this as root from mush. Use option 1 (root shell) instead of any other method of getting to a shell."
        exit
    fi
    murkmod
fi
