# Pavlov Server

```
docker run --name pavlov -d \
  -p 7777:7777/udp \
  -p 8177:8177/udp \
  -v /home/user/pavlov/Game.ini:/home/steam/pavlovserver/Pavlov/Saved/Config/LinuxServer/Game.ini \
  -v /home/user/pavlov/mods.txt:/home/steam/pavlovserver/Pavlov/Saved/Config/mods.txt \
  -v /home/user/pavlov/blacklist.txt:/home/steam/pavlovserver/Pavlov/Saved/Config/blacklist.txt \ #optional
  -v /home/user/pavlov/whitelist.txt:/home/steam/pavlovserver/Pavlov/Saved/Config/whitelist.txt \ #optional
  --restart unless-stopped \
  gregology/pavlov-server:latest
```

Your game should appear on the [PC Servers List](https://pavlovhorde.com/pcServers/).

### Sample Game.ini
```
[/Script/Pavlov.DedicatedServer]
bEnabled=true
ServerName=Gregology
bSecured=true
MapRotation=(MapId="UGC2456742088")
```
Note: MapIds starting with `UGC` are from the [Steam workshop](https://steamcommunity.com/app/555160/workshop/). Append `UGC` to the id from the url of the map you want to use.  
See the [docs](http://wiki.pavlov-vr.com/index.php?title=Dedicated_server#Configuring_Game.ini) for more options

### Sample mods.txt
```
76561198057346920 # Gregology
```
Note: Use [Steam ID Finder}(https://www.steamidfinder.com/) to look up a Steam user ID
