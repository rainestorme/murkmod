#!/bin/bash
# menu_plugin
PLUGIN_NAME="GBB Tools"
PLUGIN_FUNCTION="Open GBB tools"
PLUGIN_DESCRIPTION="Allows you to view, edit, and remove GBB (Google Binary Block) flags on the system easily"
PLUGIN_AUTHOR="kubisnax, rainestorme"
PLUGIN_VERSION=2

doas() {
    ssh -t -p 1337 -i /rootkey -oStrictHostKeyChecking=no root@127.0.0.1 "$@"
}

pushd /tmp
    curl -LOk https://raw.githubusercontent.com/kubisnax/gbb_tools/master/gbbtools.sh
    doas "pushd /tmp
    clear
    bash gbbtools.sh
    popd
    exit"
popd
