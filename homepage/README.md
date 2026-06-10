# Homepage

Modern, self-hosted application dashboard ([gethomepage.dev](https://gethomepage.dev/)).

Auto-discovers Docker containers via labels. Supports widgets for
system info, weather, search, and integrations with dozens of self-hosted apps.

## URL

| | URL |
|--|-----|
| **Dashboard** | `https://homepage.${LOCAL_DOMAIN}` |

## Deployment

Deployed via Dockhand.

### Environment Variables (`.env` defaults)

| Variable | Default | Description |
|----------|---------|-------------|
| `LOCAL_DOMAIN` | *(from config.env)* | Shared -- routing domain for Traefik Host rules |
| `TZ` | `Europe/Prague` | Shared -- container timezone |
| `PUID` | `1026` | Shared -- Synology user ID for file permissions |
| `PGID` | `100` | Shared -- Synology group ID for file permissions |

### Secrets (configure in Dockhand UI)

Widget integrations use `{{HOMEPAGE_VAR_*}}` placeholders in `services.yaml`.
The actual values are injected via environment variables at runtime.

All of these are **optional** -- Homepage works without them, widgets just
won't show live data.

| Variable | Description | Used by widget |
|----------|-------------|----------------|
| `HOMEPAGE_VAR_DOCKHAND_USERNAME` | Dockhand login username | Dockhand |
| `HOMEPAGE_VAR_DOCKHAND_PASSWORD` | Dockhand login password | Dockhand |
| `HOMEPAGE_VAR_FORGEJO_KEY` | Forgejo API token | Forgejo/Gitea |
| `HOMEPAGE_VAR_EMBY_KEY` | Emby API key | Emby |
| `HOMEPAGE_VAR_NAVIDROME_USER` | Navidrome username | Navidrome |
| `HOMEPAGE_VAR_NAVIDROME_TOKEN` | Navidrome API token | Navidrome |
| `HOMEPAGE_VAR_NAVIDROME_SALT` | Navidrome token salt | Navidrome |
| `HOMEPAGE_VAR_CALIBRE_USERNAME` | Calibre-Web username | Calibre-Web |
| `HOMEPAGE_VAR_CALIBRE_PASSWORD` | Calibre-Web password | Calibre-Web |
| `HOMEPAGE_VAR_NAS_USERNAME` | Synology DSM username | Synology DSM |
| `HOMEPAGE_VAR_NAS_PASSWORD` | Synology DSM password | Synology DSM |
| `HOMEPAGE_VAR_PROXMOX_USERNAME` | Proxmox API user (`user@pam!token`) | Proxmox |
| `HOMEPAGE_VAR_PROXMOX_PASSWORD` | Proxmox API token secret | Proxmox |
| `HOMEPAGE_VAR_UNIFI_USERNAME` | UniFi controller username | UniFi |
| `HOMEPAGE_VAR_UNIFI_PASSWORD` | UniFi controller password | UniFi |
| `HOMEPAGE_VAR_IMMICH_KEY` | Immich API key | Immich |
| `HOMEPAGE_VAR_NETBIRD_TOKEN` | NetBird API token | NetBird |
| `HOMEPAGE_VAR_MIKROTIK_URL` | MikroTik router URL (e.g. `http://172.31.2.1`) | MikroTik |
| `HOMEPAGE_VAR_MIKROTIK_USERNAME` | MikroTik admin username | MikroTik |
| `HOMEPAGE_VAR_MIKROTIK_PASSWORD` | MikroTik admin password | MikroTik |

Generate Forgejo token: **Forgejo -> Settings -> Applications -> Generate Token**
Generate Emby API key: **Emby -> Dashboard -> API Keys -> New**
Generate Navidrome token: see [Subsonic auth docs](https://www.subsonic.org/pages/api.jsp) (`token = md5(password + salt)`)

## Volumes

| Volume | Container Path | Purpose |
|--------|---------------|---------|
| `homepage-config` | `/app/config` | YAML configuration files |
| `/var/run/docker.sock` | `/var/run/docker.sock` | Docker service auto-discovery (read-only) |

## Configuration

Homepage uses YAML files in `/app/config`. On first start, defaults are
generated. Edit them via:

```bash
# Find the named volume path
docker volume inspect homepage-config --format '{{ .Mountpoint }}'

# Or copy files out, edit, copy back
docker cp homepage:/app/config/services.yaml ./services.yaml
# ... edit ...
docker cp ./services.yaml homepage:/app/config/services.yaml
```

### Key config files

| File | Purpose |
|------|---------|
| `settings.yaml` | Title, theme, layout, search providers |
| `services.yaml` | Service groups and links (use `{{HOMEPAGE_VAR_*}}` for secrets) |
| `widgets.yaml` | Top-bar widgets (search, system info, weather) |
| `bookmarks.yaml` | Bookmark groups |
| `docker.yaml` | Docker socket / API config for auto-discovery |

### Example `services.yaml` with widget secrets

```yaml
- Infrastructure:
    - Dockhand:
        icon: dockhand
        href: https://dockhand.{{HOMEPAGE_VAR_LOCAL_DOMAIN}}
        widget:
          type: dockhand
          url: http://dockhand:3000
          username: "{{HOMEPAGE_VAR_DOCKHAND_USERNAME}}"
          password: "{{HOMEPAGE_VAR_DOCKHAND_PASSWORD}}"

    - Forgejo:
        icon: forgejo
        href: https://forgejo.{{HOMEPAGE_VAR_LOCAL_DOMAIN}}
        widget:
          type: gitea
          url: https://forgejo.{{HOMEPAGE_VAR_LOCAL_DOMAIN}}
          key: "{{HOMEPAGE_VAR_FORGEJO_KEY}}"

- Network:
    - MikroTik:
        icon: mikrotik
        href: "{{HOMEPAGE_VAR_MIKROTIK_URL}}"
        description: Router

- Kubernetes:
    - Jellyfin:
        icon: jellyfin
        href: https://jellyfin.example.net
        description: Media server

    - Home Assistant:
        icon: home-assistant
        href: https://hass.example.net
        description: Home automation

    - Grafana:
        icon: grafana
        href: https://grafana.example.net
        description: Monitoring dashboards

    - Longhorn:
        icon: longhorn
        href: https://longhorn.example.net
        description: Storage

    - Kluctl:
        icon: kubernetes
        href: https://kluctl.example.net
        description: GitOps deployments

    - Harbor:
        icon: harbor
        href: https://harbor.example.net
        description: Container registry

    - OctoPrint:
        icon: octoprint
        href: https://octoprint.example.net
        description: 3D printer

    - UniFi:
        icon: unifi
        href: https://unifi.example.net
        description: Network controller

- Media:
    - Emby:
        icon: emby
        href: https://emby.{{HOMEPAGE_VAR_LOCAL_DOMAIN}}
        widget:
          type: emby
          url: http://emby:8096
          key: "{{HOMEPAGE_VAR_EMBY_KEY}}"

    - Navidrome:
        icon: navidrome
        href: https://navidrome.{{HOMEPAGE_VAR_LOCAL_DOMAIN}}
        widget:
          type: navidrome
          url: http://navidrome:4533
          user: "{{HOMEPAGE_VAR_NAVIDROME_USER}}"
          token: "{{HOMEPAGE_VAR_NAVIDROME_TOKEN}}"
          salt: "{{HOMEPAGE_VAR_NAVIDROME_SALT}}"
```

### Docker auto-discovery

Homepage can discover services from Docker labels. Add these labels to
any container's compose file to make it appear on the dashboard:

```yaml
labels:
  - "homepage.group=Infrastructure"
  - "homepage.name=Traefik"
  - "homepage.icon=traefik"
  - "homepage.href=https://traefik.${LOCAL_DOMAIN}/dashboard/"
  - "homepage.description=Reverse proxy"
```

### Example `docker.yaml` for Synology

```yaml
local:
  socket: /var/run/docker.sock
```

### Example `settings.yaml`

```yaml
title: Synology Dashboard
theme: dark
color: slate
headerStyle: clean
layout:
  Infrastructure:
    style: row
    columns: 4
  Media:
    style: row
    columns: 3
  Applications:
    style: row
    columns: 4
```

## Resource Limits

The container is limited to **256MB RAM** via `deploy.resources.limits.memory`.
Adjust in `compose.yaml` if needed.

## Security

- Container runs with `no-new-privileges` security option
- Docker socket is mounted **read-only**
- Widget secrets are passed via environment variables, never stored in config files

## DNS + Reverse Proxy

1. DSM reverse proxy: `homepage.${LOCAL_DOMAIN}:443` -> `localhost:9980`
2. DNS: `homepage.${LOCAL_DOMAIN}` -> `${NAS_IP}`

## Replacing Homarr

If Homepage replaces Homarr as the primary dashboard, consider:

1. Add `homepage.*` Docker labels to all existing stacks for auto-discovery
2. Update the Traefik bare-domain redirect to point to Homepage instead
3. Remove or stop the Homarr stack
