# Docusaurus documentation site management
#
# Usage (from repo root):
#   just docusaurus up          # Build image and start container
#   just docusaurus rebuild     # Force rebuild (re-clones repos)
#   just docusaurus fetch       # Clone/pull repos locally (for dev)
#   just docusaurus dev         # Local dev server with hot reload
#   just docusaurus logs        # Tail container logs
#   just docusaurus list-repos  # Show configured repos

set shell := ["bash", "-euc"]

COMPOSE := source_directory() / "compose.yaml"
REPOS_JSON := source_directory() / "repos.json"
DATA_DIR := source_directory() / "data"
SITE_DIR := source_directory() / "site"

# Build image and start container
up:
    docker compose -f {{COMPOSE}} up -d --build

# Stop container
down:
    docker compose -f {{COMPOSE}} down

# Force rebuild (re-clones repos from repos.json, rebuilds site)
rebuild:
    docker compose -f {{COMPOSE}} up -d --build --force-recreate

# Tail container logs
logs *args:
    docker compose -f {{COMPOSE}} logs -f {{args}}

# Show container status
status:
    docker compose -f {{COMPOSE}} ps

# Clone/pull repos locally into data/ (for local development)
fetch:
    #!/usr/bin/env bash
    set -euo pipefail
    [[ ! -f "{{REPOS_JSON}}" ]] && { echo "No repos.json found"; exit 1; }
    mkdir -p "{{DATA_DIR}}"
    jq -c '.[]' "{{REPOS_JSON}}" | while IFS= read -r repo; do
        name=$(echo "$repo" | jq -r '.name')
        url=$(echo "$repo" | jq -r '.url')
        branch=$(echo "$repo" | jq -r '.branch // "main"')
        clone_dir="{{DATA_DIR}}/$name"
        if [[ -d "$clone_dir/.git" ]]; then
            echo "Pulling $name ($branch)..."
            git -C "$clone_dir" fetch origin "$branch" --depth=1 2>&1
            git -C "$clone_dir" reset --hard "origin/$branch" 2>&1
        else
            echo "Cloning $name..."
            rm -rf "$clone_dir"
            git clone --depth=1 --branch "$branch" "$url" "$clone_dir"
        fi
    done
    echo "Done. Repos in {{DATA_DIR}}/"

# Copy fetched repo docs into site/docs/ for local development
prepare:
    #!/usr/bin/env bash
    set -euo pipefail
    [[ ! -f "{{REPOS_JSON}}" ]] && { echo "No repos.json found"; exit 1; }
    jq -c '.[]' "{{REPOS_JSON}}" | while IFS= read -r repo; do
        name=$(echo "$repo" | jq -r '.name')
        docs_path=$(echo "$repo" | jq -r '.docs_path // "docs"')
        target=$(echo "$repo" | jq -r '.target // .name')
        src="{{DATA_DIR}}/$name/$docs_path"
        dest="{{SITE_DIR}}/docs/$target"
        if [[ -d "$src" ]]; then
            echo "$name/$docs_path -> site/docs/$target"
            rm -rf "$dest"
            cp -r "$src" "$dest"
            find "$dest" -name ".git" -exec rm -rf {} + 2>/dev/null || true
        else
            echo "WARNING: $src does not exist, skipping"
        fi
    done

# Start local dev server (requires Node.js, jq, git)
dev: fetch prepare
    npm start --prefix "{{SITE_DIR}}"

# Build site locally (requires Node.js)
build-local: fetch prepare
    npm run build --prefix "{{SITE_DIR}}"

# Serve locally built site (requires Node.js)
serve: build-local
    npm run serve --prefix "{{SITE_DIR}}"

# Install Node.js dependencies locally
install:
    npm ci --prefix "{{SITE_DIR}}" --no-audit --no-fund

# Clean Docusaurus build artifacts
clean:
    rm -rf "{{SITE_DIR}}/build" "{{SITE_DIR}}/.docusaurus"

# Clean everything including cloned repos and Docker volume
clean-all: clean
    rm -rf "{{DATA_DIR}}"
    docker compose -f {{COMPOSE}} down -v 2>/dev/null || true

# List configured repos from repos.json
list-repos:
    #!/usr/bin/env bash
    set -euo pipefail
    echo "Configured documentation repos:"
    jq -r '.[] | "  \(.name) -> \(.url) (\(.branch // "main"))\n    source: \(.docs_path // "docs")  target: docs/\(.target // .name)"' "{{REPOS_JSON}}"

# Add a new repo to repos.json
add-repo name url branch="main" docs_path="docs" target="":
    #!/usr/bin/env bash
    set -euo pipefail
    t="{{target}}"
    [[ -z "$t" ]] && t="{{name}}"
    tmp=$(mktemp)
    jq --arg n "{{name}}" --arg u "{{url}}" --arg b "{{branch}}" \
       --arg d "{{docs_path}}" --arg t "$t" \
       '. + [{name:$n, url:$u, branch:$b, docs_path:$d, target:$t}]' \
       "{{REPOS_JSON}}" > "$tmp" && mv "$tmp" "{{REPOS_JSON}}"
    echo "Added {{name}} -> repos.json"
    echo "Run 'just docusaurus rebuild' to deploy, or 'just docusaurus fetch' for local dev"

# Remove a repo from repos.json by name
rm-repo name:
    #!/usr/bin/env bash
    set -euo pipefail
    tmp=$(mktemp)
    jq --arg n "{{name}}" 'map(select(.name != $n))' "{{REPOS_JSON}}" > "$tmp" && mv "$tmp" "{{REPOS_JSON}}"
    rm -rf "{{DATA_DIR}}/{{name}}"
    echo "Removed {{name}} from repos.json"
