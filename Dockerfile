FROM cm2network/steamcmd:root

LABEL maintainer="gregology" \
      description="Pavlov VR Dedicated Server" \
      source="https://github.com/gregology/pavlov-server-docker"

# Install Pavlov's additional dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    libc++-dev \
    gdb \
    && rm -rf /var/lib/apt/lists/*

# Fix libc++ symlink (required since Pavlov v29)
RUN rm -f /usr/lib/x86_64-linux-gnu/libc++.so \
    && ln -sf /usr/lib/x86_64-linux-gnu/libc++.so.1 /usr/lib/x86_64-linux-gnu/libc++.so

# Create directory structure Pavlov expects
RUN mkdir -p \
    /home/steam/pavlovserver/Pavlov/Saved/Config/LinuxServer \
    /home/steam/pavlovserver/Pavlov/Saved/Config/CrashReportClient \
    /home/steam/pavlovserver/Pavlov/Saved/Logs \
    /home/steam/pavlovserver/Pavlov/Saved/maps \
    /home/steam/pavlovserver/Pavlov/Binaries/Linux \
    && chown -R steam:steam /home/steam/pavlovserver

COPY --chown=steam:steam entrypoint.sh /home/steam/entrypoint.sh
RUN chmod +x /home/steam/entrypoint.sh

ENV SERVER_NAME="Pavlov VR Server" \
    MAX_PLAYERS=16 \
    API_KEY="" \
    SERVER_PASSWORD="" \
    GAME_PORT=7777 \
    RCON_ENABLED=true \
    RCON_PASSWORD="" \
    RCON_PORT=9100 \
    BETA_BRANCH=default \
    SECURED=true \
    CUSTOM_SERVER=true \
    VERBOSE_LOGGING=false \
    COMPETITIVE=false \
    WHITELIST=false \
    REFRESH_LIST_TIME=120 \
    LIMITED_AMMO_TYPE=0 \
    TICK_RATE=90 \
    TIME_LIMIT=60 \
    AFK_TIME_LIMIT=300 \
    BALANCE_TABLE_URL="" \
    MAP_ROTATION='(MapId="datacenter", GameMode="DM")' \
    ADDITIONAL_GAME_INI="" \
    SKIP_UPDATE=false

VOLUME ["/home/steam/pavlovserver", "/tmp"]

EXPOSE 7777/udp 8177/udp 9100/tcp

USER steam
WORKDIR /home/steam

ENTRYPOINT ["/home/steam/entrypoint.sh"]
