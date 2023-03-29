#!/bin/bash
PLUGIN_NAME="BIOS Dumper"
PLUGIN_FUNCTION="Dump current BIOS"
PLUGIN_DESCRIPTION="Dumps the current system firmware/BIOS for further reverse-engineering"
PLUGIN_AUTHOR="rainestorme"
PLUGIN_VERSION=1

doas() {
    ssh -t -p 1337 -i /rootkey -oStrictHostKeyChecking=no root@127.0.0.1 "$@"
}

echo "Dumping firmware..."
doas "pushd /home/chronos/user/Downloads
clear
flashrom -r bios.bin &> /dev/null
popd
exit"
echo "Done! Look in /home/chronos/user/Downloads (just labeled 'Downloads' in the file explorer) for the .bin file."
sleep 1
