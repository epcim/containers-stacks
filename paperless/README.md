# Paperless-ngx

Document management system with OCR ([paperless-ngx](https://docs.paperless-ngx.com/)).

Scans, OCRs, tags, and indexes documents. Original files and archival PDF/A
copies are stored on physical drives and remain human-readable on the filesystem.

## URL

| | URL |
|--|-----|
| **Web UI** | `https://paperless.${LOCAL_DOMAIN}` |

## Deployment

Deployed via Dockhand. The stack includes:
- **paperless** -- main application (web UI, consumer, task workers)
- **paperless-db** -- PostgreSQL 16 database
- **paperless-redis** -- Redis task queue

### Environment Variables (`.env` defaults)

| Variable | Default | Description |
|----------|---------|-------------|
| `LOCAL_DOMAIN` | *(from config.env)* | Shared -- routing domain for Traefik Host rules |
| `TZ` | `Europe/Prague` | Shared -- container timezone |
| `PUID` | `1026` | Shared -- Synology user ID for file permissions |
| `PGID` | `100` | Shared -- Synology group ID for file permissions |
| `POSTGRES_DATABASE` | `paperless` | PostgreSQL database name |
| `POSTGRES_USER` | `paperless` | PostgreSQL username |
| `PAPERLESS_OCR_LANGUAGE` | `eng+ces` | OCR languages (Tesseract codes, `+` separated) |
| `PAPERLESS_OCR_MODE` | `skip` | Skip OCR if document already has text |
| `PAPERLESS_OCR_SKIP_ARCHIVE_FILE` | `with_text` | Don't create archive for docs that already have text |
| `PAPERLESS_CONSUMER_RECURSIVE` | `true` | Scan consume dir subdirectories |
| `PAPERLESS_CONSUMER_SUBDIRS_AS_TAGS` | `true` | Use subdirectory names as document tags |
| `PAPERLESS_CONSUMER_POLLING` | `300` | Consume dir polling interval (seconds) |
| `PAPERLESS_FILENAME_FORMAT` | `{created_year}/{correspondent}/{title}` | File naming in archive |
| `PAPERLESS_ADMIN_USER` | `admin` | Initial admin username (first start only) |
| `PAPERLESS_ADMIN_MAIL` | `admin@example.com` | Initial admin email (first start only) |

### Secrets (configure in Dockhand)

| Variable | Description | Generate with |
|----------|-------------|---------------|
| `POSTGRES_PASSWORD` | PostgreSQL password (shared by app + db) | `openssl rand -base64 24` |
| `PAPERLESS_SECRET_KEY` | Django secret key for sessions/tokens | `openssl rand -base64 48` |
| `PAPERLESS_ADMIN_PASSWORD` | Initial admin password (first start only) | choose a strong password |

Generate a local `.env.secrets` file (not committed to git):

```bash
cat > paperless/.env.secrets << EOF
POSTGRES_PASSWORD=$(openssl rand -base64 24)
PAPERLESS_SECRET_KEY=$(openssl rand -base64 48)
PAPERLESS_ADMIN_PASSWORD=$(openssl rand -base64 16)
EOF
```

Load into Dockhand (one-time, before first deploy):

```bash
just dockhand set-secrets-from paperless/.env.secrets paperless
just dockhand env paperless   # verify
just dockhand deploy paperless
```

> `PAPERLESS_ADMIN_PASSWORD` is applied **only on first start** when the
> database is empty. Change credentials via the web UI afterward.

Store `.env.secrets` in your separate secrets repository (SOPS-encrypted)
for backup. It is gitignored and not committed to `compose-stacks.git`.

## Storage Layout

```
/volume1/Documents/paperless/         # Physical drives (HDD) -- human-readable
├── media/
│   └── documents/
│       ├── originals/                # Uploaded source files (PDF, images, etc.)
│       ├── archive/                  # OCR'd PDF/A archival copies
│       └── thumbnails/               # Generated previews (regenerable)
└── consume/                          # Inbox -- drop files here via SMB for auto-import

Named volumes (NVME-backed Docker storage):
├── paperless-data                    # Search index, classification model
├── paperless-db-data                 # PostgreSQL database
└── paperless-redis-data              # Redis task queue
```

### Why this split?

| Storage | What | Why |
|---------|------|-----|
| **Physical drives** (`/volume1/`) | Originals + archive PDFs | Large, archival, human-browsable via SMB, backed up via Hyper Backup |
| **Named volumes** (NVME) | Database, search index, Redis | Small, I/O heavy, benefits from fast storage, regenerable from originals |

### SMB access to consume directory

To drop files from scanners or other devices, share the consume directory
via Synology DSM:

1. DSM -> Control Panel -> Shared Folder -> `Documents`
2. The consume path is at `Documents/paperless/consume`
3. Scanners/devices save to `\\<NAS_IP>\Documents\paperless\consume`

Paperless automatically imports, OCRs, and files any document placed in
this directory.

## Volumes

| Host / Volume | Container Path | Purpose |
|---------------|---------------|---------|
| `/volume1/Documents/paperless/media` | `/media` | Document originals + archive (physical drives) |
| `/volume1/Documents/paperless/consume` | `/consume` | Auto-import inbox (physical drives, SMB accessible) |
| `paperless-data` | `/data` | Search index, classification data (NVME) |
| `paperless-db-data` | `/var/lib/postgresql/data` | PostgreSQL database (NVME) |
| `paperless-redis-data` | `/data` | Redis persistence (NVME) |

## DNS + Reverse Proxy

1. DSM reverse proxy: `paperless.${LOCAL_DOMAIN}:443` -> `localhost:9980`
2. DNS: `paperless.${LOCAL_DOMAIN}` -> `${NAS_IP}`

## First-Time Setup

1. Create the host directories before starting:
   ```bash
   mkdir -p /volume1/Documents/paperless/media
   mkdir -p /volume1/Documents/paperless/consume
   chown -R 1026:100 /volume1/Documents/paperless
   ```
2. Set the three secrets in Dockhand Config Sets
3. Deploy the stack
4. Log in at `https://paperless.${LOCAL_DOMAIN}` with the admin credentials
5. The admin account is created only on first start; afterwards `PAPERLESS_ADMIN_*` vars are ignored

## OCR Languages

The default `eng+ces` supports English and Czech. To add languages, change
`PAPERLESS_OCR_LANGUAGE` in `.env`. Common codes:

| Language | Code |
|----------|------|
| English | `eng` |
| Czech | `ces` |
| German | `deu` |
| French | `fra` |
| Slovak | `slk` |

Multiple languages: `eng+ces+deu` (Tesseract will detect per-page).

## Backup

- **Documents**: Hyper Backup `/volume1/Documents/paperless/` -- this captures
  all originals and archive PDFs in their original form
- **Database**: `docker exec paperless-db pg_dump -U paperless paperless > backup.sql`
- **Full export**: `docker exec paperless document_exporter /export` (creates
  a portable JSON manifest + files)
