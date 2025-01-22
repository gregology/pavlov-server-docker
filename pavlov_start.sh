#!/bin/bash
set -e

# Start the Pavlov server with the specified port
echo "Starting Pavlov Server on port $PORT..."
/home/steam/pavlovserver/PavlovServer.sh -PORT=${PORT}
