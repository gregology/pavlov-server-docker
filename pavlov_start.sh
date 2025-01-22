#!/bin/bash
set -e

# 1) Perform update
/home/steam/pavlov_update.sh

# 2) Start the Pavlov server
#    By default uses -PORT=$PORT, which is set by ENV PORT in Dockerfile
echo "Starting Pavlov Server on port $PORT..."
/home/steam/pavlovserver/PavlovServer.sh -PORT=${PORT}
