#!/bin/bash
# Custom init script for linuxserver/calibre-web
# Pre-configures Calibre database path and anonymous browsing
# Runs via /custom-cont-init.d/ on each container start

APP_DB="/config/app.db"
CALIBRE_DIR="/books"

# app.db created after first HTTP request -- run config in background
(
    for i in $(seq 1 120); do
        [ -f "$APP_DB" ] && break
        sleep 2
    done

    if [ ! -f "$APP_DB" ]; then
        echo "[init-calibre-web] app.db not found after 240s, skipping"
        exit 0
    fi

    sleep 3

    echo "[init-calibre-web] Setting Calibre DB path to: $CALIBRE_DIR"
    sqlite3 "$APP_DB" "UPDATE settings SET config_calibre_dir='$CALIBRE_DIR' WHERE id=1;" 2>/dev/null

    if [ "${ANON_BROWSE:-false}" = "true" ]; then
        echo "[init-calibre-web] Enabling anonymous browsing"
        sqlite3 "$APP_DB" "UPDATE settings SET config_anonbrowse=1 WHERE id=1;" 2>/dev/null
    fi

    echo "[init-calibre-web] Config applied"
) &

exit 0
