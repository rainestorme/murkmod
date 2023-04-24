#!/bin/bash
# menu_plugin
PLUGIN_NAME="Neofetch"
PLUGIN_FUNCTION="Run Neofetch"
PLUGIN_DESCRIPTION="Originally built-in to murkmod, now a plugin. Take screenshots on your Chromebook in style!"
PLUGIN_AUTHOR="rainestorme"
PLUGIN_VERSION=2

curl https://raw.githubusercontent.com/dylanaraps/neofetch/master/neofetch | bash

read -n 1 -s -r -p "Press any key to continue"
