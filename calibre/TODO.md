# Calibre - Future: Unified Library

## Goal

Consolidate 3 separate Calibre libraries (Beletry, Fiction, Education) into
a single calibre-web instance with one unified `metadata.db`. Books remain
in their current directory locations on disk.

## Current State

- 3 calibre-web containers, one per library
- 3 separate `metadata.db` files
- Books stored at:
  - `/volume1/Media/books-text/Beletry/<author>/<title>/`
  - `/volume1/Media/books-text/Fiction/<author>/<title>/`
  - `/volume1/Media/books-text/Education/<author>/<title>/`

## Target State

- 1 calibre-web container
- 1 unified `metadata.db` (new, in a separate location)
- Books stay in their original directories (not moved)
- Categories (Beletry/Fiction/Education) become Calibre custom columns or tags
- Single URL: `https://calibre.${LOCAL_DOMAIN}`

## Tasks

- [ ] Create a new unified Calibre library directory
      (e.g., `/volume1/Media/books-text/.unified/`)
- [ ] Write a migration script that:
  - [ ] Reads `metadata.db` from each sub-library
  - [ ] Merges book metadata into the unified DB
  - [ ] Adds a custom column or tag for the source library name
  - [ ] Creates symlinks from unified library structure to actual book files
        (or uses Calibre's `path` field to reference original locations)
- [ ] Test with a copy of the data first (non-destructive)
- [ ] Update compose.yaml to single container mounting:
      `/volume1/Media/books-text:/books:ro` with unified DB
- [ ] Update Traefik routing to single `calibre.${LOCAL_DOMAIN}`
- [ ] Remove extra config volumes and containers
- [ ] Keep original `metadata.db` files intact as backup
- [ ] Update ingest script to add to unified library with correct tags

## Considerations

- Calibre stores book paths relative to the library root. With books in
  subdirectories (Beletry/Fiction/Education), the unified library needs
  to be at `/volume1/Media/books-text/` (parent of all sub-libraries)
  so relative paths resolve correctly.
- Calibre-web's "Categories" or a custom column can replace the directory-
  based separation.
- The migration is one-time but the ingest script needs updating to tag
  incoming books by inbox subfolder.
- Keep the 3-container setup as fallback until unified is proven stable.

## Migration Script Outline

```python
#!/usr/bin/env python3
"""Merge multiple Calibre libraries into one unified library."""
import sqlite3
import shutil
from pathlib import Path

LIBRARIES = {
    "Beletry": Path("/volume1/Media/books-text/Beletry"),
    "Fiction": Path("/volume1/Media/books-text/Fiction"),
    "Education": Path("/volume1/Media/books-text/Education"),
}
UNIFIED = Path("/volume1/Media/books-text/.unified")

# For each source library:
#   1. Read metadata.db
#   2. For each book, insert into unified DB
#   3. Set custom column "library" = source name
#   4. Adjust path to include source prefix (Beletry/Author/Title)
```
