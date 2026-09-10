#!/bin/bash

TIMESTAMP=$(date +%Y%m%d_%H%M%S)
BACKUP_DIR="./backups"
BACKUP_FILE="$BACKUP_DIR/backup_$TIMESTAMP.sql"
RETENTION_DAYS=7

mkdir -p "$BACKUP_DIR"

docker exec product-catalog-devops-postgres-1 pg_dumpall -U admin > "$BACKUP_FILE"

gzip "$BACKUP_FILE"

echo "Backup created: $BACKUP_FILE.gz"

find "$BACKUP_DIR" -name "backup_*.sql.gz" -mtime +$RETENTION_DAYS -delete

echo "Old backups (older than $RETENTION_DAYS days) cleaned up."