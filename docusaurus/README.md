# Docusaurus

Internal documentation site powered by [Docusaurus](https://docusaurus.io/).
Aggregates Markdown documentation from multiple git repositories and serves
a unified static site.

## URL

| | URL |
|--|-----|
| **Web UI** | `https://docs.${LOCAL_DOMAIN}` |

## Architecture

```
repos.json          defines git repos to clone
       |
  entrypoint.sh     clones/pulls repos into /data (named volume)
       |             copies docs content into Docusaurus docs/ tree
       |
  npm run build     builds static site
       |
     nginx          serves the built site on port 80
```

Content sources are configured in `repos.json`. Each entry specifies:

| Field | Description |
|-------|-------------|
| `name` | Unique identifier for the repo |
| `url` | Git clone URL |
| `branch` | Branch to track (default: `main`) |
| `docs_path` | Path to docs inside the repo (default: `docs`) |
| `target` | Subdirectory under `docs/` in Docusaurus (default: same as `name`) |

Example `repos.json`:

```json
[
  {
    "name": "synology",
    "url": "https://forgejo.example.familyds.net/org/synology-containers.git",
    "branch": "main",
    "docs_path": "_docs",
    "target": "synology"
  }
]
```

### How it works

1. Container starts and reads `repos.json`
2. For each repo: `git clone --depth=1` (first run) or `git pull` (subsequent)
3. Copies each repo's `docs_path` into `site/docs/<target>/`
4. Runs `npm run build` to generate static HTML
5. Serves with nginx

Cloned repos persist in the `docusaurus-data` Docker volume. Restarts only
pull updates (fast). Use `just docusaurus rebuild` to force a clean build.

## Deployment

Deployed via Dockhand. The image is built locally and pushed to the Forgejo
container registry. Dockhand pulls the image on deploy (it does not build
from Dockerfiles).

### Quick reference (from `_stacks/docusaurus/`)

```bash
just build       # Build image locally (native arch, fast)
just test        # Build + run on http://localhost:8080
just push        # Build for amd64 + push :latest to Forgejo registry
just deploy      # Build, push with timestamped tag, update compose, deploy via Dockhand
just clean       # Remove local test image
```

### From repo root

```bash
just build-image _stacks/docusaurus                 # Build + push to registry
just deploy-image _stacks/docusaurus                # Build + push + deploy via Dockhand
just build-image _stacks/docusaurus v1.0.0           # With specific tag
# just build-image _stacks/docusaurus latest "linux/amd64,linux/arm64"  # Multi-platform
```

### Manual build and deploy (without just)

```bash
# Build for amd64, push to registry (use --no-cache to force clean build)
docker buildx build \
    --platform linux/amd64 \
    --no-cache \
    -t forgejo.example.familyds.net/example/docusaurus:latest \
    --push \
    .

# Deploy via Dockhand (force recreate + repull image)
just dockhand sync docusaurus true
```

### When to rebuild vs restart

| Change | Action |
|--------|--------|
| Markdown content in repos | Restart only (`docker restart docusaurus`) |
| `repos.json` (add/remove repo) | Rebuild + deploy (`just deploy`) |
| `exclude.txt` | Rebuild + deploy |
| `docusaurus.config.js` / theme / CSS | Rebuild + deploy |
| `package.json` / Node deps | Rebuild + deploy |

Requires `docker login forgejo.example.familyds.net` first (one-time, uses
a Forgejo personal access token with `package:write` scope).

### Environment Variables (`.env` defaults)

| Variable | Default | Description |
|----------|---------|-------------|
| `LOCAL_DOMAIN` | *(from config.env)* | Shared -- routing domain for Traefik Host rules |
| `TZ` | `Europe/Prague` | Shared -- container timezone |

### Secrets (configure in Dockhand)

No secrets required for public repos.

For private repos, set git credentials as environment variables via Dockhand:

| Variable | Description | Example |
|----------|-------------|---------|
| `GIT_USER` | Git username for private repos | `admin` |
| `GIT_TOKEN` | Personal access token | *(generate in Forgejo)* |

Set via: `just dockhand set-secret docusaurus GIT_TOKEN "value"`

## Volumes

| Host / Volume | Container Path | Purpose |
|---------------|---------------|---------|
| `docusaurus-data` | `/data` | Cloned git repositories (persists across restarts) |

## Operations

### Justfile commands

```bash
just docusaurus up              # Build image and start
just docusaurus rebuild         # Force rebuild (re-clone + rebuild)
just docusaurus logs            # Tail container logs
just docusaurus status          # Container status

just docusaurus list-repos      # Show configured repos
just docusaurus add-repo NAME URL [BRANCH] [DOCS_PATH] [TARGET]
just docusaurus rm-repo NAME    # Remove a repo

# Local development (requires Node.js, jq, git)
just docusaurus fetch           # Clone/pull repos locally into data/
just docusaurus dev             # Start local dev server with hot reload
just docusaurus serve           # Build and serve locally
just docusaurus install         # Install Node.js deps
just docusaurus clean           # Clean build artifacts
just docusaurus clean-all       # Clean everything + Docker volume
```

### Adding a new documentation repo

```bash
# 1. Add to repos.json
just docusaurus add-repo my-docs https://forgejo.example.familyds.net/org/my-docs.git main docs my-docs

# 2. Rebuild the container
just docusaurus rebuild
```

Or edit `repos.json` directly and push to trigger Dockhand sync.

### Preparing a documentation repo

Any git repo with Markdown files can be added. For best results, follow
these conventions.

#### Directory structure

```
my-docs/
  _category_.json         <- sidebar label and sort order for this section
  index.md                <- section landing page (shown when clicking category)
  getting-started.md
  configuration.md
  advanced/
    _category_.json
    topic-a.md
    topic-b.md
  images/
    diagram.png
```

#### Frontmatter

Every `.md` file should start with a YAML frontmatter block. This controls
the page title, sidebar position, and URL slug:

```markdown
---
title: Getting Started
sidebar_position: 1
description: How to set up the project from scratch
---

# Getting Started

Your content here...
```

Common frontmatter fields:

| Field | Purpose | Example |
|-------|---------|---------|
| `title` | Page title (sidebar + browser tab) | `Getting Started` |
| `sidebar_position` | Sort order in sidebar (lower = higher) | `1` |
| `sidebar_label` | Override sidebar text (shorter than title) | `Setup` |
| `description` | SEO / link preview description | `How to...` |
| `slug` | Custom URL path | `/intro` |
| `tags` | Categorization tags | `[setup, docker]` |

#### Category files (`_category_.json`)

Place in each directory to control the sidebar section:

```json
{
  "label": "Advanced Topics",
  "position": 3,
  "collapsible": true,
  "collapsed": false
}
```

#### Index pages

A file named `index.md` in a directory becomes the landing page for that
category. When a user clicks the category name in the sidebar, they see
this page instead of an auto-generated list.

#### Images and assets

Place images next to the Markdown files that reference them:

```markdown
![Architecture diagram](./images/diagram.png)
```

Or use a shared `images/` or `assets/` directory at the repo root.

#### `.md` vs `.mdx`

| Extension | Format | Use when |
|-----------|--------|----------|
| `.md` | CommonMark | Plain docs, notes, Obsidian vaults — no JSX needed |
| `.mdx` | MDX | Need React components, tabs, admonitions with JSX syntax |

Most content should be `.md`. Use `.mdx` only when you need interactive
components like `<Tabs>` or custom React widgets.

#### Admonitions (callout boxes)

Works in both `.md` and `.mdx`:

```markdown
:::note
This is a note.
:::

:::tip
Helpful tip here.
:::

:::warning
Be careful with this.
:::

:::danger
This can break things.
:::
```

#### Linking between pages

Use relative paths:

```markdown
See [Configuration](./configuration.md) for details.
See [Advanced Topic A](./advanced/topic-a.md).
```

#### Minimal example repo

A repo ready to be added to `repos.json`:

```
my-wiki/
  _category_.json         <- {"label": "My Wiki", "position": 1}
  index.md                <- landing page with frontmatter
  notes.md
  reference.md
```

`index.md`:

```markdown
---
title: My Wiki
sidebar_position: 1
---

# My Wiki

Overview of this documentation section.
```

#### What gets filtered out

Files matching patterns in `exclude.txt` are stripped during copy.
This includes `.git`, `.obsidian`, `AGENTS*.md`, `TODO*.md`, `Justfile`,
IDE configs, and OS artifacts. See `exclude.txt` for the full list.

### Updating content

Content updates when the container restarts (entrypoint pulls latest):

```bash
docker restart docusaurus
# or
just docusaurus rebuild         # Force full rebuild
```

## DNS + Reverse Proxy

1. DSM reverse proxy: `docs.${LOCAL_DOMAIN}:443` -> `localhost:9980`
2. DNS: `docs.${LOCAL_DOMAIN}` -> `${NAS_IP}`
