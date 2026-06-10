# Docusaurus documentation site
#
# Single-container runtime build:
#   1. On startup: entrypoint clones/pulls repos from repos.json into /data volume
#   2. Copies repo docs content into the Docusaurus docs tree
#   3. Builds the static site with `npm run build`
#   4. Serves the output with nginx
#
# /data is a named Docker volume that persists across restarts.
# Subsequent starts only `git pull` (fast). Rebuild to re-fetch.
#
# renovate: datasource=docker depName=node
FROM node:20-alpine

# nginx (Alpine package) reads conf from /etc/nginx/http.d/*.conf
RUN apk add --no-cache nginx git jq \
    && mkdir -p /run/nginx /usr/share/nginx/html

WORKDIR /app

# Install Node.js dependencies (separate layer for Docker cache)
COPY site/package.json site/package-lock.json* ./
RUN npm ci --no-audit --no-fund

# Copy Docusaurus project: config, theme, default docs, static assets
COPY site/ ./

# Copy runtime scripts, repo list, and exclusion filter
COPY scripts/entrypoint.sh /entrypoint.sh
COPY exclude.txt ./exclude.txt
COPY repos.json ./repos.json
COPY nginx.conf /etc/nginx/http.d/default.conf

RUN chmod +x /entrypoint.sh \
    && mkdir -p /data /app/docs

# /data is mounted as a named volume to persist cloned repos
VOLUME ["/data"]

EXPOSE 80

ENTRYPOINT ["/entrypoint.sh"]
