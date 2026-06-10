# MinIO

S3-compatible object storage ([minio/minio](https://github.com/minio/minio)).

## URLs

| | URL |
|--|-----|
| **Console** | `https://minio.example.familyds.net` |
| **S3 API** | `https://s3.example.familyds.net` |

## Deployment

Deployed via Dockhand. Set these in Dockhand Config Sets:

- `MINIO_ROOT_USER` — admin username
- `MINIO_ROOT_PASSWORD` — admin password

## Volumes

Uses existing bind mounts (not named volumes):

| Host Path | Container Path | Purpose |
|-----------|---------------|---------|
| `/volume1/Minio` | `/data` | Object storage data |
| `/volume1/docker/minio/config` | `/root/.minio` | MinIO configuration |

To switch to named volumes, uncomment the `volumes:` section in `compose.yaml`.

## DNS + Reverse Proxy

Two Synology DSM reverse proxy entries needed:

1. `minio.example.familyds.net:443` → `localhost:9980`
2. `s3.example.familyds.net:443` → `localhost:9980`

DNS: both subdomains → `172.31.2.12`
