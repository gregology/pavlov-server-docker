#
# Dockerfile for a Pavlov VR Dedicated Server (Ubuntu 22.04)
#   - Installs required packages
#   - Installs SteamCMD via wget
#   - Downloads Pavlov server files (PC non-beta by default)
#   - Copies steamclient.so
#   - Fixes libc++ symlink
#   - Exposes default port (7777/udp)
#
FROM ubuntu:22.04

# Avoid some interactive prompts during install
ENV DEBIAN_FRONTEND=noninteractive

# Optionally define a port environment variable (for Pavlov)
ENV PORT=7777

# 1) Install necessary dependencies, including ca-certificates (important for secure downloads)
RUN apt-get update && apt-get install -y --no-install-recommends \
    gdb curl wget lib32gcc-s1 libc++-dev unzip nano cron ca-certificates \
    && rm -rf /var/lib/apt/lists/*

# 2) Update CA certificates to ensure HTTPS downloads can be trusted
RUN update-ca-certificates

# 3) Create a 'steam' user with home directory
RUN groupadd --gid 1000 steam
RUN useradd --create-home --no-log-init --shell /bin/bash --uid 1000 --gid 1000 steam

# 4) Switch to 'steam' user context
USER steam
WORKDIR /home/steam

# 5) Download and install SteamCMD via wget
RUN mkdir -p /home/steam/Steam \
    && cd /home/steam/Steam \
    && wget --progress=dot:giga --no-check-certificate \
       "https://steamcdn-a.akamaihd.net/client/installer/steamcmd_linux.tar.gz" \
    && tar -xvzf steamcmd_linux.tar.gz \
    && rm steamcmd_linux.tar.gz

# Set environment var to point to SteamCMD directory
ENV STEAMCMD_DIR="/home/steam/Steam"

# 6) Install Pavlov server (PC non-beta by default; change -beta if needed)
RUN ${STEAMCMD_DIR}/steamcmd.sh \
      +force_install_dir /home/steam/pavlovserver \
      +login anonymous \
      +app_update 622970 -beta default \
      +quit

# 7) Update Steamworks SDK Redist & copy steamclient.so
RUN ${STEAMCMD_DIR}/steamcmd.sh \
      +login anonymous \
      +app_update 1007 \
      +quit \
    && mkdir -p /home/steam/.steam/sdk64 \
    && cp "/home/steam/Steam/steamapps/common/Steamworks SDK Redist/linux64/steamclient.so" "/home/steam/.steam/sdk64/steamclient.so" \
    && cp "/home/steam/Steam/steamapps/common/Steamworks SDK Redist/linux64/steamclient.so" "/home/steam/pavlovserver/Pavlov/Binaries/Linux/steamclient.so"

# 8) Switch back to root to fix libc++ symlink
USER root
# Patched issue since v29
RUN rm /usr/lib/x86_64-linux-gnu/libc++.so 
RUN ln -s /usr/lib/x86_64-linux-gnu/libc++.so.1 /usr/lib/x86_64-linux-gnu/libc++.so 

# 9) Ensure steam owns the pavlovserver folder so it can write custom maps/logs
RUN chown -R steam:steam /home/steam/pavlovserver
RUN chmod -R 755 /home/steam/pavlovserver

# 10) Switch back to steam user, adjust permissions, copy scripts
USER steam
RUN chmod +x /home/steam/pavlovserver/PavlovServer.sh

# Create necessary directories to avoid permission issues
RUN mkdir -p /home/steam/pavlovserver/Pavlov/Saved/Logs \
    && mkdir -p /home/steam/pavlovserver/Pavlov/Saved/Config/LinuxServer \
    && mkdir -p /home/steam/pavlovserver/Pavlov/Saved/maps \
    && mkdir -p /home/steam/pavlovserver/Pavlov/Saved/Config/CrashReportClient

# Copy your start/update scripts from local into container
COPY --chown=steam:steam pavlov_start.sh /home/steam/pavlov_start.sh
COPY --chown=steam:steam pavlov_update.sh /home/steam/pavlov_update.sh
RUN chmod +x /home/steam/pavlov_start.sh /home/steam/pavlov_update.sh

# (Optional) Create a logs dir for the update script
RUN mkdir -p /home/steam/pavlov_update_logs && touch /home/steam/pavlov_update_logs/pavlov_update.sh.log

# 11) Expose the server port (UDP). We'll expose 7777/udp
EXPOSE 7777/udp

# 12) Default startup command - calls our start script
CMD ["/home/steam/pavlov_start.sh"]
