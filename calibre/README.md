# Calibre

Ebook library management with multiple Calibre libraries and automatic book ingestion.

## Services

| Service | Purpose |
|---------|---------|
| **calibre-beletry** | Calibre-Web reader for Beletry library (default) |
| **calibre-fiction** | Calibre-Web reader for Fiction library |
| **calibre-education** | Calibre-Web reader for Education library |
| **calibre-ingest** | Watches inbox, adds new books to correct library via `calibredb` |

## URLs

All libraries served under a single domain via Traefik path-based routing:

| Library | URL |
|---------|-----|
| **Root** | `https://calibre.${LOCAL_DOMAIN}/` (redirects to Beletry) |
| **Beletry** | `https://calibre.${LOCAL_DOMAIN}/beletry/` |
| **Fiction** | `https://calibre.${LOCAL_DOMAIN}/fiction/` |
| **Education** | `https://calibre.${LOCAL_DOMAIN}/education/` |

Uses Traefik `StripPrefix` + `X-Script-Name` header so calibre-web generates
correct links under each path. Only one DSM reverse proxy entry needed
(`calibre.${LOCAL_DOMAIN}`).

## Deployment

Deployed via Dockhand. Three calibre-web containers share the same Docker
image (layers deduplicated on disk, ~50MB RAM per instance). One ingest
sidecar watches the inbox.

### Environment Variables (`.env` defaults)

| Variable | Default | Description |
|----------|---------|-------------|
| `LOCAL_DOMAIN` | *(from config.env)* | Shared -- routing domain |
| `TZ` | `Europe/Prague` | Shared -- timezone |
| `PUID` | `1026` | Shared -- Synology user ID |
| `PGID` | `100` | Shared -- Synology group ID |
| `CALIBRE_DEFAULT_LIBRARY` | `Beletry` | Ingest: default library for unsorted books |
| `INGEST_INTERVAL` | `300` | Ingest: scan interval in seconds (5 min) |

### Secrets

No secrets required.

## Default Login (Calibre-Web)

Each instance has its own credentials. On first start:

| Field | Value |
|-------|-------|
| Username | `admin` |
| Password | `admin123` |

**Change immediately** after first login on each instance.

## Volumes

| Host / Volume | Container Path | Service | Purpose |
|---------------|---------------|---------|---------|
| `calibre-beletry-config` | `/config` | calibre-beletry | Web config |
| `calibre-fiction-config` | `/config` | calibre-fiction | Web config |
| `calibre-education-config` | `/config` | calibre-education | Web config |
| `/volume1/Media/books-text/Beletry` | `/books` | calibre-beletry | Library (ro) |
| `/volume1/Media/books-text/Fiction` | `/books` | calibre-fiction | Library (ro) |
| `/volume1/Media/books-text/Education` | `/books` | calibre-education | Library (ro) |
| `/volume1/Media/books-inbox` | `/inbox` | calibre-ingest | Drop zone |
| `/volume1/Media/books-text` | `/books-text` | calibre-ingest | All libraries (rw) |

## Book Ingestion

The `calibre-ingest` container watches `/volume1/Media/books-inbox/` every
5 minutes and processes new ebook files.

### Inbox structure

```
/volume1/Media/books-inbox/
├── book.epub                # -> Beletry (default library)
├── Fiction/
│   └── novel.epub           # -> Fiction library
├── Education/
│   └── textbook.pdf         # -> Education library
└── .failed/                 # books that failed to import
```

### Supported formats

`epub`, `pdf`, `mobi`, `azw3`, `fb2`, `djvu`, `cbz`, `cbr`, `lit`, `rtf`, `txt`

## First-Time Setup

1. **Create inbox directory** on the NAS (once):
   ```bash
   mkdir -p /volume1/Media/books-inbox
   chown 1031:100 /volume1/Media/books-inbox
   ```

2. **Deploy** and visit each URL to trigger `app.db` creation. The init
   script auto-configures the library path (`/books`) and anonymous browsing.

3. Each library directory must contain a `metadata.db` (created automatically
   by the ingest container when `calibredb add` runs for the first time)

## DNS + Reverse Proxy

Only one DSM reverse proxy entry needed:

1. DSM reverse proxy: `calibre.${LOCAL_DOMAIN}:443` -> `localhost:9980`
2. DNS: `calibre.${LOCAL_DOMAIN}` -> `${NAS_IP}` (wildcard covers this)

Traefik handles path-based routing internally:
- `/` -> redirect to `/beletry/` (priority 5)
- `/beletry/*` -> calibre-beletry (priority 10, StripPrefix + X-Script-Name)
- `/fiction/*` -> calibre-fiction (priority 10, StripPrefix + X-Script-Name)
- `/education/*` -> calibre-education (priority 10, StripPrefix + X-Script-Name)

## Future: Lightweight ingest image

The ingest container uses `linuxserver/calibre:7.28.0` (2GB+).
`Dockerfile.ingest.PLACEHOLDER` provides a lightweight Alpine alternative (~300MB).
