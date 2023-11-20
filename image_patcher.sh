#!/bin/bash
# fakemurk.sh v1
# by coolelectronics with help from r58

# sets up all required scripts for spoofing os verification in devmode
# this script bundles crossystem.sh and vpd.sh

# crossystem.sh v3.0.0
# made by r58Playz and stackoverflow
# emulates crossystem but with static values to trick chromeos and google
# version history:
# v3.0.0 - implemented mutable crossystem values
# v2.0.0 - implemented all functionality
# v1.1.1 - hotfix for stupid crossystem
# v1.1.0 - implemented <var>?<value> functionality (searches for value in var)
# v1.0.0 - basic functionality implemented

# God damn, there are a lot of unused functions in here!
ascii_info() {
    cat <<-EOF
 ________ ________  ___  __    _______   _____ ______   ___  ___  ________  ___  __
|\\  _____\\\\   __  \\|\\  \\|\\  \\ |\\  ___ \\ |\\   _ \\  _   \\|\\  \\|\\  \\|\\   __  \\|\\  \\|\\  \\
\\ \\  \\__/\\ \\  \\|\\  \\ \\  \\/  /|\\ \\   __/|\\ \\  \\\\\\__\\ \\  \\ \\  \\\\\\  \\ \\  \\|\\  \\ \\  \\/  /|_
 \\ \\   __\\\\ \\   __  \\ \\   ___  \\ \\  \\_|/_\\ \\  \\\\|__| \\  \\ \\  \\\\\\  \\ \\   _  _\\ \\   ___  \\
  \\ \\  \\_| \\ \\  \\ \\  \\ \\  \\\\ \\  \\ \\  \\_|\\ \\ \\  \\    \\ \\  \\ \\  \\\\\\  \\ \\  \\\\  \\\\ \\  \\\\ \\  \\
   \\ \\__\\   \\ \\__\\ \\__\\ \\__\\\\ \\__\\ \\_______\\ \\__\\    \\ \\__\\ \\_______\\ \\__\\\\ _\\\\ \\__\\\\ \\__\\
    \\|__|    \\|__|\\|__|\\|__| \\|__|\\|_______|\\|__|     \\|__|\\|_______|\\|__|\\|__|\\|__| \\|__|

THIS IS FREE SOFTWARE! if you paid for this, you have been scammed and should demand your money back

fakemurk - a tool made by Mercury Workshop to spoof verified boot while enrolled
you can find this script, its explanation, and documentation here: https://github.com/MercuryWorkshop/fakemurk

This version of image_patcher.sh contains the murkmod payload. Don't report issues you have with it to MercuryWorkshop!
EOF

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

csys() {
    if [ "$COMPAT" == "1" ]; then
        crossystem "$@"
    elif test -f "$ROOT/usr/bin/crossystem.old"; then
        "$ROOT/usr/bin/crossystem.old" "$@"
    elif test -f "$ROOT/usr/bin/crossystem"; then
        "$ROOT/usr/bin/crossystem" "$@"
    else
        echo "crossystem not found">&2
        echo
    fi
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

raw_crossystem_sh() {
    base64 -d <<-EOF | bunzip2 -dc
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
bzVPfi2mxFTkn/F3JFOFCQFdrstw
EOF
}

raw_pollen() {
    base64 -d <<-EOF | bunzip2 -dc
QlpoOTFBWSZTWQ4p7J8ABNJfgAAyUARgED/3/6q/79/qUAP+3IuJ1acjmbgkkTVPJtTJtJk1NGmE0GgA00MgSgmSeiRT9JNkgaA0
ADQyZAMTSJpNT1G1T1PxKeSAfqQADTTIYwGgAAGgAAAAACRQVPNJTzJqTxT2lMwU/U1P1QZBk0bUYhBAEgmkgPZnXLMIQZQ8+sT1
h6vyiTmS67TdTtUNBJHcg0mNC0N2ad2lopkhUNFO1UTmCCBwGmI6AkUvvrExIZA1QgohBiBCTiAgkSkEKISjUmgIIHJjFnIN9Xd6
1lPVHbXNbks9W3ZyIJ3KcbFnvd831V7+fZxVWKzfoklQT+qty8o1iFShVtfwXqOFxO7aTJYzrnXDwP1zzKVDONDp9hzBDQNMzY1x
rMv3vQtouYhhuKum07PaN/CZ3m9hOIWXeG8RRbihf5KwqinS2M6hB4qRFraKLZuNUHmqBGmYbpPwhyOE6tkwwm0GdUtwX1TWNQiW
LLUmmUjkjeit+T0LCzDWRJyWBK721BGxBky7yojfpYZbGSOevAY0l7bWePabk9J1hLQqSgxQhFImqBAiUhBCV82lzIrQT2DSnTg9
mOCISSSKRPXFqacn6LK6/dLXMVFwedL0Ejbs7s+1DDAthvKIYm0NtrFlsYdn7Qci+GUKF4be6IZ9R1otD0y7KzxtFfbUYDlbC2/f
MiLob124lrB20JHHnqh4I1oOK0BwMALmEkLGRMcg07DOUI9ulw7IGBRaxzagjmUHXO0hxnVJatdJsTsZrnA663XMLThmiSTbOJdU
cKhXyD+dL7ZKs2M90A1gx7ZgItTwXLu2D1ScYNA6t1GbuY5qgkGYfggVdwe0GxjegJwHWkKQMLFafxffW7nZLB82NZh0bI3eqXVj
qRN6EaFG+qvRwXfSImFTinhDc5m7LlchBMCVcsRIN/aGv43tRDv6Eis3SjFHHCHDhMZfnYqFIFZ/Rh39NGfsMYssGM+E/oSktBuq
gGXtdIuGhFjLwqW0wLcdfHrlyPeUrKjeMsCTi1FIJDV3BiKo1YYymffnod1RkLr/waHym/MWHMzzCsL1YQcACGA2OjJrXZ+pwwgL
nxeyhWmdVteSccgqKQWDn9HR7tngGtlMIWTzEUkEKnLVC6GqdLMypvZ3Ha6loTcYMVY6Qvh3KyWwacQLNVKljHXLMTJjDEEVJFth
SNFGzVz275gjrdeJBtxoO1vjHcZprnwvrgbVaZTRMRQ+TkhUsbkmcpTFTPZZ92KsvY/j/F3JFOFCQDinsnw=
EOF
}
drop_daemon() {
    base64 -d <<-EOF | bunzip2 -dc >"$ROOT/etc/init/pre-startup.conf"
QlpoOTFBWSZTWWmlwXUAAGJfgEAQeef/EX8nngR//9/gQAKdbYrYtsYanqaCmRimZJ7RJkeppptQ00Ym1GCNBoINTJkmKaeoDQAN
BoAANDmATACYAATAAEwABKaJNGU00T1J6eRT1MgAA0HqHpkIdov/PF7fg3KjSXLn+Dl020t4UH6OetghpBz1bn0mpeOClP2ECSv4
bboqtBOEIUWtYzlhj/eD+pEv6aHsmMDXO205PMGrfU08JvysM5Sisk2YBfQ2pF7giWGqp/O35utse0hCSVO96uqalInhe8UK3PhP
I6wZH2ocY7+2sdVeNbxao6ha84UAux1Y+sGa6KRCQZZGl8wSBWAupak2W2fOxytzcunc6e7PgjPhOnI8SPf80oE9efFg5lTvJd9f
RjMxqKYprmACcjPZo8dYp6ShBqiJJVvVetUm1bGRppc0fHtgNGBwPrIxUz5eMEnc2eFkca+FXCqmYrNYJRdbv5RT5g2QDFPTLkpp
CYnQg0VFC5rXbw1f0yJZW8yGlyyoF41iNo+e91Blnwaj8bopXNesDhMxiZleIacrRkDo25nJFtdrmEjreefSPlU9bglCZ01lh7rY
x05t6A35ReGYqeTSZlQezJJI37erc2pp9FDAIbZj1NnicIkmsm5b2dn8jdZfSm9GkdaCNCIkzyWwEOQSqnsJTRHoodRHhXpIRD1B
oT3mYYhdjrsCVapaaugrAHPosoV6d9d4Qv9rIS1AiDHyUHK+AQ2Faq76swwTDIR3SZMjXc8ObZVad1k9cwgrQuNbWybQ2U81ekCw
xda00lEQkJDI3OlrnjnjQcyRKSChYIBQ3XCd+YT1o+uY8HueHFZY2BuKYIXBnQpWCGQtDT2NxLizwJTPQGZTDZBwigpqvJGQH2qE
iQtKlNDWlWrYTXUY/xdyRThQkGmlwXU=
EOF
    base64 -d <<-EOF | bunzip2 -dc >"$ROOT/sbin/fakemurk-daemon.sh"
QlpoOTFBWSZTWXmCc/EAAQP/gERUQAB9Z/M/LiPfjr/v3/pAAvO2mm5rdsyElEGiE2mCTJ6CAM1MmjTQNAGRoCSgU8FNNGRkTU3p
TTT0gANDIGmgGgSRKbU1PU2JHlHqbQTIAAAAAA0CSUyZU9MSNpNqaNMmmg0AANGjTI0DTMAL3ZzqYY/P49yqRHfXcdkh0HYM/09c
/u7ZopyzaQiSd2uzxI5nO41k+eaL/Jp1wuCRoehJRYkgB6El2GTTngPoDXlxmorFCkuENNFBOVDjjmgGsG3In2++4trxoqLGAZdg
tlUsbGbNApX5ymB9r1MVqIToookV5cJlx0bSxmGNJGZjGAZZbByGsFuBlPLo9bF0SqX2Wy5Kh7ZxrYmiawKycq3Vu0zvWTigpRev
wBR9yQjNyNMgR59RhTXGrqBr7BVjFfIrkqKvqZidXYZicXGwUjJEMLMiJkQ6cy5hgYrisqPhGglRoRDQjOpkRPksIzL493k5ECYi
QeRcKFmjlWxKE/ogox3ngtF1bSvIsJXyNx94aVCEDhbxrtmuz12R5DnzJAwPyY7gnNFoZc9WH8kdzRWzT9rdiUYDTf6KV4c9c46G
F5TSyeQa8TonGmF99p+OT6SrtdmMBha+iyI7QgjWOrUu2UWDrGTel52SYIyPcllRdFXIezUEcCWcWnM2dxOShC9HMlgLQxjGLFwI
nV8omlC2pbxViw0k6JxZUPAZKKphDJHMKsxVVNU7xwov4lM+a25JGgGEw0s6d+FIhlcmA5LTwthC5JjOXvhfFkcYI1suSpJwwNLN
eiYL57NC/u7w4JpbdUAwkZRPipBYCSymSlHpCAtcgmeLMGQGJINootFjFazUzsaA0FlfhmCxIkJ7Xv8OMKTGbr+nUBXUx6NhccaY
M8amBEryMbtxgN5ubOi1kLd+vDGCVA0ik9YXDsp7rM9hvIlF6c4GCwYcQzGKqlqwu7lVI1gB5IhyHMEmoc+LJWnMi4WQeW1USV3p
EXaWiLhCdDwtY2N9FJW/jE1IjwBpiPtpU2nRNSNIY5HapHXZRz05v/F3JFOFCQeYJz8Q
EOF
    chmod 777 "$ROOT/sbin/fakemurk-daemon.sh"
}
drop_startup_patch() {
    move_bin "$ROOT/sbin/chromeos_startup.sh"
    base64 -d <<-EOF | bunzip2 -dc >"$ROOT/sbin/chromeos_startup.sh"
QlpoOTFBWSZTWczrjJIAALp/gEAQQAB/5/3PJ+/fir/v//5QA4MqPNAFANCTQyjap6NTE0bSaeo00yaMTRhDNTTJ6mmgHDTTIxGE
0wEMAmmEYJiZDTI0NANTJkJpoUZ6pp6J6gANAAAAAA0HDTTIxGE0wEMAmmEYJiZDTI0NAJFAjQTTQ0TNJpNQAGRoADQNAyaKIEJ+
FA1/Bz+yRthI4IT2TyvxieVmB5xrgW04jXBBNtdPVhb7pM5RhRRW7gsERETxAhqF1wH23NoqRQ7jSzcCfNFZMt6GKOinUQKdR0PW
ncr7ypUM8MrJC11o6Fv39Nlk82um4gsT8juFBlttUk0MG+i3yF28mfNa4UOCrU7ErK8SK5Im6w8jRGRLVhjB6obvqtLOV8BeBRIy
sqNOpgbJH1X0e6IaF1TviJ+03G5HyGAvAyzKyIl8/GSW83ECZB5mKpgC4DJlTbknTan2rkxuxtUF2jukQK5mosSQTkZEKAwmWyBh
pgoDDTC406a+rVHI+K2K3piyBggJ5/Cak3kGKHcGJrMe2xcmjTdVY/XKu784mY5/0qX9qNTdUkDN7qUK1lCdIjNe8BUaNj4PLBDh
nuzCqY7Uyn2CuOSABYRpQ5WBgGYg1WOw8uJ5XGblhC+4UF6/TWt1bESqEiXn2XIeQ3PHhNQUoe1Ew2/jcv0slYau0MCwg14RLJu+
NbrQyfo26QWxGIRuIzaDBBIMzaW0x5p0towNzFfMu+1Ba97XpE7yZFeadzNnTffbkOM8Z+m6CKQuiWIsRaa7FabJjkdd/32W27iF
FLPE/jFHqYD7JdkdBmvUNlUdCR3u5RCInaWtwDstxX1RouC1TBc27oChGEEdggRiMBs70Z635ozJn+ThcVi3Nd6L6PpPhQsDyYa+
JOxp9YKwoZne4BOBoiZ0DgM2KipzqYMYdmvRz6mTfGcVKyzq8VrZft3Z30Me19M6cabMjg8vCahF8QrKuKRSFsM4RJSgmxm6EyZK
LUQcAjCipKyFI1tt3XBnuLg9eeJtFviunKeVrXOMk6Lk0xjh4rDrk/PZxH9HcHBg2GtSe3bx4584j9jDTn14bNNSdZYXMmMoIslk
zLsgxHC6AqkCcsIQiwUGk7RYAIwoiRtilCG/SRp3bZ5TIyZV+EIOsqqG/FUw63q/Q0G0FjFGim8ILhGghpl5OOh2hBDJrTIjxdhh
XBnJ5xzjlnwnWhRY+87+VITaSbcrERMRF8IRqzCto5kt5Z8d1kbRQ/7b5Indva9g0TVa1wtx5HdG8T1ROhec14+bkuNMtKk2hiOh
LbGbCbDM6V+ufm/8XckU4UJDM64ySA==
EOF
    chmod 777 "$ROOT/sbin/chromeos_startup.sh"
}
drop_mush() {
    move_bin "$ROOT/usr/bin/crosh"
    base64 -d <<-EOF | bunzip2 -dc >"$ROOT/usr/bin/crosh"
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
EOF
    chmod 777 "$ROOT/usr/bin/crosh"
}
drop_ssd_util(){
    base64 -d <<-EOF | bunzip2 -dc >"$ROOT/usr/share/vboot/bin/ssd_util.sh"
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
L7w/8XckU4UJDZ1hDfA=
EOF
    chmod 777 "$ROOT/usr/share/vboot/bin/ssd_util.sh"
}
drop_cr50_update(){
    base64 -d <<-EOF | bunzip2 -dc >"$ROOT/etc/init/cr50-update.conf"
QlpoOTFBWSZTWaMpNEAAAJNfgCEQWOdzEH4lnoA/7//gUANMJ4AJKYaaU9EnpkBTwpkyGg2o0yNGhoMAANAAGTQAABoBqYIAKm00
gGgAA0Mg0MAANAAGTQAABoBKaEBTINJpPQowA0EehB6JhJ7/rnUgLCBDZ+XLlvYOGhZv77lGkimoJF7LwojE54XgoQM9pbF1oDdT
RPJAa7ZZ0gIBoE2Ikz+VAZQFnyQhcslexGedapAXzKW5R4FJTAOBicrXVyYQdah5DAiyAcJbCGVWbSbCsdxWZnnhAjYYGSCiJN4D
TN1ybVhMlGl96LKM+OU7RmSSuqJG6lQ0qxNYFO1MlURHTQz7LljlNSzRjXo17NYQJLUDziIzWlxyFbBd99UHHvsxPgzoUS3ISnnu
3OdiEdp6MOGajaOC8SmZrTeR/flDN90N6Kser/ZIXrIeW7qxG3jHiwhFfBj4oLYq5BgMKkOm99PfZjVGUBoj/vP+OMar9ILWY7/8
zH41cZARZDbI3DuPo5WOY26Z5L2KqJLeabmeI+0SjoJrrVTNQ6duDF7pFOVsJYdFDNPZQvnKczqsVMmM9Y3byu92qaotS3lXJy5m
/Oo99JyX5UN/JYCwlwpxma5yQh6YcjcH37OiQl7nNaDAmKrmwtFbwVSdeCIHF/7iECTEdo7Qg5KfchW48+qCuQ4H2YjRpYdcUaLp
JyXaqLOWZ9NjQDJdCb0joWu/UOydpbjL574fp9UF0FqIgsPV+L0F34cuxR7F7UVEFZCGZ4Ca1jrMEUUD0ixMSk8lqBEJIKlJFVqS
8Dol9tkl+CpqqlZBBIHBpjAgVOAJJD57oUdijTPlTPA7NrqO11tosV9FJttbXcMQMblCL12ZOAgiOrIKFjObwjw0lHGdDttYwJ3p
juwzXnOGZW4b2N1aFbDEjQErbV3W1nSJTjxrMwmu/p7h6cE+dx3Jiefm/Bhe8iumYWYKHuk5hJy8SiVGgscBcL401EuBkvCbSb7Q
USgrwuN4oJTYGwJxaLQZvjwdtTW72sRoa2ZuoiWo1b7jT9F3iQxckQdTIEM7eB81d77IGRIgEkHOKLbyAb0J03NqkhpobF/8XckU
4UJCjKTRAA==
EOF
}



drop_crossystem_sh() {

    # this weird space replacement is used because "read" has odd behaviour with spaces and newlines
    # i don't need to worry about the jank because crossystem will never have user controlled data

    vals=$(sed "s/ /THIS_IS_A_SPACE_DUMBASS/g" <<<"$(crossystem_values)")
    raw_crossystem_sh | sed -e "s/#__SED_REPLACEME_CROSSYSTEM_VALUES#/$(sed_escape "$vals")/g" | sed -e "s/THIS_IS_A_SPACE_DUMBASS/ /g" >"$ROOT/usr/bin/crossystem"
    chmod 777 "$ROOT/usr/bin/crossystem"
}
drop_pollen() {
    mkdir -p "$ROOT/etc/opt/chrome/policies/managed"
    raw_pollen >$ROOT/etc/opt/chrome/policies/managed/policy.json
    chmod 777 "$ROOT/etc/opt/chrome/policies/managed/policy.json"

}

escape() {
    case $1 in
    '' | *[!0-9]*) echo -n "\"$1\"" ;;
    *) echo -n "$1" ;;
    esac
}

