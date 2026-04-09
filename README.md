# Pavlov VR Dedicated Server (Docker)

A lightweight Docker setup for running a Pavlov VR dedicated server. Game files are downloaded at runtime into a persistent volume (not baked into the image), so the image stays small and updates happen automatically on each container start.

Supports **PC**, **Shack (Quest)**, and their beta variants via a single image.

## Quick Start

```bash
cp .env.example .env
# Edit .env — at minimum, set API_KEY
docker compose up -d
```

The first start downloads ~2-3 GB of server files. Subsequent starts only apply updates.

### Get an API Key

An `API_KEY` is **required** for your server to appear in the server browser (mandatory since December 2024).

The official key generation site (`api-key.vankrupt.net`) is currently down. To obtain a key:

1. **Discord** — Join the [Pavlov VR Discord](https://discord.gg/pavlov-vr) and ask in `#pc-custom-servers`, or DM `davevillz`
2. **Email** — Contact `devrel@vankrupt.com`

You'll need your Steam64 ID and may need to complete SMS verification. One key supports up to ~10 servers. Generating a new key invalidates the old one.

## Server Variants

Set `BETA_BRANCH` in `.env` to choose which build to install:

| `BETA_BRANCH`  | Variant             | Max Players |
|----------------|---------------------|-------------|
| `default`      | PC stable           | 50          |
| `beta_server`  | PC beta             | 50          |
| `shack`        | Shack (Quest)       | 24          |
| `shack_beta`   | Shack (Quest) beta  | 24          |

## Configuration

### Method 1: Environment Variables (recommended)

All server settings are configured via `.env`. See [`.env.example`](.env.example) for the full list with documentation.

### Method 2: Bind-Mount Config Files (advanced)

For full control, copy files from `config/` and mount them directly. Uncomment the volume lines in `docker-compose.yml`:

```yaml
volumes:
  - ./config/Game.ini:/home/steam/pavlovserver/Pavlov/Saved/Config/LinuxServer/Game.ini
  - ./config/RconSettings.txt:/home/steam/pavlovserver/Pavlov/Saved/Config/RconSettings.txt
  - ./config/mods.txt:/home/steam/pavlovserver/Pavlov/Saved/Config/mods.txt
```

When a config file already exists (from a bind mount or a previous run), the entrypoint will **not** overwrite it. Delete the file and restart to regenerate from env vars.

## Ports

| Port | Protocol | Purpose |
|------|----------|---------|
| `GAME_PORT` (default 7777) | UDP | Game traffic |
| `GAME_PORT + 400` (default 8177) | UDP | Secondary game port |
| `RCON_PORT` (default 9100) | TCP | Remote console |

All three ports must be forwarded on your firewall/router. If you change `GAME_PORT`, update `SECONDARY_PORT` in `.env` to match (`GAME_PORT + 400`).

For Shack servers with custom maps, TCP on both game ports must also be open.

## Volumes

| Volume | Purpose |
|--------|---------|
| `pavlov-data` | Server files, configs, downloaded maps. Persists across container rebuilds. |
| `pavlov-tmp` | Temp storage for map downloads. Prevents OOM from large maps on tmpfs. |

To back up server data: `docker run --rm -v pavlov-data:/data -v $(pwd):/backup alpine tar czf /backup/pavlov-backup.tar.gz /data`

To force a full re-download: `docker volume rm pavlov-data` then restart.

## Map Rotation

Maps use [mod.io](https://mod.io/g/pavlov) resource IDs with a `UGC` prefix. To find a map ID, go to the map's mod.io page and use `UGC` + the resource ID (shown in the URL or sidebar).

In `.env`, separate multiple maps with semicolons:

```bash
MAP_ROTATION=(MapId="datacenter", GameMode="DM");(MapId="UGC2773760", GameMode="TDM")
```

Available game modes: `DM`, `TDM`, `SND`, `KOTH`, `GUN`, `OITC`, `TANKTDM`, `TTT`, `TTTclassic`, `WW2GUN`, `ZWV`, `HIDE`, `INFECTION`, `PUSH`, `PH`

## Administration

### RCON

Set `RCON_PASSWORD` in `.env` to enable remote console access on `RCON_PORT` (default 9100). RCON allows you to run commands like switching maps, kicking players, and checking server status.

### Moderators

Add Steam64 IDs to `mods.txt` (one per line) to grant in-game admin privileges. Use [steamidfinder.com](https://www.steamidfinder.com/) to look up IDs.

### Bans and Whitelist

- `blacklist.txt` — Steam64 IDs of banned players
- `whitelist.txt` — Steam64 IDs of allowed players (only active when `WHITELIST=true`)

## Running Multiple Servers

Run additional servers with separate project names and env files:

```bash
cp .env .env.server2
# Edit .env.server2 — change SERVER_NAME, GAME_PORT, SECONDARY_PORT, RCON_PORT
docker compose -p pavlov-server2 --env-file .env.server2 up -d
```

## Troubleshooting

**Server doesn't appear in browser** — Ensure `API_KEY` is set. See [Get an API Key](#get-an-api-key) above.

**Out of memory downloading maps** — Large custom maps download to `/tmp`. The `pavlov-tmp` volume in docker-compose prevents this. If running with `docker run`, add `-v pavlov-tmp:/tmp`.

**Permission errors on mounted config files** — Mounted files must be readable by UID 1000 (the `steam` user inside the container).

**"steamclient.so: cannot open shared object file"** — The entrypoint copies this automatically. If it fails, check the container logs for the WARNING message.

**Force full server re-download** — `docker volume rm pavlov-data && docker compose up -d`

## Performance

Pavlov server is functionally single-threaded. More CPUs only help when running multiple servers. Higher clock speed = better per-server performance.

| Scenario | CPU % | Memory |
|----------|-------|--------|
| Idle (0 players) | ~69% | ~710 MB |
| 8 players | ~118% | ~916 MB |
| 16 players | ~141% | ~1 GB |

A server with 1 GB of RAM can run a small map with a few players. [Oracle's free tier](https://www.oracle.com/cloud/free/) VMs work for small servers.

## Building

```bash
docker compose build
```

Or manually:

```bash
docker build -t gregology/pavlov-server:latest .
```

## Links

- [Pavlov VR Wiki — Dedicated Server Setup](https://pavlovwiki.com/index.php/Setting_up_a_dedicated_server)
- [Pavlov VR Wiki — Troubleshooting Servers](https://pavlovwiki.com/index.php/Troubleshooting_Servers)
- [mod.io — Pavlov VR Maps](https://mod.io/g/pavlov)
- [Pavlov VR Discord](https://discord.gg/pavlov-vr) (for API key requests and support)
