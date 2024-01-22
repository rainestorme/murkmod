#!/bin/bash
# startup_plugin
PLUGIN_NAME="Example Startup Plugin 2"
PLUGIN_FUNCTION="" # PLUGIN_FUNCTION can be left empty for a startup plugin
PLUGIN_DESCRIPTION="creates a file"
PLUGIN_AUTHOR="rainestorme"
PLUGIN_VERSION=1

touch /test
chmod 775 /test
