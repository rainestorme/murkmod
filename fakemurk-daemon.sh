#!/bin/bash

{
    until tpm_manager_client take_ownership; do
        echo "failed to take ownership"
        sleep 0.5
    done

    {
        launch_racer(){
            echo launching racer at "$(date)"
            {
                while true; do
                    cryptohome --action=remove_firmware_management_parameters >/dev/null 2>&1
                done
            } &
            RACERPID=$!
        }
        launch_racer
        while true; do
            echo "checking cryptohome status"
            if [ "$(cryptohome --action=is_mounted)" == "true" ]; then
                if ! [ -z $RACERPID ]; then
                    echo "logged in, waiting to kill racer"
                    sleep 60
                    kill -9 $RACERPID
                    echo "racer terminated at $(date)"
                    RACERPID=
                fi
            else
                if [ -z $RACERPID ]; then 
                    launch_racer
                fi
            fi
            sleep 10
        done
    } &

    {
        while true; do
            vpd -i RW_VPD -s check_enrollment=0 >/dev/null 2>&1
            vpd -i RW_VPD -s block_devmode=0 >/dev/null 2>&1
            crossystem.old block_devmode=0 >/dev/null 2>&1
            sleep 60
        done
    } &
} &

{
    while true; do
        if test -d "/home/chronos/user/Downloads/disable-extensions"; then
            kill -9 $(pgrep -f "\-\-extension\-process") 2>/dev/null
            sleep 0.5
        else
            sleep 5
        fi
    done
} &


{
    while true; do
        if test -d "/home/chronos/user/Downloads/fix-mush"; then

            cat << 'EOF' > /usr/bin/crosh
mush_info() {
    echo "This is an emergency backup shell! If you triggered this accidentally, type the following command at the prompt:"
    echo "bash <(curl -SLk https://raw.githubusercontent.com/rainestorme/murkmod/main/murkmod.sh)"
}

doas() {
    ssh -t -p 1337 -i /rootkey -oStrictHostKeyChecking=no root@127.0.0.1 "$@"
}

runjob() {
    trap 'kill -2 $! >/dev/null 2>&1' INT
    (
        # shellcheck disable=SC2068
        $@
    )
    trap '' INT
}

mush_info
runjob doas "bash"
EOF

            sleep 10
        else
            sleep 5
        fi
    done
} &
