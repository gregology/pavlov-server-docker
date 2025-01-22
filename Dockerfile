#
# Dockerfile for a Pavlov VR Dedicated Server (Ubuntu 22.04)
#   - Installs required packages
#   - Installs SteamCMD via wget
#   - Downloads Pavlov server files (PC non-beta by default)
#   - Copies steamclient.so
#   - Fixes libc++ symlink
#   - Sets specific UID and GID for steam user
#   - Exposes default port (7777/udp)
#
FROM ubuntu:22.04

# Avoid interactive prompts during install
ENV DEBIAN_FRONTEND=noninteractive

# Define port environment variable
ENV PORT=7777

# 1) Install necessary dependencies, including ca-certificates and gosu
RUN apt-get update && apt-get install -y --no-install-recommends \
    gdb curl wget lib32gcc-s1 libc++-dev unzip nano cron ca-certificates locales gosu \
    && rm -rf /var/lib/apt/lists/*

# 2) Configure locale to fix locale warnings
RUN locale-gen en_US.UTF-8 \
    && update-locale LANG=en_US.UTF-8 \
    && export LANG=en_US.UTF-8

ENV LANG en_US.UTF-8
ENV LANGUAGE en_US:en
ENV LC_ALL en_US.UTF-8

# 3) Create 'steam' group with GID 1000
RUN groupadd --gid 1000 steam

# 4) Create 'steam' user with UID 1000 and assign to 'steam' group
RUN useradd --create-home --no-log-init --shell /bin/bash --uid 1000 --gid 1000 steam

# 5) Switch to 'steam' user context
USER steam
WORKDIR /home/steam

# 6) Download and install SteamCMD via wget
RUN mkdir -p /home/steam/Steam \
    && cd /home/steam/Steam \
    && wget --progress=dot:giga --no-check-certificate \
       "https://steamcdn-a.akamaihd.net/client/installer/steamcmd_linux.tar.gz" \
    && tar -xvzf steamcmd_linux.tar.gz \
    && rm steamcmd_linux.tar.gz

# Set environment variable to point to SteamCMD directory
ENV STEAMCMD_DIR="/home/steam/Steam"

# 7) Install Pavlov server (PC non-beta by default; change -beta if needed)
RUN ${STEAMCMD_DIR}/steamcmd.sh \
      +force_install_dir /home/steam/pavlovserver \
      +login anonymous \
      +app_update 622970 -beta default \
      +quit

# 8) Update Steamworks SDK Redist & copy steamclient.so
RUN ${STEAMCMD_DIR}/steamcmd.sh +login anonymous +app_update 1007 +quit \
    && mkdir -p /home/steam/.steam/sdk64 \
    && cp "/home/steam/Steam/steamapps/common/Steamworks SDK Redist/linux64/steamclient.so" "/home/steam/.steam/sdk64/steamclient.so" \
    && cp "/home/steam/Steam/steamapps/common/Steamworks SDK Redist/linux64/steamclient.so" "/home/steam/pavlovserver/Pavlov/Binaries/Linux/steamclient.so"

# 9) Switch back to root to fix libc++ symlink and handle ownership
USER root

# Fix libc++ symlink
RUN rm /usr/lib/x86_64-linux-gnu/libc++.so \
    && ln -s /usr/lib/x86_64-linux-gnu/libc++.so.1 /usr/lib/x86_64-linux-gnu/libc++.so

# Ensure steam owns the pavlovserver folder so it can write custom maps/logs
RUN chown -R steam:steam /home/steam/pavlovserver

# 10) Switch back to steam user
USER steam

# Make PavlovServer script executable
RUN chmod +x /home/steam/pavlovserver/PavlovServer.sh

# Copy in your start/update scripts and entrypoint
COPY --chown=steam:steam pavlov_start.sh /home/steam/pavlov_start.sh
COPY --chown=steam:steam pavlov_update.sh /home/steam/pavlov_update.sh
COPY --chown=steam:steam entrypoint.sh /home/steam/entrypoint.sh

# Make scripts executable
RUN chmod +x /home/steam/pavlov_start.sh /home/steam/pavlov_update.sh /home/steam/entrypoint.sh

# (Optional) Create a logs dir for the update script
RUN mkdir -p /home/steam/pavlov_update_logs && touch /home/steam/pavlov_update_logs/pavlov_update.sh.log

# 11) Expose the server port (UDP)
EXPOSE 7777/udp

# 12) Set startup command
ENTRYPOINT ["/home/steam/entrypoint.sh"]
