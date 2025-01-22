#!/bin/bash
set -e

echo "=== Beginning Pavlov VR update: $(date) ==="

# Run the update script as root
/home/steam/pavlov_update.sh

echo "Fixing ownership and permissions..."
chown -R steam:steam /home/steam/pavlovserver

echo "=== Pavlov VR update finished: $(date) ==="

# Start the server as 'steam' user using gosu
exec gosu steam /home/steam/pavlov_start.sh
