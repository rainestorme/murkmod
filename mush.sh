#!/bin/bash

get_largest_nvme_namespace() {
    # this function doesn't exist if the version is old enough, so we redefine it
    local largest size tmp_size dev
    size=0
    dev=$(basename "$1")

    for nvme in /sys/block/"${dev%n*}"*; do
        tmp_size=$(cat "${nvme}"/size)
        if [ "${tmp_size}" -gt "${size}" ]; then
            largest="${nvme##*/}"
            size="${tmp_size}"
        fi
    done
    echo "${largest}"
}

traps() {
    set +e
    trap 'last_command=$current_command; current_command=$BASH_COMMAND' DEBUG
    trap 'echo "\"${last_command}\" command failed with exit code $?' EXIT
    trap '' INT
}

mush_info() {
    cat <<-EOF
Welcome to mush, the fakemurk developer shell.

If you got here by mistake, don't panic! Just close this tab and carry on.

This shell contains a list of utilities for performing various actions on a fakemurked chromebook.

This installation of fakemurk has been patched by murkmod. Don't report any bugs you encounter with it to the fakemurk developers.
EOF
}
doas() {
    ssh -t -p 1337 -i /rootkey -oStrictHostKeyChecking=no root@127.0.0.1 "$@"
}

runjob() {
    trap 'kill -2 $! >/dev/null 2>&1' INT
    (
        $@
    )
    trap '' INT
}

swallow_stdin() {
    while read -t 0 notused; do
        read input
    done
}

edit() {
    if which nano 2>/dev/null; then
        doas nano "$@"
    else
        doas vi "$@"
    fi
}

main() {
    traps
    mush_info
    while true; do
        cat <<-EOF
(1) Root Shell
(2) Chronos Shell
(3) Crosh
(4) Powerwash
(5) Soft Disable Extensions
(6) Hard Disable Extensions
(7) Hard Enable Extensions
(8) Emergency Revert & Re-Enroll
(9) Edit Pollen
(10) Run neofetch
(11) Install plugins
(12) Uninstall plugins
EOF
        if ! test -f /mnt/stateful_partition/crouton; then
            echo "(13) Install Crouton"
            echo "(14) Start Crouton (only run after running above)"
        fi

        # Scan the plugins directory for plugin scripts
        PLUGIN_DIR="/mnt/stateful_partition/murkmod/plugins"
        for plugin_file in $(find "$PLUGIN_DIR" -name "*.sh"); do
            source "$plugin_file"
            echo "($((++i))) ${PLUGIN_NAME} (ver: ${PLUGIN_VERSION})"
        done

        swallow_stdin
        read -r -p "> (1-$((i+11))): " choice
        case "$choice" in
        1) runjob doas bash ;;
        2) runjob bash ;;
        3) runjob /usr/bin/crosh.old ;;
        4) runjob powerwash ;;
        5) runjob softdisableext ;;
        6) runjob harddisableext ;;
        7) runjob hardenableext ;;
        8) runjob revert ;;
        9) runjob edit /etc/opt/chrome/policies/managed/policy.json ;;
        10) runjob do_neofetch ;;
        11) runjob install_plugins ;;
        12) runjob uninstall_plugins ;;
        13) runjob install_crouton ;;
        14) runjob run_crouton ;;

        # Execute the chosen plugin script
        $((i+1))|$((i+2))|...) source "$(find "$PLUGIN_DIR" -name "*.sh" | sed -n "$((choice-i-1))p")";;

        *) echo "----- Invalid option ------" ;;
        esac
    done
}

do_neofetch() {
    curl https://raw.githubusercontent.com/dylanaraps/neofetch/master/neofetch | bash
}

install_plugins() {
  local plugins_url="https://api.github.com/repos/rainestorme/murkmod/contents/plugins"
  local plugins=$(curl -s $plugins_url | jq -r '.[] | select(.type == "file") | .name')

  echo "Available plugins:"

  for plugin in $plugins; do
    local plugin_url="$plugins_url/$plugin"
    local plugin_info=$(curl -s $plugin_url)

    local plugin_name=$(echo "$plugin_info" | jq -r '.name')
    local plugin_desc=$(echo "$plugin_info" | jq -r '.description')
    local plugin_author=$(echo "$plugin_info" | jq -r '.author')

    echo "$plugin_name by $plugin_author: $plugin_desc"
    echo ""
  done

  echo "Enter the name of a plugin to install (or q to quit):"
  read -r plugin_name

  while [[ $plugin_name != "q" ]]; do
    local plugin_url="$plugins_url/$plugin_name"
    local plugin_info=$(curl -s $plugin_url)

    if [[ $plugin_info == *"Not Found"* ]]; then
      echo "Plugin not found"
    else
      local plugin_file_url=$(echo "$plugin_info" | jq -r '.download_url')
      local plugin_path="/mnt/stateful_partition/murkmod/plugins/$plugin_name"
      
      curl -s $plugin_file_url > $plugin_path
      echo "Installed $plugin_name"
    fi

    echo "Enter the name of a plugin to install (or q to quit):"
    read -r plugin_name
  done
}


