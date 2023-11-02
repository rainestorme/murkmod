#!/bin/bash
# menu_plugin
PLUGIN_NAME="murkgui"
PLUGIN_FUNCTION="Start murkgui listener"
PLUGIN_DESCRIPTION="Allows graphical plugins and menus to run commands on the system"
PLUGIN_AUTHOR="rainestorme"
PLUGIN_VERSION=1

echo "Listening for commands on /home/chronos/user/Downloads/murkgui"
echo "Press Ctrl+C to exit."

mkdir -p /home/chronos/user/Downloads/murkgui
touch /home/chronos/user/Downloads/murkgui/up
touch /home/chronos/user/Downloads/murkgui/down

doas() {
    ssh -t -p 1337 -i /rootkey -oStrictHostKeyChecking=no root@127.0.0.1 "$@"
}

while true; do
    if [ -f "/home/chronos/user/Downloads/murkgui/up" ]; then
        cmd=$(cat /home/chronos/user/Downloads/murkgui/up)
        echo " " > /home/chronos/user/Downloads/murkgui/up
        read -a cmd_array <<< "$cmd"
        if [[ "${cmd_array[0]}" == "exec" ]]; then
            exec="${cmd_array[@]:1}"
            doas "$exec > /home/chronos/user/Downloads/murkgui/down"
        elif [[ "${cmd_array[0]}" == "chronos" ]]; then
            exec="${cmd_array[@]:1}"
            $exec > /home/chronos/user/Downloads/murkgui/down
        fi
    fi
    sleep 0.1
done
