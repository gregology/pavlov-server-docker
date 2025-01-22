#!/bin/bash
set -e

echo "=== Beginning Pavlov VR update: $(date) ==="

# We are already user "steam", so just run the update script:
./pavlov_update.sh

echo "=== Pavlov VR update finished: $(date) ==="

# Start server (already "steam" user)
exec ./pavlov_start.sh
