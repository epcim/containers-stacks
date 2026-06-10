# Navidrome

Lightweight, Subsonic-compatible music streaming server ([deluan/navidrome](https://github.com/navidrome/navidrome)).

Works with Subsonic-compatible clients including Amperfy (iOS), Submariner (macOS),
DSub (Android), Sonixd, and many others.

## URL

| | URL |
|--|-----|
| **Web UI** | `https://navidrome.${LOCAL_DOMAIN}` |
| **Subsonic API** | `https://navidrome.${LOCAL_DOMAIN}/rest` |

## Deployment

Deployed via Dockhand.

### Environment Variables (`.env` defaults)

| Variable | Default | Description |
|----------|---------|-------------|
| `LOCAL_DOMAIN` | *(from config.env)* | Shared -- routing domain for Traefik Host rules |
| `TZ` | `Europe/Prague` | Shared -- container timezone |
| `PUID` | `1026` | Shared -- Synology user ID |
| `PGID` | `100` | Shared -- Synology group ID |
| `ND_SCANSCHEDULE` | `1h` | How often to scan music library for changes |
| `ND_LOGLEVEL` | `info` | Log verbosity (`error`, `warn`, `info`, `debug`, `trace`) |
| `ND_SESSIONTIMEOUT` | `24h` | Web session timeout |
| `ND_ENABLETRANSCODINGCONFIG` | `true` | Allow configuring transcoding in the UI |
| `ND_ENABLESHARING` | `false` | Enable public sharing links |

### Secrets

No secrets required. Admin account is created on first login via the web UI.

## Volumes

| Host / Volume | Container Path | Purpose |
|---------------|---------------|---------|
| `navidrome-data` | `/data` | Database, cache, transcoding config |
| `/volume1/Media/music` | `/music` | Music library (read-only) |

## First-Time Setup

1. Open `https://navidrome.${LOCAL_DOMAIN}`
2. Create the admin account (first user to register becomes admin)
3. Navidrome automatically scans `/music` and indexes your library

## Client Configuration (Amperfy / Subsonic)

| Setting | Value |
|---------|-------|
| Server URL | `https://navidrome.${LOCAL_DOMAIN}` |
| Username | *(your Navidrome account)* |
| Password | *(your Navidrome password)* |

Navidrome implements the full Subsonic API. No special API key needed --
clients authenticate with username/password.

## DNS + Reverse Proxy

1. DSM reverse proxy: `navidrome.${LOCAL_DOMAIN}:443` -> `localhost:9980`
2. DNS: `navidrome.${LOCAL_DOMAIN}` -> `${NAS_IP}`
