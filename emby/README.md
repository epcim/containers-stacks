# Emby

Media server for music, audiobooks, movies, and TV ([emby/embyserver](https://emby.media/)).

## URL

| | URL |
|--|-----|
| **Web UI** | `https://emby.${LOCAL_DOMAIN}` |

## Deployment

Deployed via Dockhand.

### Environment Variables (`.env` defaults)

| Variable | Default | Description |
|----------|---------|-------------|
| `LOCAL_DOMAIN` | *(from config.env)* | Shared -- routing domain for Traefik Host rules |
| `TZ` | `Europe/Prague` | Shared -- container timezone |
| `PUID` | `1026` | Shared -- Synology user ID |
| `PGID` | `100` | Shared -- Synology group ID |

### Secrets

No secrets required for basic operation.

Emby Premiere (optional paid license) can be activated in the web UI
after setup -- no env var needed.

## Volumes

| Host / Volume | Container Path | Purpose |
|---------------|---------------|---------|
| `emby-config` | `/config` | Emby configuration, database, metadata cache |
| `/volume1/Media/music` | `/media/music` | Music library (read-only) |
| `/volume1/Media/books-audio` | `/media/audiobooks` | Audiobook library (read-only) |

### Adding more media

To mount additional media directories (movies, TV shows), add bind mounts
to `compose.yaml`:

```yaml
volumes:
  - /volume1/Media/movies:/media/movies:ro
  - /volume1/Media/tv:/media/tv:ro
```

## First-Time Setup

1. Open `https://emby.${LOCAL_DOMAIN}`
2. Follow the setup wizard:
   - Set language and create admin account
   - Add media libraries:
     - Music: `/media/music`
     - Audiobooks: `/media/audiobooks`
   - Configure remote access (not needed -- Traefik handles this)
3. Emby scans and indexes media automatically

## DNS + Reverse Proxy

1. DSM reverse proxy: `emby.${LOCAL_DOMAIN}:443` -> `localhost:9980`
2. DNS: `emby.${LOCAL_DOMAIN}` -> `${NAS_IP}`

## Notes

- Media directories are mounted **read-only**. Emby only needs read access
  for streaming. Remove `:ro` only if you need Emby to manage/delete files.
- Emby stores metadata and transcoding cache in the `emby-config` volume.
  This can grow large with many media items -- monitor disk usage.
- For hardware transcoding on Synology, you would need to pass through
  `/dev/dri` -- add under `devices:` in `compose.yaml` if needed.
