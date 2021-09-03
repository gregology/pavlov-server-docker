FROM ubuntu:20.04

# Install prerequisites
RUN apt update && apt install -y gdb curl lib32gcc1 libc++-dev unzip

# Create steam user
RUN useradd -m -N -s /bin/bash -u 1000 -p 'password' steam
USER steam

# Install Steam
RUN mkdir /home/steam/Steam && cd /home/steam/Steam && curl -sqL "https://steamcdn-a.akamaihd.net/client/installer/steamcmd_linux.tar.gz" | tar zxvf -

# Host Pavlov
RUN /home/steam/Steam/steamcmd.sh +login anonymous +force_install_dir /home/steam/pavlovserver +app_update 622970 +exit && chmod +x /home/steam/pavlovserver/PavlovServer.sh

# Start Steam
RUN /home/steam/Steam/steamcmd.sh +login anonymous +app_update 1007 +quit
RUN mkdir -p /home/steam/.steam/sdk64
RUN cp /home/steam/Steam/steamapps/common/Steamworks\ SDK\ Redist/linux64/steamclient.so /home/steam/.steam/sdk64/steamclient.so
RUN cp /home/steam/Steam/steamapps/common/Steamworks\ SDK\ Redist/linux64/steamclient.so /home/steam/pavlovserver/Pavlov/Binaries/Linux/steamclient.so

CMD ["/home/steam/pavlovserver/PavlovServer.sh"]
