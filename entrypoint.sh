#!/bin/bash
set -uo pipefail

# --- Constants ---
STEAMCMD="/home/steam/steamcmd/steamcmd.sh"
INSTALL_DIR="/home/steam/pavlovserver"
CONFIG_DIR="${INSTALL_DIR}/Pavlov/Saved/Config"
GAME_INI="${CONFIG_DIR}/LinuxServer/Game.ini"
RCON_SETTINGS="${CONFIG_DIR}/RconSettings.txt"
SERVER_BINARY="${INSTALL_DIR}/PavlovServer.sh"

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*"
}

update_server() {
    if [ "${SKIP_UPDATE}" = "true" ]; then
        log "Skipping server update (SKIP_UPDATE=true)"
        return
    fi

    log "Updating Pavlov server (branch: ${BETA_BRANCH})..."
    "${STEAMCMD}" \
        +force_install_dir "${INSTALL_DIR}" \
        +login anonymous \
        +app_update 622970 -beta "${BETA_BRANCH}" validate \
        +quit || log "WARNING: SteamCMD exited with non-zero status (this may be normal)"

    log "Updating Steamworks SDK..."
    "${STEAMCMD}" \
        +login anonymous \
        +app_update 1007 \
        +quit || log "WARNING: SteamCMD exited with non-zero status (this may be normal)"

    # Find and copy steamclient.so to both required locations
    local steamclient_src=""
    for candidate in \
        "/home/steam/steamcmd/linux64/steamclient.so" \
        "/home/steam/Steam/steamapps/common/Steamworks SDK Redist/linux64/steamclient.so"; do
        if [ -f "${candidate}" ]; then
            steamclient_src="${candidate}"
            break
        fi
    done

    if [ -n "${steamclient_src}" ]; then
        mkdir -p /home/steam/.steam/sdk64
        cp "${steamclient_src}" /home/steam/.steam/sdk64/steamclient.so
        cp "${steamclient_src}" "${INSTALL_DIR}/Pavlov/Binaries/Linux/steamclient.so"
        log "Copied steamclient.so from ${steamclient_src}"
    else
        log "WARNING: steamclient.so not found — server may not start correctly"
    fi

    chmod +x "${SERVER_BINARY}" 2>/dev/null || true
    log "Server update complete"
}

generate_game_ini() {
    if [ -f "${GAME_INI}" ]; then
        log "Using existing Game.ini"
        return
    fi

    if [ -z "${API_KEY}" ]; then
        log "WARNING: API_KEY is not set — server will not appear in the server browser"
        log "         See README.md for instructions on obtaining an API key"
    fi

    log "Generating Game.ini from environment variables..."

    cat > "${GAME_INI}" <<EOF
[/Script/Pavlov.DedicatedServer]
bEnabled=true
ServerName="${SERVER_NAME}"
MaxPlayers=${MAX_PLAYERS}
ApiKey="${API_KEY}"
bSecured=${SECURED}
bCustomServer=${CUSTOM_SERVER}
bVerboseLogging=${VERBOSE_LOGGING}
bCompetitive=${COMPETITIVE}
bWhitelist=${WHITELIST}
RefreshListTime=${REFRESH_LIST_TIME}
LimitedAmmoType=${LIMITED_AMMO_TYPE}
TickRate=${TICK_RATE}
TimeLimit=${TIME_LIMIT}
AFKTimeLimit=${AFK_TIME_LIMIT}
EOF

    if [ -n "${SERVER_PASSWORD}" ]; then
        echo "Password=${SERVER_PASSWORD}" >> "${GAME_INI}"
    fi

    if [ -n "${BALANCE_TABLE_URL}" ]; then
        echo "BalanceTableURL=${BALANCE_TABLE_URL}" >> "${GAME_INI}"
    fi

    # Parse semicolon-separated map rotation entries
    IFS=';' read -ra MAPS <<< "${MAP_ROTATION}"
    for map in "${MAPS[@]}"; do
        map=$(echo "${map}" | xargs) # trim whitespace
        if [ -n "${map}" ]; then
            echo "MapRotation=${map}" >> "${GAME_INI}"
        fi
    done

    if [ -n "${ADDITIONAL_GAME_INI}" ]; then
        echo -e "${ADDITIONAL_GAME_INI}" >> "${GAME_INI}"
    fi

    log "Game.ini generated"
}

generate_rcon_settings() {
    if [ -f "${RCON_SETTINGS}" ]; then
        log "Using existing RconSettings.txt"
        return
    fi

    if [ "${RCON_ENABLED}" = "true" ] && [ -n "${RCON_PASSWORD}" ]; then
        log "Generating RconSettings.txt..."
        cat > "${RCON_SETTINGS}" <<EOF
Password=${RCON_PASSWORD}
Port=${RCON_PORT}
EOF
        log "RconSettings.txt generated"
    fi
}

ensure_config_files() {
    # Create empty config files if they don't exist to prevent server errors
    touch "${CONFIG_DIR}/mods.txt" 2>/dev/null || true
    touch "${CONFIG_DIR}/blacklist.txt" 2>/dev/null || true
    touch "${CONFIG_DIR}/whitelist.txt" 2>/dev/null || true
}

shutdown_server() {
    log "Received shutdown signal, stopping server..."
    if [ -n "${SERVER_PID:-}" ]; then
        kill -TERM "${SERVER_PID}" 2>/dev/null
        wait "${SERVER_PID}" 2>/dev/null
    fi
    log "Server stopped"
    exit 0
}

# --- Main ---

trap shutdown_server SIGTERM SIGINT

log "=== Pavlov VR Dedicated Server ==="
log "Branch: ${BETA_BRANCH} | Port: ${GAME_PORT} | Server: ${SERVER_NAME}"

update_server
generate_game_ini
generate_rcon_settings
ensure_config_files

log "Starting Pavlov server on port ${GAME_PORT}..."
"${SERVER_BINARY}" -PORT="${GAME_PORT}" "$@" &
SERVER_PID=$!
wait "${SERVER_PID}"
