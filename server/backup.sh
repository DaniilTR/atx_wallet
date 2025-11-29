#!/usr/bin/env bash
set -euo pipefail

# Backup MongoDB database into the Windows path of this repo
# Output folder: /mnt/d/atx_wallet/server/db_backup_<YYYY-MM-DD_HH-MM-SS>

# Resolve repo path inside WSL
REPO_PATH="/mnt/d/atx_wallet"
SERVER_PATH="$REPO_PATH/server"
ENV_FILE="$SERVER_PATH/.env"
BACKUP_DIR_BASE="$SERVER_PATH"
TIMESTAMP=$(date +%F_%H-%M-%S)
OUT_DIR="$BACKUP_DIR_BASE/db_backup_$TIMESTAMP"

# Load env if present
if [[ -f "$ENV_FILE" ]]; then
  # shellcheck disable=SC1090
  source "$ENV_FILE"
fi

# Defaults if not set in .env
DB_NAME=${DB_NAME:-atx_wallet}
MONGODB_URI=${MONGODB_URI:-"mongodb://localhost:27017"}

mkdir -p "$OUT_DIR"

echo "Backing up MongoDB..."
echo " DB_NAME: $DB_NAME"
echo " URI: $MONGODB_URI"
echo " OUT_DIR: $OUT_DIR"

# Run mongodump
mongodump \
  --uri "$MONGODB_URI" \
  --db "$DB_NAME" \
  --out "$OUT_DIR"

# Optional: compress result
TAR_FILE="$BACKUP_DIR_BASE/db_backup_$TIMESTAMP.tar.gz"

tar -C "$BACKUP_DIR_BASE" -czf "$TAR_FILE" "$(basename "$OUT_DIR")"

echo "Backup completed: $OUT_DIR"
echo "Archive created: $TAR_FILE"
