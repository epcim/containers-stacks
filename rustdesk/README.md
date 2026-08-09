# RustDesk Server

Self-hosted RustDesk remote desktop rendezvous and relay server (`hbbs` and `hbbr`).

This stack allows you to host your own secure remote support infrastructure on Synology, fully isolated and controlled.

## URL & Port Reference

Since RustDesk does not use HTTP for remote desktop sessions, traffic is routed directly to the Synology NAS IP on custom ports, bypassing Traefik proxy for session streams.

| Service | Port | Protocol | Purpose |
|---------|------|----------|---------|
| **hbbs (Rendezvous)** | `21115` | TCP | Connection negotiation |
| **hbbs (ID Server)** | `21116` | TCP | TCP hole punching |
| **hbbs (ID Server)** | `21116` | UDP | Heartbeat / ID discovery |
| **hbbr (Relay)** | `21117` | TCP | Session traffic relaying (if direct P2P fails) |

## Deployment

Deployed via **Dockhand** GitOps workflow.

### Environment Variables (`.env` defaults)

| Variable | Default | Description |
|----------|---------|-------------|
| `LOCAL_DOMAIN` | *(from config.env)* | Shared — routing domain (used for client configurations) |
| `TZ` | `Europe/Prague` | Shared — container timezone |
| `NAS_IP` | `172.31.2.12` | Shared — Synology LAN/VLAN IP on the regular USER network interface |

### Secrets (configure in Dockhand)

No secrets are required for the standard free OSS server.

---

## 🔒 Network Isolation and Security

Unlike default Docker templates that use `network_mode: host` (which binds ports to `0.0.0.0` on all network interfaces, exposing RustDesk to management interfaces, public VPNs, and WANs), **this stack uses explicit port mapping bound specifically to `${NAS_IP}`**.

This guarantees that RustDesk only listens and accepts connections on your **USER VLAN network interface**, keeping your management and administrative subnets completely secure.

### Synology DSM Firewall Rules
Ensure your DSM firewall allows incoming traffic from the User VLAN to the Synology IP on the following ports:
* **TCP**: `21115`, `21116`, `21117`
* **UDP**: `21116`

---

## 📁 Volumes

| Host / Volume | Container Path | Purpose |
|---------------|---------------|---------|
| `rustdesk-data` | `/root` | Shared volume containing the automatically generated public/private encryption keys |

Both `hbbs` and `hbbr` share the `rustdesk-data` volume so that connection signatures can be verified.

---

## 💻 RustDesk Client Configuration

To configure your RustDesk clients (Windows, Mac, Linux, Android, iOS) to use your self-hosted server:

### 1. Retrieve the Server Public Key 🔑
When the container boots for the first time, it automatically generates an encryption keypair in `/root/id_ed25519.pub`. You need to copy this public key:

Run this command on your Synology NAS terminal (or retrieve it from the named volume):
```bash
docker exec -it rustdesk-hbbs cat /root/id_ed25519.pub
```
*Example output:* `ds9hA1...Fas78A=`

### 2. Configure the Client Settings ⚙️
1. Open the RustDesk client on the technician's and the client's computer.
2. Click the **three dots** next to your ID -> **Network**.
3. Fill in the following fields:
   * **ID Server**: `rustdesk.${LOCAL_DOMAIN}` *(or directly your `${NAS_IP}`)*
   * **Relay Server**: `rustdesk.${LOCAL_DOMAIN}` *(or directly your `${NAS_IP}`)*
   * **API Server**: *(leave blank unless using Pro)*
   * **Key**: *(Paste the public key you retrieved in Step 1)*
4. Click **Apply**. The status bar at the bottom should say **"Ready"** with a green dot!

---

## 🚀 Advanced: RustDesk Server Pro (Web Console)

If you use **RustDesk Server Pro** (commercial version) and want to reverse-proxy the administrative Web Console through Traefik:

1. In `compose.yaml`, change the images to:
   * `hbbs`: `rustdesk/rustdesk-server-pro:latest`
   * `hbbr`: `rustdesk/rustdesk-server-pro:latest`
2. Add the following Traefik and Homepage labels to the **`hbbs`** service in `compose.yaml`:

```yaml
    labels:
      - "traefik.enable=true"
      - "traefik.http.routers.rustdesk.rule=Host(`rustdesk.${LOCAL_DOMAIN}`)"
      - "traefik.http.routers.rustdesk.entrypoints=web"
      - "traefik.http.services.rustdesk.loadbalancer.server.port=21114"
      # Homepage
      - "homepage.group=Infrastructure"
      - "homepage.name=RustDesk Console"
      - "homepage.icon=rustdesk"
      - "homepage.href=https://rustdesk.${LOCAL_DOMAIN}"
      - "homepage.description=Self-hosted remote desktop administrative console"
```
3. Sync and redeploy the stack! Your console will be instantly accessible at `https://rustdesk.yourdomain.com` with secure SSL encryption.
