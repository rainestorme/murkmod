#!/bin/bash
# menu_plugin
PLUGIN_NAME="FakeAPK"
PLUGIN_FUNCTION="Install/Uninstall FakeAPK"
PLUGIN_DESCRIPTION="Install unsigned APKs when fakemurked, easily."
PLUGIN_AUTHOR="ClockworkIndustries, rainestorme"
PLUGIN_VERSION=1

# Source project: https://github.com/ClockworkIndustries/FakeAPK

doas() {
    ssh -t -p 1337 -i /rootkey -oStrictHostKeyChecking=no root@127.0.0.1 "$@"
}

pushd /tmp
    curl -LOk https://raw.githubusercontent.com/clockworkindustries/FakeAPK/main/fakeapk.sh
    doas "pushd /tmp
    clear
    bash fakeapk.sh
    popd
    exit"
popd
