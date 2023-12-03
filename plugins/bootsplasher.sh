#!/bin/bash
# menu_plugin
PLUGIN_NAME="Bootsplasher"
PLUGIN_FUNCTION="Set custom boot splash"
PLUGIN_DESCRIPTION="Simple plugin to set a custom boot splash from the user's downloads folder"
PLUGIN_AUTHOR="rainestorme"
PLUGIN_VERSION=1

doas() {
    ssh -t -p 1337 -i /rootkey -oStrictHostKeyChecking=no root@127.0.0.1 "$@"
}

copy_bootsplash_static() {
  echo "Copying bootsplash..."
  doas 'rm /usr/share/chromeos-assets/images_100_percent/boot_splash_frame*.png'
  doas 'cp /tmp/bootsplash.png /usr/share/chromeos-assets/images_100_percent/boot_splash_frame00.png'
  rm -f /tmp/bootsplash.png
  echo "Done!"
}

copy_bootsplash_animated() {
  echo "Copying bootsplash..."
  doas 'rm /usr/share/chromeos-assets/images_100_percent/boot_splash_frame*.png'
  doas 'cp /tmp/bootsplash/*.png /usr/share/chromeos-assets/images_100_percent/'
  rm -rf /tmp/bootsplash
  echo "Done!"
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

set_custom() {
  read -p 'Enter filename (downloads folder) > ' bootsplash
  cp "/home/chronos/user/Downloads/$bootsplash" /tmp/bootsplash.png
  copy_bootsplash_static
}

set_custom_animated() {
  read -p 'Enter folder name (downloads folder) > ' bootsplash
  cp -r "/home/chronos/user/Downloads/$bootsplash" /tmp/bootsplash
  copy_bootsplash_animated
}

restore_murkmod() {
  echo "Grabbing murkmod bootsplash..."
  install "chromeos-bootsplash-v2.png" /tmp/bootsplash.png
  copy_bootsplash_static
}

echo "Make sure your bootsplash is in PNG format!"
echo "Animated bootsplashes must be in a folder named 'bootsplash' in your downloads folder!"
echo "Select an option:"
echo " 1. Set custom static bootsplash"
echo " 2. Set custom animated bootsplash"
echo " 3. Restore murkmod default bootsplash"
read -r -p "> (1-2): " choice
case "$choice" in
1) set_custom ;;
2) set_custom_animated ;;
3) restore_murkmod ;;
*) echo && echo "Invalid option, dipshit." && echo ;;
esac

sync
exit