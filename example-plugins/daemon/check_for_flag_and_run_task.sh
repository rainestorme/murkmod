#!/bin/bash
# daemon_plugin
PLUGIN_NAME="Example Daemon Plugin"
PLUGIN_FUNCTION="" # PLUGIN_FUNCTION can be left empty in daemon plugins
PLUGIN_DESCRIPTION="Checks for the existience of a flag in the user's Downloads folder and runs a script if it's found."
PLUGIN_AUTHOR="rainestorme"
PLUGIN_VERSION=1

if test -d "/home/chronos/user/Downloads/do-something-cool"; then
    echo "*insert something cool here*"
    rm -Rf /home/chronos/user/Downloads/do-something-cool
fi

sleep 1 # Always make sure to delay at the end of a daemon plugin, it's run in an infinite loop.
