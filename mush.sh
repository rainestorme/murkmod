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
    trap 'echo \"${last_command}\" command failed with exit code $?' EXIT
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
    clear
    trap 'kill -2 $! >/dev/null 2>&1' INT
    (
        # shellcheck disable=SC2068
        $@
    )
    trap '' INT
    clear
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
(4) Plugins
(5) Install plugins
(6) Uninstall plugins
(7) Powerwash
(8) Emergency Revert & Re-Enroll
(9) Soft Disable Extensions
(10) Hard Disable Extensions
(11) Hard Enable Extensions
(12) Edit Pollen
(13) Install Crouton
(14) Start Crouton
(15) [EXPERIMENTAL] Update ChromeOS
(16) [EXPERIMENTAL] Install Chromebrew
(17) Check for updates
EOF
        
        swallow_stdin
        read -r -p "> (1-15): " choice
        case "$choice" in
        1) runjob doas bash ;;
        2) runjob doas "su chronos" ;;
        3) runjob /usr/bin/crosh.old ;;
        4) runjob show_plugins ;;
        5) runjob install_plugins ;;
        6) runjob uninstall_plugins ;;
        7) runjob powerwash ;;
        8) runjob revert ;;
        9) runjob softdisableext ;;
        10) runjob harddisableext ;;
        11) runjob hardenableext ;;
        12) runjob edit /etc/opt/chrome/policies/managed/policy.json ;;
        13) runjob install_crouton ;;
        14) runjob run_crouton ;;
        15) runjob attempt_chromeos_update ;;
        16) runjob attempt_chromebrew_install ;;
        17) runjob do_updates && exit 0 ;;


        *) echo "----- Invalid option ------" ;;
        esac
    done
}

do_updates() {
    doas "bash <(curl -SLk https://raw.githubusercontent.com/rainestorme/murkmod/main/murkmod.sh)"
    exit
}

