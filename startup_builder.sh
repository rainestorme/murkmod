#!/bin/bash -e

# startup_builder.sh v0.1 - written by rainestorme
# builds chromeos_startup for a given board and patch file from the given version of cros

# parameters:
# ./startup_builder.sh board /path/to/startup.patch 1xx

BRANCH="HEAD" # TODO: find correct branch
TGZ_URL="https://chromium.googlesource.com/chromiumos/platform2/+archive/$BRANCH/init.tar.gz"

SDK_VERSION="2024.05.07.65861"
SDK_FILENAME="cros-sdk-$SDK_VERSION.tar.xz"
SDK_URL="https://storage.googleapis.com/chromiumos-sdk/$SDK_FILENAME"
SDK_FOLDER="./sdk"

pushd (){
    command pushd "$@" > /dev/null 
}
popd (){
    command popd "$@" > /dev/null 
}

if [ ! -d "sdk/usr" ]; then
    echo "Cleaning old files..."
    rm -Rf sdk
    mkdir -p sdk
    pushd sdk || exit
        echo "Downloading SDK..."
        if [ "$SDK_FOLDER" != "0" ]; then
            pushd $SDK_FOLDER
                curl -Ok $SDK_URL --progress-bar
            popd
            echo "Extracting..."
            tar -xmvf $SDK_FOLDER/$SDK_FILENAME -C .
        else
            curl -Ok $SDK_URL --progress-bar
            echo "Extracting..."
            tar -xmvf $SDK_FILENAME -C .
        fi
        mkdir -p root/murkmod_tmp
        pushd root/murkmod_tmp
            echo "Downloading source tree..."
            curl -Ok $TGZ_URL --progress-bar
            echo "Extracting..."
            tar -xmf init.tar.gz -C .
        popd
    popd
fi

chroot sdk "cd /root/murkmod_tmp/startup; clang main.cc; exit;"


