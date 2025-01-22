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

echo "Fixing ownership and permissions..."

# Ensure all files and directories are owned by 'steam:steam'
chown -R steam:steam /home/steam/pavlovserver

# Ensure directories have read, write, and execute permissions for the owner
find /home/steam/pavlovserver -type d -exec chmod 755 {} \;

# Ensure files have read and write permissions for the owner
find /home/steam/pavlovserver -type f -exec chmod 644 {} \;

# Specifically ensure that executable scripts have execute permissions
chmod +x /home/steam/pavlovserver/PavlovServer.sh
chmod +x /home/steam/pavlov_start.sh
chmod +x /home/steam/pavlov_update.sh

echo "=== Pavlov VR update finished: $(date) ==="
