#!/bin/bash
set -e

echo "=== Beginning Pavlov VR update: $(date) ==="

echo "Updating Pavlov game files..."
/home/steam/Steam/steamcmd.sh \
  +force_install_dir "/home/steam/pavlovserver" \
  +login anonymous \
  +app_update 622970 -beta default \
  +quit

echo "Updating Steamworks SDK Redist..."
/home/steam/Steam/steamcmd.sh \
  +login anonymous \
  +app_update 1007 \
  +quit

echo "Copying steamclient.so..."
cp "/home/steam/Steam/steamapps/common/Steamworks SDK Redist/linux64/steamclient.so" "/home/steam/.steam/sdk64/steamclient.so"
cp "/home/steam/Steam/steamapps/common/Steamworks SDK Redist/linux64/steamclient.so" "/home/steam/pavlovserver/Pavlov/Binaries/Linux/steamclient.so"

echo "=== Pavlov VR update finished: $(date) ==="
