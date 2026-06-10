#!/bin/bash
# Calibre book ingest script
# Watches /inbox for new ebook files and adds them to Calibre libraries.
#
# Inbox structure:
#   /inbox/book.epub             -> default library (CALIBRE_DEFAULT_LIBRARY)
#   /inbox/Fiction/book.epub     -> /books-text/Fiction library
#   /inbox/Education/book.pdf    -> /books-text/Education library
#   /inbox/Beletry/book.mobi     -> /books-text/Beletry library
#
# Supported formats: epub, pdf, mobi, azw3, fb2, djvu, cbz, cbr, lit, rtf, txt

set -euo pipefail

INTERVAL="${INGEST_INTERVAL:-300}"
DEFAULT_LIBRARY="${CALIBRE_DEFAULT_LIBRARY:-Beletry}"
EBOOK_EXTS="epub|pdf|mobi|azw3|fb2|djvu|cbz|cbr|lit|rtf|txt|htmlz"

log() { echo "[ingest] $(date '+%Y-%m-%d %H:%M:%S') $*"; }

process_file() {
    local file="$1"
    local relpath="${file#/inbox/}"
    local ext="${file##*.}"
    ext="${ext,,}"

    # Skip hidden files and partial downloads
    [[ "$(basename "$file")" == .* ]] && return
    [[ "$ext" == "part" || "$ext" == "tmp" || "$ext" == "crdownload" ]] && return

    if [[ ! "$ext" =~ ^($EBOOK_EXTS)$ ]]; then
        log "skip: $relpath (unsupported: $ext)"
        return
    fi

    # Determine target library from subdirectory
    local subdir
    subdir=$(dirname "$relpath")
    local library="$DEFAULT_LIBRARY"
    if [[ "$subdir" != "." && -d "/books-text/$subdir" ]]; then
        library="$subdir"
    fi
    local libpath="/books-text/$library"

    # Ensure library directory exists
    mkdir -p "$libpath"

    log "ebook: $relpath -> library=$library"
    if calibredb add "$file" --library-path "$libpath" 2>&1 | grep -q "Added book"; then
        log "  added, removing source"
        rm -f "$file"
    else
        log "  failed, moving to /inbox/.failed/"
        mkdir -p /inbox/.failed
        mv "$file" "/inbox/.failed/"
    fi
}

log "Starting ingest (interval: ${INTERVAL}s, default library: $DEFAULT_LIBRARY)"
log "Libraries: $(ls -1 /books-text/ | tr '\n' ' ')"

while true; do
    find /inbox -maxdepth 2 -type f -not -path '/inbox/.failed/*' -not -name '.*' 2>/dev/null | sort | while read -r file; do
        process_file "$file"
    done

    # Clean empty subdirs in inbox
    find /inbox -mindepth 1 -maxdepth 1 -type d -not -name '.failed' -empty -delete 2>/dev/null || true

    sleep "$INTERVAL"
done
