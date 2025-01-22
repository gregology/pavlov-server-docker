#!/bin/bash
set -e

echo "Starting Pavlov Server on port $PORT..."
/home/steam/pavlovserver/PavlovServer.sh -PORT=${PORT}
