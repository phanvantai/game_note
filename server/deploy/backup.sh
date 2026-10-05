#!/usr/bin/env bash
# Nightly logical backup of the Game Note database; keeps 14 days.
set -euo pipefail
DIR=/opt/game-note/backups
mkdir -p "$DIR"
docker exec game-note-db-1 pg_dump -U game_note -d game_note --format=custom \
  > "$DIR/game_note-$(date +%Y%m%d-%H%M%S).dump"
find "$DIR" -name 'game_note-*.dump' -mtime +14 -delete
