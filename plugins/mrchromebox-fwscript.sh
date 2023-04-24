#!/bin/bash
# menu_plugin
PLUGIN_NAME="MrChromebox Firmware Utility Script"
PLUGIN_FUNCTION="Run MrChromebox's firmware utility script"
PLUGIN_DESCRIPTION="Runs MrChromebox's firmware utility script."
PLUGIN_AUTHOR="MrChromebox, DiffuseHyperion"
PLUGIN_VERSION=2

doas() {
    ssh -t -p 1337 -i /rootkey -oStrictHostKeyChecking=no root@127.0.0.1 "$@"
}

pushd /tmp
    curl -LOk mrchromebox.tech/firmware-util.sh
    doas "pushd /tmp
    bash firmware-util.sh
    popd
    exit"
popd
