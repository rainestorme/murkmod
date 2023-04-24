#!/bin/bash
# menu_plugin
PLUGIN_NAME="BIOS Dumper"
PLUGIN_FUNCTION="Dump BIOS/firmware"
PLUGIN_DESCRIPTION="Dumps the current system firmware/BIOS for further reverse-engineering"
PLUGIN_AUTHOR="rainestorme"
PLUGIN_VERSION=2

doas() {
    ssh -t -p 1337 -i /rootkey -oStrictHostKeyChecking=no root@127.0.0.1 "$@"
}

doas "pushd /home/chronos/user/Downloads
clear
echo 'Dumping firmware...'
flashrom -r bios.bin &> /dev/null
popd
exit"
clear
echo "Done! Look in /home/chronos/user/Downloads (just labeled 'Downloads' in the file explorer) for the .bin file."
sleep 1
