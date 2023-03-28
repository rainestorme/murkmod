#!/bin/bash
PLUGIN_NAME="MrChromebox Firmware Utility Script"
PLUGIN_FUNCTION="Runs MrChromebox's firmware utility script."
PLUGIN_DESCRIPTION="Runs MrChromebox's firmware utility script."
PLUGIN_AUTHOR="MrChromebox, DiffuseHyperion"
PLUGIN_VERSION=1

doas() {
    ssh -t -p 1337 -i /rootkey -oStrictHostKeyChecking=no root@127.0.0.1 "$@"
}

cd; curl -LOk mrchromebox.tech/firmware-util.sh && doas bash firmware-util.sh
