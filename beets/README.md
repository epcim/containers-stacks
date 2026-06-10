# Beets

Music library manager and tagger ([linuxserver/beets](https://github.com/linuxserver/docker-beets)).

## URL

| | URL |
|--|-----|
| **Web UI** | `https://beets.${LOCAL_DOMAIN}` |

## Deployment

Deployed via Dockhand.

### Environment Variables (`.env` defaults)

| Variable | Default | Description |
|----------|---------|-------------|
| `LOCAL_DOMAIN` | *(from config.env)* | Shared -- routing domain for Traefik Host rules |
| `TZ` | `Europe/Prague` | Shared -- container timezone |
| `PUID` | `1031` | Synology user ID for file permissions (dedicated media user) |
| `PGID` | `100` | Shared -- Synology group ID for file permissions |

### Secrets

No secrets required.

## Volumes

| Host / Volume | Container Path | Purpose |
|---------------|---------------|---------|
| `beets-config` | `/config` | Beets configuration and database |
| `/volume1/Media/music` | `/music` | Music library (Synology shared folder) |

## DNS + Reverse Proxy

1. DSM reverse proxy: `beets.${LOCAL_DOMAIN}:443` -> `localhost:9980`
2. DNS: `beets.${LOCAL_DOMAIN}` -> `${NAS_IP}`
