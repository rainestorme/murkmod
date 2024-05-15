#!/bin/bash

# image_patcher.sh
# written based on the original by coolelectronics and r58, modified heavily for murkmod

CURRENT_MAJOR=6
CURRENT_MINOR=0
CURRENT_VERSION=0

# God damn, there are a lot of unused functions in here!
# future rainestorme: finally cleaned it up! :D

ascii_info() {
    echo -e "                      __                      .___\n  _____  __ _________|  | __ _____   ____   __| _/\n /     \|  |  \_  __ \  |/ //     \ /  _ \ / __ | \n|  Y Y  \  |  /|  | \/    <|  Y Y  (  <_> ) /_/ | \n|__|_|  /____/ |__|  |__|_ \__|_|  /\____/\____ | \n      \/                  \/     \/            \/\n"
    echo "        The fakemurk plugin manager - v$CURRENT_MAJOR.$CURRENT_MINOR.$CURRENT_VERSION"

    # spaces get mangled by makefile, so this must be separate
}
nullify_bin() {
    cat <<-EOF >$1
#!/bin/bash
exit
EOF
    chmod 777 $1
    # shebangs crash makefile
}

. /usr/share/misc/chromeos-common.sh || :

traps() {
    set -e
    trap 'last_command=$current_command; current_command=$BASH_COMMAND' DEBUG
    trap 'echo "\"${last_command}\" command failed with exit code $?. THIS IS A BUG, REPORT IT HERE https://github.com/MercuryWorkshop/fakemurk"' EXIT
}

leave() {
    trap - EXIT
    echo "exiting successfully"
    exit
}


sed_escape() {
    echo -n "$1" | while read -n1 ch; do
        if [[ "$ch" == "" ]]; then
            echo -n "\n"
            # dumbass shellcheck not expanding is the entire point
        fi
        echo -n "\\x$(printf %x \'"$ch")"
    done
}

move_bin() {
    if test -f "$1"; then
        mv "$1" "$1.old"
    fi
}

disable_autoupdates() {
    # thanks phene i guess?
    # this is an intentionally broken url so it 404s, but doesn't trip up network logging
    sed -i "$ROOT/etc/lsb-release" -e "s/CHROMEOS_AUSERVER=.*/CHROMEOS_AUSERVER=$(sed_escape "https://updates.gooole.com/update")/"

    # we don't want to take ANY chances
    move_bin "$ROOT/usr/sbin/chromeos-firmwareupdate"
    nullify_bin "$ROOT/usr/sbin/chromeos-firmwareupdate"

    # bye bye trollers! (trollers being cros devs)
    rm -rf "$ROOT/opt/google/cr50/firmware/" || :
}

SCRIPT_DIR=$(dirname "$0")
configure_binaries(){
  if [ -f /sbin/ssd_util.sh ]; then
    SSD_UTIL=/sbin/ssd_util.sh
  elif [ -f /usr/share/vboot/bin/ssd_util.sh ]; then
    SSD_UTIL=/usr/share/vboot/bin/ssd_util.sh
  elif [ -f "${SCRIPT_DIR}/lib/ssd_util.sh" ]; then
    SSD_UTIL="${SCRIPT_DIR}/lib/ssd_util.sh"
  else
    echo "ERROR: Cannot find the required ssd_util script. Please make sure you're executing this script inside the directory it resides in"
    exit 1
  fi
}

patch_root() {
    echo "Staging populator..."
    >$ROOT/population_required
    >$ROOT/reco_patched
    echo "Murkmod-ing root..."
    echo "Disabling autoupdates..."
    disable_autoupdates
    local milestone=$(lsbval CHROMEOS_RELEASE_CHROME_MILESTONE $ROOT/etc/lsb-release)
    echo "Installing startup scripts..."
    move_bin "$ROOT/sbin/chromeos_startup.sh"
    if [ "$milestone" -gt "116" ]; then
        echo "Detected newer version of CrOS, using new chromeos_startup"
        move_bin "$ROOT/sbin/chromeos_startup"
        install "chromeos_startup.sh" $ROOT/sbin/chromeos_startup
        chmod 755 $ROOT/sbin/chromeos_startup # whoops
        touch $ROOT/new-startup
    else
        move_bin "$ROOT/sbin/chromeos_startup.sh"
        install "chromeos_startup.sh" $ROOT/sbin/chromeos_startup.sh
        chmod 755 $ROOT/sbin/chromeos_startup.sh
    fi
    echo "Installing murkmod components..."
    install "daemon.sh" $ROOT/sbin/murkmod-daemon.sh
    move_bin "$ROOT/usr/bin/crosh"
    install "mush.sh" $ROOT/usr/bin/crosh
    echo "Installing startup services..."
    install "pre-startup.conf" $ROOT/etc/init/pre-startup.conf
    install "cr50-update.conf" $ROOT/etc/init/cr50-update.conf
    echo "Installing other utilities..."
    install "ssd_util.sh" $ROOT/usr/share/vboot/bin/ssd_util.sh
    install "image_patcher.sh" $ROOT/sbin/image_patcher.sh
    install "crossystem_boot_populator.sh" $ROOT/sbin/crossystem_boot_populator.sh
    install "ssd_util.sh" $ROOT/usr/share/vboot/bin/ssd_util.sh
    install "plugin_common.sh" $ROOT/usr/bin/murkmod_plugin_common.sh
    mkdir -p "$ROOT/etc/opt/chrome/policies/managed"
    install "pollen.json" $ROOT/etc/opt/chrome/policies/managed/policy.json
    echo "Chmod-ing everything..."
    chmod 777 $ROOT/sbin/murkmod-daemon.sh $ROOT/usr/bin/crosh $ROOT/usr/share/vboot/bin/ssd_util.sh $ROOT/sbin/image_patcher.sh $ROOT/etc/opt/chrome/policies/managed/policy.json $ROOT/sbin/crossystem_boot_populator.sh $ROOT/usr/share/vboot/bin/ssd_util.sh    
    echo "Done."
}

