#
# Dockerfile for a Pavlov VR Dedicated Server (Ubuntu 22.04)
#
FROM ubuntu:22.04

# Avoid interactive prompts during install
ENV DEBIAN_FRONTEND=noninteractive
ENV PORT=7777

# 1) Install necessary dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    gdb curl wget lib32gcc-s1 libc++-dev unzip nano cron ca-certificates locales \
    # gosu is no longer strictly needed if we won't do user switching at runtime
    && rm -rf /var/lib/apt/lists/*

# 2) Configure locale
RUN locale-gen en_US.UTF-8 \
    && update-locale LANG=en_US.UTF-8 \
    && export LANG=en_US.UTF-8

ENV LANG=en_US.UTF-8
ENV LANGUAGE=en_US:en
ENV LC_ALL=en_US.UTF-8

# 3) Create 'steam' group and 'steam' user
RUN groupadd --gid 1000 steam \
    && useradd --create-home --no-log-init --shell /bin/bash --uid 1000 --gid 1000 steam

# 4) Install SteamCMD (as root)
WORKDIR /home/steam
RUN mkdir -p /home/steam/Steam \
    && cd /home/steam/Steam \
    && wget --progress=dot:giga --no-check-certificate \
       "https://steamcdn-a.akamaihd.net/client/installer/steamcmd_linux.tar.gz" \
    && tar -xvzf steamcmd_linux.tar.gz \
    && rm steamcmd_linux.tar.gz

# 5) Install Pavlov server + Steamworks Redist (still as root)
ENV STEAMCMD_DIR="/home/steam/Steam"
RUN $STEAMCMD_DIR/steamcmd.sh \
      +force_install_dir /home/steam/pavlovserver \
      +login anonymous \
      +app_update 622970 -beta default \
      +quit \
    && $STEAMCMD_DIR/steamcmd.sh \
      +login anonymous \
      +app_update 1007 \
      +quit

# 6) Copy steamclient.so
RUN mkdir -p /home/steam/.steam/sdk64 \
    && cp "/home/steam/Steam/steamapps/common/Steamworks SDK Redist/linux64/steamclient.so" "/home/steam/.steam/sdk64/steamclient.so" \
    && cp "/home/steam/Steam/steamapps/common/Steamworks SDK Redist/linux64/steamclient.so" "/home/steam/pavlovserver/Pavlov/Binaries/Linux/steamclient.so"

# 7) Fix libc++ symlink
RUN rm /usr/lib/x86_64-linux-gnu/libc++.so \
    && ln -s /usr/lib/x86_64-linux-gnu/libc++.so.1 /usr/lib/x86_64-linux-gnu/libc++.so

# 8) Give steam ownership of /home/steam
RUN chown -R steam:steam /home/steam

# 9) Switch to steam user for the final image
USER steam
WORKDIR /home/steam

# Make sure the PavlovServer script is executable
RUN chmod +x /home/steam/pavlovserver/PavlovServer.sh

# Copy in start/update scripts and entrypoint
COPY --chown=steam:steam pavlov_start.sh /home/steam/pavlov_start.sh
COPY --chown=steam:steam pavlov_update.sh /home/steam/pavlov_update.sh
COPY --chown=steam:steam entrypoint.sh /home/steam/entrypoint.sh
RUN chmod +x /home/steam/pavlov_start.sh /home/steam/pavlov_update.sh /home/steam/entrypoint.sh

# (Optional) Create logs dir
RUN mkdir -p /home/steam/pavlov_update_logs && touch /home/steam/pavlov_update_logs/pavlov_update.sh.log

# Expose port
EXPOSE 7777/udp

ENTRYPOINT ["/home/steam/entrypoint.sh"]
