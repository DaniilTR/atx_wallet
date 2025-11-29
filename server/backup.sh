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
  source "$ENVrfr_FILE"
fi

# Defaults if not set in .env
DB_NAME=${DB_NAME:-atx_wallet}
MONGODB_URI=${MONGODB_URI:-"mongodb://localhost:27017"}
USERNAME=${USERNAME:-}
PASSWORD=${PASSWORD:-}
AUTH_DB=${AUTH_DB:-admin}

mkdir -p "$OUT_DIR"

echo "Backing up MongoDB..."
echo " DB_NAME: $DB_NAME"
echo " URI: $MONGODB_URI"
echo " OUT_DIR: $OUT_DIR"

# Ensure mongodump exists
if ! command -v mongodump >/dev/null 2>&1; then
  echo "ERROR: mongodump not found in PATH. Install MongoDB Database Tools." >&2
  rmdir "$OUT_DIR" 2>/dev/null || true
  exit 1
fi

# Run mongodump
LOG_FILE="$OUT_DIR/mongodump.log"
{
  echo "$(date -Iseconds) Running mongodump..."
  echo "URI=$MONGODB_URI"; echo "DB=$DB_NAME"; echo "AUTH_DB=$AUTH_DB"; echo "USER=$USERNAME";
  # Build args
  ARGS=(
    --uri "$MONGODB_URI"
    --db "$DB_NAME"
    --out "$OUT_DIR"
  )
  # Only set authenticationDatabase if not provided in URI
  if [[ "$MONGODB_URI" != *"authSource="* ]]; then
    ARGS+=(--authenticationDatabase "$AUTH_DB")
  fi
  if [ -n "$USERNAME" ]; then ARGS+=(--username "$USERNAME"); fi
  if [ -n "$PASSWORD" ]; then ARGS+=(--password "$PASSWORD"); fi

  mongodump "${ARGS[@]}"
} &> "$LOG_FILE" || {
  echo "ERROR: mongodump failed. See log: $LOG_FILE" >&2
  # If failed, and directory is empty, remove it for cleanliness
  if [ -z "$(ls -A "$OUT_DIR" 2>/dev/null)" ]; then
    rmdir "$OUT_DIR" 2>/dev/null || true
  fi
  exit 1
}

# Warn if dump is empty (e.g., no collections or wrong DB)
if [ -z "$(ls -A "$OUT_DIR" 2>/dev/null)" ]; then
  echo "WARNING: Dump completed but output directory is empty."
  echo "Check DB name, URI, and permissions. Log: $LOG_FILE"
fi

# Optional: compress result
TAR_FILE="$BACKUP_DIR_BASE/db_backup_$TIMESTAMP.tar.gz"

# Only archive if there is content
if [ -n "$(ls -A "$OUT_DIR" 2>/dev/null)" ]; then
  tar -C "$BACKUP_DIR_BASE" -czf "$TAR_FILE" "$(basename "$OUT_DIR")"
  echo "Archive created: $TAR_FILE"
else
  echo "Skip archiving: output directory is empty"
fi

echo "Backup completed: $OUT_DIR"