show_plugins() {
    clear
    
    plugins_dir="/mnt/stateful_partition/murkmod/plugins"
    plugin_files=()

    while IFS= read -r -d '' file; do
        plugin_files+=("$file")
    done < <(find "$plugins_dir" -type f -name "*.sh" -print0)

    plugin_info=()
    for file in "${plugin_files[@]}"; do
        plugin_script=$file
        PLUGIN_NAME=$(grep -o 'PLUGIN_NAME=".*"' "$plugin_script" | cut -d= -f2-)
        PLUGIN_FUNCTION=$(grep -o 'PLUGIN_FUNCTION=".*"' "$plugin_script" | cut -d= -f2-)
        PLUGIN_DESCRIPTION=$(grep -o 'PLUGIN_DESCRIPTION=".*"' "$plugin_script" | cut -d= -f2-)
        PLUGIN_AUTHOR=$(grep -o 'PLUGIN_AUTHOR=".*"' "$plugin_script" | cut -d= -f2-)
        PLUGIN_VERSION=$(grep -o 'PLUGIN_VERSION=".*"' "$plugin_script" | cut -d= -f2-)
        plugin_info+=("$PLUGIN_FUNCTION (provided by $PLUGIN_NAME)")
    done

    # Print menu options
    for i in "${!plugin_info[@]}"; do
        printf "%s. %s\n" "$((i+1))" "${plugin_info[$i]}"
    done

    # Prompt user for selection
    read -p "> Select a plugin (or q to quit): " selection

    if [ "$selection" = "q" ]; then
        return 0
    fi

    # Validate user's selection
    if ! [[ "$selection" =~ ^[1-9][0-9]*$ ]]; then
        echo "Invalid selection. Please enter a number between 0 and ${#plugin_info[@]}"
        return 1
    fi

    if ((selection < 1 || selection > ${#plugin_info[@]})); then
        echo "Invalid selection. Please enter a number between 0 and ${#plugin_info[@]}"
        return 1
    fi

    # Get plugin function name and corresponding file
    selected_plugin=${plugin_info[$((selection-1))]}
    selected_file=${plugin_files[$((selection-1))]}

    # Execute the plugin
    bash <(cat $selected_file) # weird syntax due to noexec mount
    return 0
}


install_plugins() {
  local raw_url="https://raw.githubusercontent.com/rainestorme/murkmod/main/plugins"

  echo "Find a plugin you want to install here: "
  echo "  https://github.com/rainestorme/murkmod/tree/main/plugins"
  echo "Enter the name of a plugin (including the .sh) to install it (or q to quit):"
  read -r plugin_name

  while [[ $plugin_name != "q" ]]; do
    local plugin_url="$raw_url/$plugin_name"
    local plugin_info=$(curl -s $plugin_url)

    if [[ $plugin_info == *"Not Found"* ]]; then
      echo "Plugin not found"
    else      
      doas "pushd /mnt/stateful_partition/murkmod/plugins && curl https://raw.githubusercontent.com/rainestorme/murkmod/main/plugins/$plugin_name -O && popd"
      echo "Installed $plugin_name"
    fi

    echo "Enter the name of a plugin (including the .sh) to install (or q to quit):"
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
        plugin_script=$file
        PLUGIN_NAME=$(grep -o 'PLUGIN_NAME=.*' "$plugin_script" | cut -d= -f2-)
        PLUGIN_FUNCTION=$(grep -o 'PLUGIN_FUNCTION=.*' "$plugin_script" | cut -d= -f2-)
        PLUGIN_DESCRIPTION=$(grep -o 'PLUGIN_DESCRIPTION=.*' "$plugin_script" | cut -d= -f2-)
        PLUGIN_AUTHOR=$(grep -o 'PLUGIN_AUTHOR=.*' "$plugin_script" | cut -d= -f2-)
        PLUGIN_VERSION=$(grep -o 'PLUGIN_VERSION=.*' "$plugin_script" | cut -d= -f2-)
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
        PLUGIN_NAME=$(grep -o 'PLUGIN_NAME=".*"' "$plugin_file" | cut -d= -f2-)
        PLUGIN_FUNCTION=$(grep -o 'PLUGIN_FUNCTION=".*"' "$plugin_file" | cut -d= -f2-)
        PLUGIN_DESCRIPTION=$(grep -o 'PLUGIN_DESCRIPTION=".*"' "$plugin_file" | cut -d= -f2-)
        PLUGIN_AUTHOR=$(grep -o 'PLUGIN_AUTHOR=".*"' "$plugin_file" | cut -d= -f2-)
        PLUGIN_VERSION=$(grep -o 'PLUGIN_VERSION=".*"' "$plugin_file" | cut -d= -f2-)

        plugin_name="$PLUGIN_NAME (version $PLUGIN_VERSION by $PLUGIN_AUTHOR)"

        read -r -p "Are you sure you want to uninstall $plugin_name? [y/n] " confirm
        if [ "$confirm" == "y" ]; then
            doas rm "$plugin_file"
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

    if doas "((\$(cgpt show -n \"$DST\" -i 2 -P) > \$(cgpt show -n \"$DST\" -i 4 -P)))"; then
        doas cgpt add "$DST" -i 2 -P 0
        doas cgpt add "$DST" -i 4 -P 1
    else
        doas cgpt add "$DST" -i 4 -P 0
        doas cgpt add "$DST" -i 2 -P 1
    fi
    echo "Setting vpd"
    doas vpd -i RW_VPD -s check_enrollment=1
    doas vpd -i RW_VPD -s block_devmode=1
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
    echo "Installing Crouton..."
    doas "bash <(curl -SLk https://goo.gl/fd3zc) -t xfce -r bullseye" && touch /mnt/stateful_partition/crouton
}

run_crouton() {
    echo "Use Crtl+Shift+Alt+Forward and Ctrl+Shift+Alt+Back to toggle between desktops"
    doas "startxfce4"
}

# https://chromium.googlesource.com/chromiumos/docs/+/master/lsb-release.md
lsbval() {
  local key="$1"
  local lsbfile="${2:-/etc/lsb-release}"

  if ! echo "${key}" | grep -Eq '^[a-zA-Z0-9_]+$'; then
    return 1
  fi

  sed -E -n -e \
    "/^[[:space:]]*${key}[[:space:]]*=/{
      s:^[^=]+=[[:space:]]*::
      s:[[:space:]]+$::
      p
    }" "${lsbfile}"
}

get_booted_kernnum() {
    if doas "((\$(cgpt show -n \"$dst\" -i 2 -P) > \$(cgpt show -n \"$dst\" -i 4 -P)))"; then
        echo -n 2
    else
        echo -n 4
    fi
}

opposite_num() {
    if [ "$1" == "2" ]; then
        echo -n 4
    elif [ "$1" == "4" ]; then
        echo -n 2
    elif [ "$1" == "3" ]; then
        echo -n 5
    elif [ "$1" == "5" ]; then
        echo -n 3
    else
        return 1
    fi
}

attempt_chromeos_update(){
    local builds=$(curl https://chromiumdash.appspot.com/cros/fetch_serving_builds?deviceCategory=Chrome%20OS)
    local release_board=$(lsbval CHROMEOS_RELEASE_BOARD)
    local board=${release_board%%-*}
    local hwid=$(jq "(.builds.$board[] | keys)[0]" <<<"$builds")
    local hwid=${hwid:1:-1}
    local latest_milestone=$(jq "(.builds.$board[].$hwid.pushRecoveries | keys) | .[length - 1]" <<<"$builds")
    local remote_version=$(jq ".builds.$board[].$hwid[$latest_milestone].version" <<<"$builds")
    local remote_version=${remote_version:1:-1}
    local local_version=$(lsbval GOOGLE_RELEASE)

    if (( ${remote_version%%\.*} > ${local_version%%\.*} )); then
        echo "Updating to ${remote_version}. THIS WILL DELETE YOUR REVERT BACKUP AND YOU WILL NO LONGER BE ABLE TO REVERT! THIS MAY ALSO DELETE ALL USER DATA! press enter to confirm, Ctrl+C to cancel."
        read -r
        sleep 4
        # read choice
        local reco_dl=$(jq ".builds.$board[].$hwid.pushRecoveries[$latest_milestone]" <<< "$builds")
        local tmpdir=/mnt/stateful_partition/update_tmp/
        doas mkdir $tmpdir
        echo "Downloading ${remote_version} from ${reco_dl}..."
        curl "${reco_dl:1:-1}" | doas "dd of=$tmpdir/image.zip status=progress"
        echo "Unzipping update binary..."
        cat $tmpdir/image.zip | gunzip | doas "dd of=$tmpdir/image.bin status=progress"
        doas rm -f $tmpdir/image.zip
        echo "Invoking image patcher..."
        doas image_patcher.sh "$tmpdir/image.bin"

        local loop=$(doas losetup -f | tr -d '\r')
        doas losetup -P "$loop" "$tmpdir/image.bin"
        echo "Performing update..."
        local dst=/dev/$(get_largest_nvme_namespace)
        local tgt_kern=$(opposite_num $(get_booted_kernnum))
        local tgt_root=$(( $tgt_kern + 1 ))

        local kerndev=${dst}p${tgt_kern}
        local rootdev=${dst}p${tgt_root}
        echo "Installing kernel patch to ${kerndev}..."
        doas dd if="${loop}p4" of="$kerndev" status=progress
        echo "Installing root patch to ${rootdev}..."
        doas dd if="${loop}p3" of="$rootdev" status=progress
        echo "Setting kernel priority..."
        doas cgpt add "$dst" -i 4 -P 0
        doas cgpt add "$dst" -i 2 -P 0
        doas cgpt add "$dst" -i "$tgt_kern" -P 1

        doas crossystem.old block_devmode=0
        doas vpd -i RW_VPD -s block_devmode=0

        # doas rm -rf $tmpdir
    
    else
        echo "update not required"
    fi
}

attempt_chromebrew_install() {
    # Chromebrew's folders are still unneccecarily referenced at some points, so they're symlinked to the actual location
    doas mkdir -p /mnt/stateful_partition/murkmod/chromebrew
    doas mkdir -pv /mnt/stateful_partition/murkmod/chromebrew/{etc,include,lib,lib64,share,tmp,bin}
    doas "for i in etc include lib lib64 share tmp; do
      ln -sv /mnt/stateful_partition/murkmod/chromebrew/$i /usr/local/$i
    done"
    doas 'chmod 777 /mnt/stateful_partition/murkmod/chromebrew/*'
    doas 'su chronos -s /bin/bash -c "curl -Ls https://raw.githubusercontent.com/rainestorme/chromebrew/master/install.sh | bash" && exit'
    echo "Don't worry. Seeing an erorr at the end of chromebrew installation about ln failing to make a symlink is normal. Chromebrew has to be invoked in a weird way for anything to work."
    read -p "Press enter to continue."
}

if [ "$0" = "$BASH_SOURCE" ]; then
    stty sane
    main
fi
