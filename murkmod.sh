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
        return 1
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
    install "mush.sh" /usr/bin/crosh
    install "fakemurk-daemon.sh" /sbin/fakemurk-daemon.sh
}

create_stateful_files() {
    mkdir -p /mnt/stateful_partition/murkmod/plugins
}

murkmod() {
    show_logo
    if [ ! -f /sbin/fakemurk-daemon.sh ] then
        echo "Either your system has a broken fakemurk installation or your system doesn't have a fakemurk installation at all. (Re)install fakemurk, then re-run this script."
        exit
    fi
    echo "Installing patched files..."
    install_patched_files
    echo "Creating stateful partition files..."
    create_stateful_files
    read -n 1 -s -r -p "Press any key to reboot."
    reboot
}

if [ "$0" = "$BASH_SOURCE" ]; then
    if [ "$EUID" -ne 0 ] then
        echo "Please run this as root from mush. Use option 1 (root shell) instead of any other method of getting to a shell."
        exit
    fi
    murkmod
fi
