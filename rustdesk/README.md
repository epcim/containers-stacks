# RustDesk Server

Self-hosted RustDesk remote desktop rendezvous and relay server.

## URL

| Service | Port | Protocol | Purpose |
|---------|------|----------|---------|
| **hbbs (Rendezvous)** | `21115` | TCP | Connection negotiation |
| **hbbs (ID Server)** | `21116` | TCP/UDP | TCP hole punching & UDP Heartbeat |
| **hbbr (Relay)** | `21117` | TCP | Session traffic relaying |

## Deployment

Deployed via Dockhand.

### Environment Variables (`.env` defaults)

| Variable | Default | Description |
|----------|---------|-------------|
| `LOCAL_DOMAIN` | *(from config.env)* | Shared — routing domain |
| `TZ` | `Europe/Prague` | Shared — container timezone |
| `NAS_IP` | `172.31.2.12` | Shared — NAS IP on the regular USER VLAN network interface |

### Secrets (configure in Dockhand)

No secrets required.

## Volumes

| Host / Volume | Container Path | Purpose |
|---------------|---------------|---------|
| `rustdesk-data` | `/root` | Stores public/private keypairs used for client encryption |

## DNS + Reverse Proxy

RustDesk uses custom TCP and UDP protocols rather than HTTP, so traffic is routed directly to the NAS IP on specified ports, bypassing Traefik proxy.

### Network Isolation and Security
To prevent exposing RustDesk on all network interfaces of your Synology NAS (such as public VPNs, management VLANs, etc.), the ports are bound explicitly to `${NAS_IP}` (representing your regular USER VLAN interface).
