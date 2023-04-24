#!/bin/bash
# menu_plugin
PLUGIN_NAME="MAC Address Randomizer"
PLUGIN_FUNCTION="Randomize MAC Address"
PLUGIN_DESCRIPTION="Randomize your device's MAC address"
PLUGIN_AUTHOR="BinBashBanana, rainestorme"
PLUGIN_VERSION=1

doas() {
    ssh -t -p 1337 -i /rootkey -oStrictHostKeyChecking=no root@127.0.0.1 "$@"
}

pushd /tmp
    curl -LOk https://raw.githubusercontent.com/MercuryWorkshop/mac-address-randomizer/main/mac-address-randomizer.sh
    doas "pushd /tmp
    clear
    bash mac-address-randomizer.sh
    clear
    popd
    exit"
popd
