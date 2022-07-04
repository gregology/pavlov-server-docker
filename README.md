# Pavlov Server

This container updates Pavlov VR and Steam on start.

```
docker run --name pavlov -d \
  -p 7777:7777/udp \
  -p 8177:8177/udp \
  -v $HOME/pavlov/Game.ini:/home/steam/pavlovserver/Pavlov/Saved/Config/LinuxServer/Game.ini \
  -v $HOME/pavlov/mods.txt:/home/steam/pavlovserver/Pavlov/Saved/Config/mods.txt \
  -v $HOME/pavlov/blacklist.txt:/home/steam/pavlovserver/Pavlov/Saved/Config/blacklist.txt \ #optional
  -v $HOME/pavlov/whitelist.txt:/home/steam/pavlovserver/Pavlov/Saved/Config/whitelist.txt \ #optional
  -e PORT=7777 \ # optional defaults to 7777
  --restart unless-stopped \
  gregology/pavlov-server:latest
```

The second port is always 400 higher than the defined port. If you use port 7000 you will also need to forward port 7400. Refer to the [docs](http://wiki.pavlov-vr.com/index.php?title=Dedicated_server#Firewall.2FPort_forwarding) for more infomation on ports and port forwarding.

Your game should appear on the [PC Servers List](https://pavlovhorde.com/pcServers/) & [pablub custom serbers](https://pablub.xyz/).

### Sample Game.ini
```
[/Script/Pavlov.DedicatedServer]
bEnabled=true
ServerName=MyAwesomeServer
bSecured=true
bCustomServer=true
LimitedAmmoType=2
TimeLimit=0
MapRotation=(MapId="UGC2443220615") # Survival Island
```
Note: MapIds starting with `UGC` are from the [Steam workshop](https://steamcommunity.com/app/555160/workshop/). Append `UGC` to the id from the url of the map you want to use.  
See the [docs](http://wiki.pavlov-vr.com/index.php?title=Dedicated_server#Configuring_Game.ini) for more game configuration options.

### Sample mods.txt
```
76561198057346920 # BabyArmour
```
Note: Use [Steam ID Finder](https://www.steamidfinder.com/) to look up a Steam user ID.

If you're having issues, please submit an [issue](https://github.com/gregology/pavlov-server-docker/issues) and ping me.

### Build

```
docker build -t gregology/pavlov-server:0.16 .
docker push gregology/pavlov-server:0.16
docker tag gregology/pavlov-server:0.16 gregology/pavlov-server:latest
docker push gregology/pavlov-server:latest
```