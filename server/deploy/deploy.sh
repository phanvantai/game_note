#!/usr/bin/env bash
# Builds and (re)starts the API on the VPS. Run from anywhere:
#   server/deploy/deploy.sh
set -euo pipefail

HOST="${DEPLOY_HOST:-examino-dev}"
REMOTE_DIR=/opt/game-note
SERVER_DIR="$(cd "$(dirname "$0")/.." && pwd)"

ssh "$HOST" mkdir -p "$REMOTE_DIR/server"
rsync -az --delete \
  --exclude node_modules --exclude dist --exclude .env --exclude '*.service-account.json' \
  "$SERVER_DIR/" "$HOST:$REMOTE_DIR/server/"

ssh "$HOST" bash -s <<REMOTE
set -euo pipefail
cd $REMOTE_DIR/server/deploy
if [ ! -f .env ]; then
  umask 077
  cat > .env <<ENV
POSTGRES_PASSWORD=\$(openssl rand -hex 24)
API_HOST=\${API_HOST:-gamenote-api.taiphanvan.dev}
ENV
  echo "Created $REMOTE_DIR/server/deploy/.env"
fi
docker compose up -d --build
docker image prune -f >/dev/null
install -m 755 backup.sh $REMOTE_DIR/backup.sh
{ crontab -l 2>/dev/null | grep -v 'game-note/backup.sh' || true; echo '17 3 * * * $REMOTE_DIR/backup.sh >> $REMOTE_DIR/backup.log 2>&1'; } | crontab -
docker compose ps
REMOTE
