# Deploying the Game Note API

The API and its Postgres run as a small docker compose project on the
`examino-dev` VPS, routed by the existing Coolify Traefik (`coolify-proxy`)
through container labels. Both containers are capped at 256 MB because the
VPS also hosts examino dev and staging.

```bash
server/deploy/deploy.sh          # rsync + docker compose up -d --build
ssh examino-dev 'cd /opt/game-note/server/deploy && docker compose logs -f api'
```

- First deploy creates `/opt/game-note/server/deploy/.env` with a random
  `POSTGRES_PASSWORD` and `API_HOST=gamenote-api.taiphanvan.dev`.
- DNS: `gamenote-api.taiphanvan.dev` A → `103.116.38.177` (DNS only). Until it
  exists the API also answers on `gamenote-api.103-116-38-177.sslip.io`.
- Backups: `/opt/game-note/backup.sh` runs nightly at 03:17 (cron) and keeps
  14 days of `pg_dump` files in `/opt/game-note/backups`.
- Restore: `docker exec -i game-note-db-1 pg_restore -U game_note -d game_note --clean < file.dump`

## Importing Firestore data (cutover)

1. Firebase console → Project settings → Service accounts → *Generate new
   private key*; save it as `server/gamenoteapp.service-account.json`
   (git-ignored). The import only reads Firestore.
2. Open a tunnel to the database container:
   ```bash
   DB_IP=$(ssh examino-dev "docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}} {{end}}' game-note-db-1" | awk '{print $1}')
   ssh -N -L 55432:$DB_IP:5432 examino-dev &
   PW=$(ssh examino-dev "grep POSTGRES_PASSWORD /opt/game-note/server/deploy/.env | cut -d= -f2")
   ```
3. Dry run, then import (re-runnable; it replaces everything):
   ```bash
   cd server
   export GOOGLE_APPLICATION_CREDENTIALS=./gamenoteapp.service-account.json
   export PUBLIC_BASE_URL=https://gamenote-api.taiphanvan.dev
   npm run import:firestore -- --dry-run
   DATABASE_URL=postgres://game_note:$PW@localhost:55432/game_note \
     npm run import:firestore -- --avatars-dir ./imported-avatars
   ```
4. Copy re-hosted avatars into the API volume:
   ```bash
   rsync -a imported-avatars/ examino-dev:/tmp/gn-avatars/
   ssh examino-dev 'docker cp /tmp/gn-avatars/. game-note-api-1:/data/avatars/ && rm -rf /tmp/gn-avatars'
   ```
