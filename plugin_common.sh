#!/bin/bash

STACK_ENABLED="0"
STACK_NAME=""

mkdir -p /mnt/stateful_partition/murkmod/stacks

starts() {
    touch /mnt/stateful_partition/murkmod/stacks/$1
    STACK_NAME="$1"
    STACK_ENABLED="1"
}

pushs() {
    if [ "$STACK_ENABLED" != "0" ]; then
        echo "$1" >> "/mnt/stateful_partition/murkmod/stacks/$STACK_NAME"
    else
        >&2 echo "The stack is not enabled for this plugin! To enable it, choose a name and run 'starts <name>' at the beginning of your plugin's script."
    fi 
}

pops() {
    if [ "$STACK_ENABLED" != "0" ]; then
        echo $(head -n 1 "/mnt/stateful_partition/murkmod/stacks/$STACK_NAME")
        sed -i 1d "/mnt/stateful_partition/murkmod/stacks/$STACK_NAME" # delete first line
    else
        >&2 echo "The stack is not enabled for this plugin! To enable it, choose a name and run 'starts <name>' at the beginning of your plugin's script."
    fi 
}