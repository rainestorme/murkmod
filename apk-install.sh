#!/bin/sh -e
# script that allows apks to be installed on a fakemurked device
# hacked together from https://source.chromium.org/chromiumos/chromiumos/codesearch/+/main:src/platform2/arc/vm/scripts/android-sh
# interestingly, it turns out that the above link doesn't contain the version used on a stock v105 install - this had to be taken directly from /usr/sbin.

if ! [ -f "$1" ]; then
    echo "Pass a real file"
    exit
fi

die() {
  echo "$0: $1" >&2
  exit 1
}

context_exists() {
  printf "$1" > /sys/fs/selinux/context 2>/dev/null
}

nsenter_flags=
pid=

# Parse leading long-form flags. The remaining arguments are passed to sh.
while [ $# -gt 0 ]; do
  arg="$1"

  case "${arg}" in
    --gid|--uid|--pid)
      shift
      [ $# -eq 0 ] && die "Missing ${arg} option"
      id="$1" && shift
      [ "${id}" -ge 0 ] 2>/dev/null || die "Invalid ${arg} option"
      ;;

    --) shift;;
  esac

  case "${arg}" in
    --gid) nsenter_flags="${nsenter_flags} -G ${id}";;
    --uid) nsenter_flags="${nsenter_flags} -S ${id}";;
    --pid) pid="${id}";;
        *) break;;
  esac
done

container_root=
if [ -n "${pid}" ]; then
  [ -d "/proc/${pid}" ] || die "PID ${pid} not found."
else
  # Support all pidfile locations, use the first usable one in the odd case
  # where more than one exists.
  for candidatefile in $(find /run/containers/android*/ \
      -maxdepth 1 -name container.pid -print); do
    candidate="$(cat "${candidatefile}")"
    container_root="$(dirname "${candidatefile}")/root"
    if [ "${candidate}" != "" -a -d "/proc/${candidate}" ]; then
      pid="${candidate}"
      break
    fi
  done
  [ -n "${pid}" ] ||
      die "Container PID file not found, is the container running?"
fi

context="$(id -Z)"

# Use the su context if available and the 'su' binary exists (both are true
# only on userdebug builds).
su_context="u:r:su:s0"
if context_exists "${su_context}" && \
   [ -f "${container_root}/system/xbin/su" ]; then
  context=${su_context}
fi

/usr/bin/env -i \
  ANDROID_ASSETS=/assets \
  ANDROID_DATA=/data \
  ANDROID_ROOT=/system \
  ANDROID_STORAGE=/storage \
  ASEC_MOUNTPOINT=/mnt/asec \
  EXTERNAL_STORAGE=/sdcard \
  PATH=/sbin:/vendor/bin:/system/bin:/system/xbin \
  /usr/bin/nsenter -t "${pid}" -C -m -U -i -n -p -r -w \
  ${nsenter_flags} \
  /system/bin/runcon "${context}" /system/bin/pm "$1"