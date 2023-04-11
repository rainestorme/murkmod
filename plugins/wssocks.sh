#!/bin/bash
PLUGIN_NAME="wssocks"
PLUGIN_FUNCTION="Manage proxy connections"
PLUGIN_DESCRIPTION="Allows you to connect to and use wssocks proxies - socks5 over websockets instead of traditional socks5 TCP connections (which could be blocked)"
PLUGIN_AUTHOR="genshen, rainestorme"
PLUGIN_VERSION=1

doas() {
    ssh -t -p 1337 -i /rootkey -oStrictHostKeyChecking=no root@127.0.0.1 "$@"
}

echo "This plugin is a work-in-progress - by which I mean that it does not work. Don't use this in production."

pushd /tmp
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
    curl -LOk https://github.com/genshen/wssocks/releases/download/v0.5.0/$filename
    chmod +x $filename
    echo 'Done!'
    clear
    ./$filename version
    popd
    exit"
popd
