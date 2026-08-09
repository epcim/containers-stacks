# Applications Stacks Catalog

This repository is a public, community-shareable catalog of application stacks designed to be deployed cleanly via **Dockhand** (or any standard GitOps engine) on Synology NAS (or any Docker-enabled hardware).

All stacks in this repository are pre-configured to run behind a **Traefik Reverse Proxy** and are fully parameterized for clean, custom deployments.

---

## 🚀 Key Architectural Principles

1. **Absolute Port Isolation**: Stacks do not hardcode host port bindings. They join a shared Traefik proxy network and are accessed securely via virtual hosts (e.g., `appname.yourdomain.com`).
2. **Strict Separation of Config and Data**: All dynamic parameters (hostnames, ports, and folder paths) are fully externalized into `.env` and `.secrets.env` files.
3. **Community-First Standards**: Compose files are kept 100% generic so they can be pushed upstream and shared with the community with **zero** custom path leaks.

---

## 📁 Managing Application Data (Bind Mount Best Practices)

When running containers on your Synology NAS, you often want to mount persistent directories (e.g., your personal Synology Drive folders, media libraries, or company documents) directly into your applications.

To keep compose configurations pristine and shareable with the community, **never hardcode your local volume paths** directly in `compose.yaml`. Instead, leverage **Environment Variables**.

### 🌟 The Path Parameterization Pattern

#### 1. Declare the path in your local `.env` file:
Create a local `.env` file (which is git-ignored or customized per deployment) and define your local host directory paths:

```ini
# .env
# Map to your local Synology volume paths
DOCS_DIR=/volume1/homes/user/Drive/Documents
MEDIA_DIR=/volume1/music
```

#### 2. Bind the variable in your `compose.yaml`:
In the public, shared `compose.yaml` file, reference that environment variable:

```yaml
# compose.yaml
services:
  myapp:
    image: vendor/myapp:1.0
    volumes:
      # Mount your local folder cleanly to the container path
      - ${DOCS_DIR}:/app/docs:ro
      - ${MEDIA_DIR}:/data/media
```

### 📝 Example: Docusaurus Synology Drive Mount
To mount your local Synology Drive Markdown folder directly to a Docusaurus static compiler stack:

```yaml
# docusaurus/compose.yaml
services:
  docusaurus:
    image: node:20-alpine
    volumes:
      # Maps your local Synology Drive folder into Docusaurus
      - ${LOCAL_DOCS_PATH}:/app/docs
```

Each user defines `LOCAL_DOCS_PATH` inside their private `.env` (e.g., `LOCAL_DOCS_PATH=/volume1/homes/petr/Drive/IT-docs`), making the template fully reusable by anyone in the community!

---

## 🛠️ How to deploy a Stack

If you are using our workstation `just` runner CLI, deploying a stack with its local configs is incredibly simple:

```bash
# 1. Register the stack in Dockhand (first-time only)
just dockhand register homepage

# 2. Sync, upload environment variables, and launch the container on the NAS!
just dockhand sync homepage
```

The CLI automatically reads your local `.env` and securely uploads your environment paths and configs to Dockhand at run time.

---

## 🤝 Contribution Guidelines

We highly welcome contributions of new application stacks! To keep the catalog clean and reusable for the community:

1. **Use Variable Paths**: Ensure all volume mount host-paths are fully parameterized via `.env` variables (e.g., use `${DATA_DIR}` or `${MEDIA_DIR}`).
2. **Anonymize Configurations**: Keep domains and IPs out of the public compose files.
3. **Include a README**: Each application subfolder should contain a quick `README.md` explaining any required environment variables.
4. **Renovate Comments**: Add Renovate comments above image tags so that automated minor/major updates can be tracked cleanly:
   ```yaml
   # renovate: datasource=docker depName=node
   image: node:20-alpine
   ```

Let's build the ultimate community-driven self-hosted catalog together! 🚀🛡️🚀
