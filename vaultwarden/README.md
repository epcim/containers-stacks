# Vaultwarden

Self-hosted Bitwarden-compatible password manager ([vaultwarden/server](https://github.com/dani-garcia/vaultwarden)).

Lightweight Rust implementation of the Bitwarden server API. Works with
all official Bitwarden clients (browser extension, desktop, mobile).

## URL

| | URL |
|--|-----|
| **Web Vault** | `https://vaultwarden.${LOCAL_DOMAIN}` |
| **Admin Panel** | `https://vaultwarden.${LOCAL_DOMAIN}/admin` |

## Deployment

Deployed via Dockhand. Single container with embedded SQLite database.

### Environment Variables (`.env` defaults)

| Variable | Default | Description |
|----------|---------|-------------|
| `LOCAL_DOMAIN` | *(from config.env)* | Shared -- routing domain |
| `TZ` | `Europe/Prague` | Shared -- timezone |
| `SIGNUPS_ALLOWED` | `false` | Disable public registration (admin creates accounts) |

### Secrets (configure in Dockhand)

| Variable | Description | Generate with |
|----------|-------------|---------------|
| `ADMIN_TOKEN` | Admin panel access token (argon2 hash) | See below |

Generate a local `.env.secrets` file:

```bash
cat > vaultwarden/.env.secrets << EOF
ADMIN_TOKEN=$(openssl rand -base64 48)
EOF
```

Load into Dockhand:

```bash
just dok set-secrets-from vaultwarden/.env.secrets vaultwarden
just dok env vaultwarden   # verify
just dok sync vaultwarden
```

> For stronger security, use an argon2id hash as the admin token:
> ```bash
> # Install argon2 if needed: apt install argon2 / brew install argon2
> echo -n "your-admin-password" | argon2 "$(openssl rand -base64 32)" -e -id -k 65540 -t 3 -p 4
> ```
> Set the output as `ADMIN_TOKEN` in Dockhand. Then use `your-admin-password`
> to log into `/admin`.

## First-Time Setup

1. **Set the admin token** before first deploy (see Secrets above)

2. **Deploy** the stack:
   ```bash
   just dok sync vaultwarden
   ```

3. **Access the admin panel** at `https://vaultwarden.${LOCAL_DOMAIN}/admin`
   - Enter the admin token (the raw value, not the hash)
   - Review and configure settings:
     - **General**: server name, icon service
     - **Users**: create user accounts (since signups are disabled)
     - **SMTP**: configure email for invitations and 2FA recovery

4. **Create your first account**:
   - Option A: Enable `SIGNUPS_ALLOWED=true` temporarily, register at the web vault, then disable
   - Option B: Use the admin panel to invite a user by email (requires SMTP)
   - Option C: Use the admin panel -> Users -> Create user

5. **Install Bitwarden clients**:
   - Browser: [Bitwarden Extension](https://bitwarden.com/download/)
   - Desktop: [Bitwarden Desktop](https://bitwarden.com/download/)
   - Mobile: Bitwarden app from App Store / Play Store
   - In each client: Settings -> Self-hosted -> Server URL: `https://vaultwarden.${LOCAL_DOMAIN}`

## Reset Admin Password

If you lose the admin token:

```bash
# Generate a new token
NEW_TOKEN=$(openssl rand -base64 48)
echo "New admin token: $NEW_TOKEN"

# Set it in Dockhand
just dok set-secret ADMIN_TOKEN "$NEW_TOKEN" vaultwarden

# Redeploy
just dok sync vaultwarden
```

## Volumes

| Volume | Container Path | Purpose |
|--------|---------------|---------|
| `vaultwarden-data` | `/data` | SQLite database, attachments, RSA keys, icon cache |

## Backup

The SQLite database and all data are in the `vaultwarden-data` volume:

```bash
# Export backup via Vaultwarden's built-in backup
docker exec vaultwarden /vaultwarden backup

# Or copy the data directory
docker cp vaultwarden:/data ./vaultwarden-backup-$(date +%Y%m%d)
```

## Security Notes

- **SIGNUPS_ALLOWED=false** -- public registration is disabled by default.
  Only the admin can create accounts.
- **Rate limiting** -- Traefik applies rate limiting (20 req/s, burst 50)
  via the `vw-ratelimit` middleware to protect against brute force.
- **HTTPS required** -- Vaultwarden refuses to serve the web vault over
  plain HTTP. Traefik + DSM reverse proxy provide TLS.
- **Admin panel** -- accessible at `/admin` with the `ADMIN_TOKEN`.
  Consider disabling it after initial setup by removing `ADMIN_TOKEN`
  from the environment.

## DNS + Reverse Proxy

1. DSM reverse proxy: `vaultwarden.${LOCAL_DOMAIN}:443` -> `localhost:9980`
2. DNS: `vaultwarden.${LOCAL_DOMAIN}` -> `${NAS_IP}`