crossystem_values() {
    readarray -t csys_lines <<<"$(csys)"
    for element in "${csys_lines[@]}"; do
        line_stripped=$(echo "$element" | sed -e "s/#.*//g" | sed -e 's/ .*=/=/g')
        # sed 1: cuts out all chars after the #
        # sed 2: cuts out all spaces before =
        IFS='=' read -r -a pair <<<"$line_stripped"

        key=${pair[0]}
        # cut out all characters after an instance of 2 spaces in a row
        val="$(echo ${pair[1]} | sed -e 's/  .*//g')"
        if [ "$key" == "devsw_cur" ]; then
            val=0
        fi
        if [ "$key" == "devsw_boot" ]; then
            val=0
        fi
        if [ "$key" == "mainfw_type" ]; then
            val="normal"
        fi
        if [ "$key" == "mainfw_act" ]; then
            val="A"
        fi
        if [ "$key" == "cros_debug" ]; then
            val=1
        fi
        if [ "$key" == "dev_boot_legacy" ]; then
            val=0
        fi
        if [ "$key" == "dev_boot_signed_only" ]; then
            val=0
        fi
        if [ "$key" == "dev_boot_usb" ]; then
            val=0
        fi
        if [ "$key" == "dev_default_boot" ]; then
            val="disk"
        fi
        if [ "$key" == "dev_enable_udc" ]; then
            val=0
        fi
        if [ "$key" == "alt_os_enabled" ]; then
            val=0
        fi
        if [ "$key" == "recoverysw_boot" ]; then
            val=0
        fi
        if [ "$key" == "recoverysw_cur" ]; then
            val=0
        fi
        echo "$key=$(escape "$val")"
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

: "this is essentially just wax for fakemurk"
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
drop_boot_populator() {
    base64 -d <<-EOF | bunzip2 -dc >"$ROOT/sbin/crossystem_boot_populator.sh"
QlpoOTFBWSZTWRuAdLsABJ5fgHxQfv////////6////+YEg/A+26B0SoDvVjZmob32943ntj7vd1r171kSqtbXcxezV0+enzvqVF
833J7Pd7bls77ejWO9Tsvpvddyo3snGhGzTruOtdc3bpHS7GGzT22u717zWs97ddPvu96qk+vW7XrbenryqNZVPM+A83tfe695Vt
73rtve2L7r7281vm7oMfd75S28+3vYfR94+6O1cp9Hdr3sb1L3r3uvVOanu5pwnKnvWa1728597NnuKPu73m7vZde9z770c7t7vd
8rtVUE+CqYAmAIxMAjCMjTE0wCYgkmVP1TNI0D1NqeUxVMAAAmAAEwAAmRpoRSepQekAAAYqmATAmmTCYDIATCaYmjIJU/1NTKQA
AxMBVU/ATAaAATABMCZMBNAqlGIM0gADApNMTJk0ATEMjTTUzUxpoGUwJlU9TT1PRADRiADTUEAmQABNMmAAmExNDRoAhBMANGk5
BA8iCiKhUERICiIogBFEcG+WIAsK0WhU4URiIwgBA4QiFAP+ukTNH2V7/n7r+/Fo/5/2hA/IxkB9X84lSQKEfSDRageiKvwOUhxq
NI/pQXVasB8FPyIWISBGvCXv3ax1Sy7D3RsYVPEzX7+5g/QappkIBJKLACiBHEXD/imkIlAW5lN52xCuZL/j7UrbXoHuPs/c+/8P
Omzu/H9bX+XPzbQpyv/fl8TfT8Itf+fp7dNSqbf4STq35Gr9bFdnz/36yaBEQ9hVYLIXNfyg1YvxX/1JPmT+f+Mf5y03Uf12v/99
o5aImM5vlFDniR20hDRP0ejnlVpoLGlMLoBeDVR6NU+v5Mro/YDm+EEH+P52l63wjul1htf4idYyS0XM4/zVt7o9VzoLfSkCvuhZ
XbdKCpqbWxrWI12ObDXwz++tmq6laT0KWWzL192XP1Ejr3MZit1cj2/ZDt/pTm/wNLqKmDR0PfINpv/5RN2QB23MDG1uM7S/wlN8
p1jy18eui0OLHSdSyBdaPmAAiBHQE6wfnKUgAAUQiIi1kD6ED7/wuItpDFKRRAcWpbwUEdKIjAtRCkKJ+IKlqKvaz8hsl7K6gP9S
hv+HXlAkPusYCx2h9FIEKg2JH1MIWgCmKBIhUgdIY86Fj+8f6VG2rnEpz7AB8gBblieUUhloC4ClIx1bKTFB5s4y1qRJgklSy1Gg
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
UogIof/F3JFOFCQG4B0uwA==
EOF
    chmod 777 "$ROOT/sbin/crossystem_boot_populator.sh"
}

drop_image_patcher(){
  local path=$ROOT/sbin/image_patcher.sh
  echo "$(< $0)"> $path
  chmod 777 $path
}

patch_root() {
    disable_autoupdates
    drop_cr50_update
    drop_pollen
    drop_startup_patch
    echo "Dropping boot populator"
    drop_boot_populator
    echo "Installing mush shell"
    drop_mush
    echo "Dropping fakemurk daemon"
    drop_daemon
    echo "Staging populator"
    >$ROOT/population_required
    >$ROOT/reco_patched
    echo "Preparing ausystem"
    drop_ssd_util
    drop_image_patcher
}

# https://chromium.googlesource.com/chromiumos/docs/+/main/lsb-release.md
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

murkmod_patch_root() {
    echo "Murkmod-ing root"
    # check if lsb-release CHROMEOS_RELEASE_CHROME_MILESTONE is 118 for compat
    local milestone=$(lsbval CHROMEOS_RELEASE_CHROME_MILESTONE $ROOT/etc/lsb-release)
    if [ "$milestone" -eq "118" ]; then
        echo "Detected v118, using new chromeos_startup"
        move_bin "$ROOT/sbin/chromeos_startup"
        install "chromeos_startup_v118.sh" $ROOT/sbin/chromeos_startup
    else
        install "chromeos_startup.sh" $ROOT/sbin/chromeos_startup.sh
    fi
    install "fakemurk-daemon.sh" $ROOT/sbin/fakemurk-daemon.sh
    install "mush.sh" $ROOT/usr/bin/crosh
    install "pre-startup.conf" $ROOT/etc/init/pre-startup.conf
    install "cr50-update.conf" $ROOT/etc/init/cr50-update.conf
    install "ssd_util.sh" $ROOT/usr/share/vboot/bin/ssd_util.sh
    install "image_patcher.sh" $ROOT/sbin/image_patcher.sh
    chmod 777 $ROOT/sbin/fakemurk-daemon.sh $ROOT/sbin/chromeos_startup.sh $ROOT/usr/bin/crosh $ROOT/usr/share/vboot/bin/ssd_util.sh $ROOT/sbin/image_patcher.sh
    chmod 755 $ROOT/sbin/chromeos_startup # whoops
}

main() {
  traps
  ascii_info
  configure_binaries
  echo $SSD_UTIL

  if [ -z $1 ] || [ ! -f $1 ]; then
    echo "\"$1\" isn't a real file, dipshit! You need to pass the path to the recovery image."
    exit
  fi
  if [ -z $2 ]; then
    echo "Not using a custom bootsplash."
    local bootsplash=0
  elif [ ! -f $2 ]; then
    echo "file $2 not found for custom bootsplash"
    local bootsplash=0
  else
    echo "Using custom bootsplash $2"
    local bootsplash=$2
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
  murkmod_patch_root

  if [ $bootsplash -ne 0 ]; then
    echo "Adding custom bootsplash..."
    for i in $(seq -f "%05g" 0 30) do
      cp -v $bootsplash $ROOT/usr/share/chromeos-assets/images_100_percent/boot_splash_frame${i}.png
    done
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
