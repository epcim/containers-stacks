# Gonic

Lightweight Subsonic-compatible music streaming server ([sentriz/gonic](https://github.com/sentriz/gonic)).

Scans multiple music directories (FLAC, MP3, AAC, OGG, DSD) and serves
via Subsonic API. Works with Amperfy (iOS), DSub (Android), Sonixd, etc.

## URL

| | URL |
|--|-----|
| **Web UI** | `https://gonic.${LOCAL_DOMAIN}` |
| **Subsonic API** | `https://gonic.${LOCAL_DOMAIN}/rest` |

## Deployment

Deployed via Dockhand.

### Environment Variables (`.env` defaults)

| Variable | Default | Description |
|----------|---------|-------------|
| `LOCAL_DOMAIN` | *(from config.env)* | Shared -- routing domain |
| `TZ` | `Europe/Prague` | Shared -- timezone |

### Secrets

No secrets required. Admin account created on first web access.

## Music Library

Gonic scans `/music` which contains all format subdirectories:

```
/volume1/Media/music/          → /music (read-only)
├── aac/
├── flac/
├── mp3/
├── ogg/
└── dsd/
```

Gonic auto-scans every 180 seconds for new files.

## Volumes

| Host / Volume | Container Path | Purpose |
|---------------|---------------|---------|
| `gonic-data` | `/data` | Database, cache, playlists |
| `/volume1/Media/music` | `/music` | Music library (read-only) |
| `/volume1/Media/podcasts` | `/podcasts` | Podcasts (read-only) |

## First-Time Setup

1. Open `https://gonic.${LOCAL_DOMAIN}`
2. Create admin account (first user becomes admin)
3. Gonic scans `/music` automatically

## Client Configuration

| Setting | Value |
|---------|-------|
| Server URL | `https://gonic.${LOCAL_DOMAIN}` |
| Username | *(your gonic account)* |
| Password | *(your gonic password)* |

## DNS + Reverse Proxy

1. DSM reverse proxy: `gonic.${LOCAL_DOMAIN}:443` -> `localhost:9980`
2. DNS: `gonic.${LOCAL_DOMAIN}` -> `${NAS_IP}`
