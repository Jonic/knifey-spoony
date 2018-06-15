#!/bin/bash

ZIP_NAME="knifey-spoony.zip"

clear

echo " __ _  __ _  __  ____  ____  _  _    ____  ____   __    __   __ _  _  _ "
echo "(  / )(  ( \(  )(  __)(  __)( \/ )  / ___)(  _ \ /  \  /  \ (  ( \( \/ )"
echo " )  ( /    / )(  ) _)  ) _)  )  /   \___ \ ) __/(  O )(  O )/    / )  / "
echo "(__\_)\_)__)(__)(__)  (____)(__/    (____/(__)   \__/  \__/ \_)__)(__/  "
echo ""

if [ -f $ZIP_NAME ]; then
  echo "${ZIP_NAME} exists - removing..."
  rm $ZIP_NAME
  echo " - Done!"
  echo ""
fi

echo "Creating: ${ZIP_NAME}"
zip $ZIP_NAME ./index.html ./knifey-spoony.js ./web/**/*
echo ""
echo "All done!"
echo ""
open .
exit 0
