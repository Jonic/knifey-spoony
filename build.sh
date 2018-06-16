#!/bin/bash

GAME="knifey-spoony"
BIN_DIR="./${GAME}.bin"
BUILD_DIR="./build"
LINUX_DIR="${BIN_DIR}/linux"
WINDOWS_DIR="${BIN_DIR}/windows"

LINUX_FILES="${LINUX_DIR}/data.pod ${LINUX_DIR}/${GAME} ${LINUX_DIR}/${GAME}.png"
MACOS_APP="./${GAME}.bin/${GAME}.app"
WINDOWS_FILES="${WINDOWS_DIR}/data.pod ${WINDOWS_DIR}/${GAME}.exe ${WINDOWS_DIR}/SDL2.dll"
WEB_FILES="./index.html ./${GAME}.js ./web/**/*"

clear

echo " __ _  __ _  __  ____  ____  _  _    ____  ____   __    __   __ _  _  _ "
echo "(  / )(  ( \(  )(  __)(  __)( \/ )  / ___)(  _ \ /  \  /  \ (  ( \( \/ )"
echo " )  ( /    / )(  ) _)  ) _)  )  /   \___ \ ) __/(  O )(  O )/    / )  / "
echo "(__\_)\_)__)(__)(__)  (____)(__/    (____/(__)   \__/  \__/ \_)__)(__/  "
echo ""

if [ -d "./build" ]; then
  rm -rf ./build
fi

mkdir $BUILD_DIR
chmod -R 775 $BUILD_DIR

echo "Creating: ${GAME}-html.zip"
zip "${BUILD_DIR}/${GAME}-html.zip" -r $WEB_FILES
echo ""

echo "Creating: ${GAME}-linux.zip"
zip -j "${BUILD_DIR}/${GAME}-linux.zip" $LINUX_FILES
echo ""

echo "Creating: ${GAME}-macos.zip"
zip -r "${BUILD_DIR}/${GAME}-macos.zip" $MACOS_APP
echo ""

echo "Creating: ${GAME}-windows.zip"
zip -j "${BUILD_DIR}/${GAME}-windows.zip" $WINDOWS_FILES
echo ""

echo "All done!"
echo ""

open ./build

exit 0
