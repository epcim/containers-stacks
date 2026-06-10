# Home Assistant

Open-source home automation platform. [upstream](https://www.home-assistant.io/)

Secondary/backup instance. Primary integrations: ESPHome and Fronius.

## URLs

| | URL |
|--|-----|
| **Home Assistant** | `https://hass.${LOCAL_DOMAIN}` |

## Deployment

Deployed via Dockhand.

### Environment Variables (`.env` defaults)

| Variable | Default | Description |
|----------|---------|-------------|
| `LOCAL_DOMAIN` | *(from config.env)* | Shared — routing domain for Traefik Host rules |
| `TZ` | `Europe/Prague` | Shared — container timezone |

### Secrets

No secrets required. Home Assistant creates an admin account on first login.

## Volumes & Config

| Source | Container Path | Managed by |
|--------|---------------|------------|
| `hass-config` (volume) | `/config` | Docker — runtime state, `.storage/`, automations |
| `./configuration.yaml` (repo) | `/config/configuration.yaml` | Git — integrations, http proxy config |

`configuration.yaml` is bind-mounted read-only from this repo. To change HA config, edit
`_stacks/hass/configuration.yaml` and run `just dockhand sync hass`.

## Notes

- ESPHome and Fronius integrations must be added manually by IP in the HA UI (no mDNS on bridge network).
- `http.trusted_proxies` in `configuration.yaml` is set to `172.20.0.0/16` (Traefik's Docker subnet).
  If Traefik's IP changes, update that value and sync.

## Dockhand Operations

```bash
just dockhand sync hass    # pull latest config + redeploy
just dockhand info hass    # check sync status
```