# https://www.chromium.org/chromium-os/developer-library/reference/infrastructure/lsb-release/
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

get_asset() {
    curl -s -f "https://api.github.com/repos/rainestorme/murkmod/contents/$1" | jq -r ".content" | base64 -d
}

install() {
    TMP=$(mktemp)
    get_asset "$1" >"$TMP"
    if [ "$?" == "1" ] || ! grep -q '[^[:space:]]' "$TMP"; then
        echo "Failed to install $1 to $2"
        rm -f "$TMP"
        exit
    fi
    # Don't mv, that would break permissions
    cat "$TMP" >"$2"
    rm -f "$TMP"
}

main() {
  traps
  ascii_info
  configure_binaries
  echo $SSD_UTIL

  if [ -z $1 ] || [ ! -f $1 ]; then
    echo "\"$1\" isn't a real file, dipshit! You need to pass the path to the recovery image. Optional args: <path to custom bootsplash: path to a png> <unfuck stateful: int 0 or 1>"
    exit
  fi
  if [ -z $2 ]; then
    echo "Not using a custom bootsplash."
    local bootsplash="0"
  elif [ "$2" == "cros" ]; then
    echo "Using cros bootsplash."
    local bootsplash="cros"
  elif [ ! -f $2 ]; then
    echo "File $2 not found for custom bootsplash"
    local bootsplash="0"
  else
    echo "Using custom bootsplash $2"
    local bootsplash=$2
  fi
  if [ -z $3 ]; then
    local unfuckstateful="1"
  else 
    local unfuckstateful=$3
  fi

  if [ "$unfuckstateful" == "1" ]; then
    echo "Will unfuck stateful partition upon boot."  
  fi

  local bin=$1
  
  echo "Creating loop device..."
  local loop=$(losetup -f)
  losetup -P "$loop" "$bin"

  echo "Disabling kernel verity..."
  $SSD_UTIL --debug --remove_rootfs_verification -i ${loop} --partitions 4
  echo "Enabling RW mount..."
  $SSD_UTIL --debug --remove_rootfs_verification --no_resign_kernel -i ${loop} --partitions 2

  # for good measure
  sync
  
  echo "Mounting target..."
  mkdir /tmp/mnt || :
  mount "${loop}p3" /tmp/mnt

  ROOT=/tmp/mnt
  patch_root

  if [ "$bootsplash" != "cros" ]; then
    if [ "$bootsplash" != "0" ]; then
      echo "Adding custom bootsplash..."
      for i in $(seq -f "%02g" 0 30); do
        rm $ROOT/usr/share/chromeos-assets/images_100_percent/boot_splash_frame${i}.png
      done
      cp $bootsplash $ROOT/usr/share/chromeos-assets/images_100_percent/boot_splash_frame00.png
    else
      echo "Adding murkmod bootsplash..."
      install "chromeos-bootsplash-v2.png" /tmp/bootsplash.png
      for i in $(seq -f "%02g" 0 30); do
        rm $ROOT/usr/share/chromeos-assets/images_100_percent/boot_splash_frame${i}.png
      done
      cp /tmp/bootsplash.png $ROOT/usr/share/chromeos-assets/images_100_percent/boot_splash_frame00.png
      rm /tmp/bootsplash.png
    fi
  fi

  if [ "$unfuckstateful" == "0" ]; then
    touch $ROOT/stateful_unfucked
    chmod 777 $ROOT/stateful_unfucked
    # by creating the flag in advance we can prevent running mkfs.ext4 on stateful upon next boot, thus retaining user data
  fi

  sleep 2
  sync
  echo "Done. Have fun."

  umount "$ROOT"
  sync
  losetup -D "$loop"
  sync
  sleep 2
  rm -rf /tmp/mnt
  leave
}

if [ "$0" = "$BASH_SOURCE" ]; then
    stty sane
    if [ "$EUID" -ne 0 ]; then
        echo "Please run as root"
        exit
    fi
    main "$@"
fi
