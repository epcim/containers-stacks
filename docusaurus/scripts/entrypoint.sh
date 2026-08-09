#!/bin/sh
# Docusaurus entrypoint
#
# 1. Clone or pull repos from repos.json into /data/<name>/
# 2. Copy each repo's docs_path into /app/docs/<target>/
# 3. Build the Docusaurus static site
# 4. Copy build output to nginx html root
# 5. Start nginx

set -e

REPOS_JSON="${REPOS_JSON:-/app/repos.json}"
DATA_DIR="${DATA_DIR:-/data}"
APP_DIR="/app"
DOCS_DIR="$APP_DIR/docs"
BUILD_DIR="$APP_DIR/build"
NGINX_HTML="/usr/share/nginx/html"

echo "==> Docusaurus entrypoint starting"

# ── 1. Clone / update repos ──────────────────────────────────────────────
if [ -f "$REPOS_JSON" ] && [ -s "$REPOS_JSON" ]; then
    repo_count=$(jq 'length' "$REPOS_JSON")
    echo "==> Cleaning repo content from docs directory"
    # Remove only repo target dirs, preserve root files (index.mdx, etc.)
    jq -r '.[].target // .[].name' "$REPOS_JSON" | while IFS= read -r t; do
        rm -rf "${DOCS_DIR:?}/$t"
    done
    echo "==> Fetching $repo_count repo(s) from $REPOS_JSON"

    jq -c '.[]' "$REPOS_JSON" | while IFS= read -r repo; do
        name=$(echo "$repo" | jq -r '.name')
        url=$(echo "$repo" | jq -r '.url')
        branch=$(echo "$repo" | jq -r '.branch // "main"')
        docs_path=$(echo "$repo" | jq -r '.docs_path // "docs"')
        target=$(echo "$repo" | jq -r '.target // .name')
        label=$(echo "$repo" | jq -r '.label // ""')

        clone_dir="$DATA_DIR/$name"

        if [ -d "$clone_dir/.git" ]; then
            echo "  Pulling $name ($branch)..."
            git -C "$clone_dir" fetch origin "$branch" --depth=1 2>&1 || {
                echo "  WARNING: fetch failed for $name, using cached"
            }
            git -C "$clone_dir" reset --hard "origin/$branch" 2>&1 || true
        else
            echo "  Cloning $name from $url ($branch)..."
            rm -rf "$clone_dir"
            git clone --depth=1 --branch "$branch" "$url" "$clone_dir" 2>&1 || {
                echo "  WARNING: clone failed for $name, skipping"
                continue
            }
        fi

        # Copy docs content into Docusaurus docs tree
        src="$clone_dir/$docs_path"
        dest="$DOCS_DIR/$target"
        if [ -d "$src" ]; then
            echo "  Syncing $name/$docs_path -> docs/$target"
            rm -rf "$dest"
            mkdir -p "$dest"
            tar -C "$src" --exclude-from=/app/exclude.txt -cf - . | tar -C "$dest" -xf -
            
            # If a custom label is specified in repos.json, generate Docusaurus category configuration
            if [ -n "$label" ]; then
                echo "  Creating category configuration for $target with label: $label"
                echo "{\"label\": \"$label\"}" > "$dest/_category_.json"
            fi
        else
            echo "  WARNING: $src not found in $name, skipping"
        fi
    done
else
    echo "==> No repos.json found or empty, using default docs only"
fi

# ── 2. Build Docusaurus ──────────────────────────────────────────────────
echo "==> Building Docusaurus site..."
cd "$APP_DIR"
npm run build 2>&1

# ── 3. Deploy build output to nginx root ────────────────────────────────
echo "==> Deploying build to nginx..."
rm -rf "${NGINX_HTML:?}/"*
cp -r "$BUILD_DIR/." "$NGINX_HTML/"

# ── 4. Start nginx ───────────────────────────────────────────────────────
echo "==> Starting nginx"
exec nginx -g 'daemon off;'