uninstall_plugins() {
    clear
    
    plugins_dir="/mnt/stateful_partition/murkmod/plugins"
    plugin_files=()

    while IFS= read -r -d '' file; do
        plugin_files+=("$file")
    done < <(find "$plugins_dir" -type f -name "*.sh" -print0)

    plugin_info=()
    for file in "${plugin_files[@]}"; do
        source "$file"
        plugin_info+=("$PLUGIN_NAME (version $PLUGIN_VERSION by $PLUGIN_AUTHOR)")
    done

    if [ ${#plugin_info[@]} -eq 0 ]; then
        echo "No plugins installed. Select "
        return
    fi

    while true; do
        echo "Installed plugins:"
        for i in "${!plugin_info[@]}"; do
            echo "$(($i+1)). ${plugin_info[$i]}"
        done
        echo "0. Exit back to mush"
        read -r -p "Enter a number to uninstall a plugin, or 0 to exit: " choice

        if [ "$choice" -eq 0 ]; then
            clear
            return
        fi

        index=$(($choice-1))

        if [ "$index" -lt 0 ] || [ "$index" -ge ${#plugin_info[@]} ]; then
            echo "Invalid choice."
            continue
        fi

        plugin_file="${plugin_files[$index]}"
        source "$plugin_file"
        plugin_name="$PLUGIN_NAME (version $PLUGIN_VERSION by $PLUGIN_AUTHOR)"

        read -r -p "Are you sure you want to uninstall $plugin_name? [y/n] " confirm
        if [ "$confirm" == "y" ]; then
            rm "$plugin_file"
            echo "$plugin_name uninstalled."
            unset plugin_info[$index]
            plugin_info=("${plugin_info[@]}")
        fi
    done
}

powerwash() {
    echo "Are you sure you wanna powerwash? This will remove all user accounts and data, but won't remove fakemurk."
    sleep 2
    echo "(Press enter to continue, ctrl-c to cancel)"
    swallow_stdin
    read -r
    doas echo "fast safe" >/mnt/stateful_partition/factory_install_reset
    doas reboot
    exit
}

revert() {
    echo "This option will re-enroll your chromebook restore to before fakemurk was run. This is useful if you need to quickly go back to normal"
    echo "This is *permanent*. You will not be able to fakemurk again unless you re-run everything from the beginning."
    echo "Are you sure - 100% sure - that you want to continue? (press enter to continue, ctrl-c to cancel)"
    swallow_stdin
    read -r
    sleep 4
    echo "Setting kernel priority"

    DST=/dev/$(get_largest_nvme_namespace)

    if doas "(($(cgpt show -n "$DST" -i 2 -P) > $(cgpt show -n "$DST" -i 4 -P)))"; then
        doas cgpt add "$DST" -i 2 -P 0
        doas cgpt add "$DST" -i 4 -P 1
    else
        doas cgpt add "$DST" -i 4 -P 0
        doas cgpt add "$DST" -i 2 -P 1
    fi
    echo "Setting vpd"
    doas vpd.old -i RW_VPD -s check_enrollment=1
    doas vpd.old -i RW_VPD -s block_devmode=1
    doas crossystem.old block_devmode=1

    echo "Done. Press enter to reboot"
    swallow_stdin
    read -r
    echo "Bye!"
    sleep 2
    doas reboot
    sleep 1000
    echo "Your chromebook should have rebooted by now. If your chromebook doesn't reboot in the next couple of seconds, press Esc+Refresh to do it manually."
}
harddisableext() { # calling it "hard disable" because it only reenables when you press
    read -r -p "Enter extension ID > " extid
    chmod 000 "/home/chronos/user/Extensions/$extid"
    kill -9 $(pgrep -f "\-\-extension\-process")
}

hardenableext() {
    read -r -p "Enter extension ID > " extid
    chmod 777 "/home/chronos/user/Extensions/$extid"
    kill -9 $(pgrep -f "\-\-extension\-process")
}

softdisableext() {
    echo "Extensions will stay disabled until you press Ctrl+c or close this tab"
    while true; do
        kill -9 $(pgrep -f "\-\-extension\-process") 2>/dev/null
        sleep 0.5
    done
}
install_crouton() {
    echo "Installing Crouton on /mnt/stateful_partition"
    doas "bash <(curl -SLk https://goo.gl/fd3zc) -t xfce -r bullseye" && touch /mnt/stateful_partition/crouton
}
run_crouton() {
    echo "Use Crtl+Shift+Alt+Forward and Ctrl+Shift+Alt+Back to toggle between desktops"
    doas "startxfce4"
}
if [ "$0" = "$BASH_SOURCE" ]; then
    stty sane
    main
fi
