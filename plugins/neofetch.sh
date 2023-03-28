#!/bin/bash
PLUGIN_NAME="Neofetch"
PLUGIN_FUNCTION="Run Neofetch"
PLUGIN_DESCRIPTION="Originally built-in to murkmod, now a plugin. Take screenshots on your Chromebook in style!"
PLUGIN_AUTHOR="rainestorme"
PLUGIN_VERSION=1

curl https://raw.githubusercontent.com/dylanaraps/neofetch/master/neofetch | bash
