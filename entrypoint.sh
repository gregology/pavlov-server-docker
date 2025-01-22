#!/bin/bash
set -e

echo "=== Beginning Pavlov VR update: $(date) ==="

/home/steam/pavlov_update.sh

echo "=== Pavlov VR update finished: $(date) ==="

# Start the server as 'steam' user using gosu
exec gosu steam /home/steam/pavlov_start.sh
