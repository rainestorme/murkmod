#!/bin/bash
# menu_plugin
PLUGIN_NAME="wssocks"
PLUGIN_FUNCTION="Start a wssocks connection"
PLUGIN_DESCRIPTION="Allows you to connect to and use wssocks proxies - socks5 over websockets instead of traditional socks5 TCP connections (which could be blocked)"
PLUGIN_AUTHOR="genshen, rainestorme"
PLUGIN_VERSION=10

doas() {
    ssh -t -p 1337 -i /rootkey -oStrictHostKeyChecking=no root@127.0.0.1 "$@"
}

clear

echo "This plugin is a work-in-progress. Don't use this in production (or for anything critical)."
pushd /tmp
    echo "Enter the wss:// or ws:// url to a wssocks proxy, or leave this field blank to use a hosted one (on replit, check the status here: https://10cf60a3-1599-4cc6-a7b5-db06769a323e.id.repl.co/status/)"
    read -p ' > ' wssocks_host
    if [ -z "$wssocks_host" ]; then
        wssocks_host="wss://10cf60a3-1599-4cc6-a7b5-db06769a323e.id.repl.co"
    fi
    echo "Checking architecture..."
    architecture=""
    case $(uname -m) in
        x86_64) architecture="amd64" ;;
        arm)    dpkg --print-architecture | grep -q "arm64" && architecture="arm64" || architecture="arm" ;;
        *)      echo "Sorry, your architecture is not supported by wssocks."; exit ;;
    esac
    echo "Updating wssocks..."
    filename="wssocks-linux-$architecture"
    doas "pushd /root
    echo 'Cleaning up...'
    rm -f $filename
    echo 'Downloading...'
    curl -LOk https://github.com/genshen/wssocks/releases/download/v0.5.0/$filename
    echo 'Chmod-ing...'
    chmod +x $filename
    echo 'Done!'
    clear
    echo 'Version info:'
    ./$filename version
    echo 'Starting wssocks client...'
    ./$filename client --addr :1080 --remote $wssocks_host --http
    read -p 'Press enter to exit.'
    popd
    exit"
popd
