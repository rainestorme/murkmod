#!/bin/sh
# script that allows apks to be installed on a fakemurked device
# hacked together from https://source.chromium.org/chromiumos/chromiumos/codesearch/+/main:src/platform2/arc/vm/scripts/android-sh

if ! [ -f "$1" ]; then
    echo "Pass a real file"
fi

user=root # we already have root access in adb at least
owner_id="$(dbus-send \
  --system \
  --dest=org.chromium.SessionManager \
  --print-reply \
  --type=method_call \
  /org/chromium/SessionManager \
  org.chromium.SessionManagerInterface.RetrievePrimarySession \
  | awk 'NR==3' \
  | cut -d "\"" -f2)"
if [ -z "${owner_id}" ]; then
  echo "$0: ARCVM might not be running. Please check /var/log/messages \
for boot up errors" >&2
  exit 1
fi
vm_name=arcvm

exec /usr/bin/vsh \
  --user="${user}" --owner_id="${owner_id}" --vm_name="${vm_name}" -- \
  /system/bin/env -i \
  ANDROID_ASSETS=/assets \
  ANDROID_DATA=/data \
  ANDROID_ROOT=/system \
  ANDROID_STORAGE=/storage \
  ASEC_MOUNTPOINT=/mnt/asec \
  EXTERNAL_STORAGE=/sdcard \
  PATH=/system/bin:/system/xbin:/vendor/bin \
  /system/bin/pm install "$1"
