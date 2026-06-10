# Joplin Server

Sync server for Joplin note-taking clients ([joplin/server](https://hub.docker.com/r/joplin/server)).

## URL

| | URL |
|--|-----|
| **Web UI** | `https://joplin.${LOCAL_DOMAIN}` |

## Deployment

Deployed via Dockhand. The stack includes Joplin Server and a PostgreSQL 16 database.

### Environment Variables (`.env` defaults)

| Variable | Default | Description |
|----------|---------|-------------|
| `LOCAL_DOMAIN` | *(from config.env)* | Shared -- routing domain for Traefik Host rules |
| `TZ` | `Europe/Prague` | Shared -- container timezone |
| `POSTGRES_DATABASE` | `joplin` | PostgreSQL database name |
| `POSTGRES_USER` | `joplin` | PostgreSQL username |
| `MAILER_ENABLED` | `0` | Enable email sending (`0` = disabled, `1` = enabled) |

### Secrets (configure in Dockhand)

| Variable | Description | Notes |
|----------|-------------|-------|
| `POSTGRES_PASSWORD` | PostgreSQL password (shared by app + db) | `openssl rand -base64 32` |
| `APP_ADMIN_EMAIL` | Admin account email | First start only |
| `APP_ADMIN_PASSWORD` | Admin account password | First start only |

Generate a local `.env.secrets` file (not committed to git):

```bash
cat > joplin/.env.secrets << EOF
POSTGRES_PASSWORD=$(openssl rand -base64 24)
APP_ADMIN_EMAIL=admin@example.com
APP_ADMIN_PASSWORD=$(openssl rand -base64 16)
EOF
```

Load into Dockhand (one-time, before first deploy):

```bash
just dockhand set-secrets-from joplin/.env.secrets joplin
just dockhand env joplin   # verify
just dockhand deploy joplin
```

> `APP_ADMIN_EMAIL` and `APP_ADMIN_PASSWORD` are applied **only on first start**
> when the database is empty. If the database already exists, change credentials
> via the Joplin web UI instead.

#### Optional mail secrets (only if `MAILER_ENABLED=1`)

| Variable | Description | Generate with |
|----------|-------------|---------------|
| `MAILER_HOST` | SMTP server hostname | *(your mail provider)* |
| `MAILER_PORT` | SMTP port | `587` (default) |
| `MAILER_SECURITY` | SMTP security mode | `starttls` (default) |
| `MAILER_AUTH_USER` | SMTP username | *(your mail provider)* |
| `MAILER_AUTH_PASSWORD` | SMTP password | *(your mail provider)* |
| `MAILER_NOREPLY_NAME` | Sender display name | `Joplin` |
| `MAILER_NOREPLY_EMAIL` | Sender email address | *(your mail provider)* |


## Troubleshooting

### Reset PostgreSQL password

If the database was initialized before the password secret was set (or the
password was changed in Dockhand), update PostgreSQL to match:

```bash
# Get the current password from Dockhand UI or:
just dockhand env joplin
# POSTGRES_PASSWORD=*** (check value in Dockhand UI -> joplin -> Environment)

# Update the password inside the running PostgreSQL container
docker exec joplin-db psql -U joplin -d joplin -c "ALTER USER joplin PASSWORD '<password>';"

# Restart Joplin app to reconnect with new password
docker restart joplin

# Verify connection
docker logs joplin --tail 10
```

### Fresh start (wipe database)

If the database is corrupted or you want to start over:

```bash
# Stop and remove containers + volumes
docker compose -p joplin down -v

# Set secrets before redeploy
just dockhand set-secret joplin POSTGRES_PASSWORD "$(openssl rand -base64 32)"
just dockhand set-secret joplin APP_ADMIN_EMAIL "admin@example.com"
just dockhand set-secret joplin APP_ADMIN_PASSWORD "yourpassword"

# Redeploy
just dockhand deploy joplin
```

## Volumes

| Volume | Container Path | Purpose |
|--------|---------------|---------|
| `joplin-db-data` | `/var/lib/postgresql/data` | PostgreSQL database files |

Joplin Server itself is stateless -- all data lives in PostgreSQL.

## DNS + Reverse Proxy

1. DSM reverse proxy: `joplin.${LOCAL_DOMAIN}:443` -> `localhost:9980`
2. DNS: `joplin.${LOCAL_DOMAIN}` -> `${NAS_IP}`

## Client Configuration

In each Joplin desktop/mobile client:

1. **Tools -> Options -> Synchronisation**
2. Set target: **Joplin Server**
3. URL: `https://joplin.${LOCAL_DOMAIN}`
4. Email / Password: your Joplin Server account credentials
