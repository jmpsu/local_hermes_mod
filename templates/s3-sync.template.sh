#!/bin/bash
set -euo pipefail

export AWS_ACCESS_KEY_ID="${AWS_ID}"
export AWS_SECRET_ACCESS_KEY="${AWS_KEY}"
export AWS_DEFAULT_REGION="${AWS_REG}"

BACKUP_DIR="/tmp/joeysvault-backups"
mkdir -p "$BACKUP_DIR"

echo "=== Packaging Chat Histories and Vector Store Artifacts ==="
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
TAR_FILE="$BACKUP_DIR/backup_$TIMESTAMP.tar.gz"

tar -czf "$TAR_FILE" -C /var/lib/docker/volumes/ open-webui-storage qdrant-storage 2>/dev/null || true

echo "=== Syncing Archive Matrix to Amazon S3 Bucket ==="
if command -v aws &> /dev/null; then
    aws s3 cp "$TAR_FILE" "s3://${AWS_BUCKET}/vps-backups/backup_$TIMESTAMP.tar.gz"
else
    docker run --rm \
      -e AWS_ACCESS_KEY_ID -e AWS_SECRET_ACCESS_KEY -e AWS_DEFAULT_REGION \
      -v "$BACKUP_DIR:/data" \
      amazon/aws-cli s3 cp "/data/backup_$TIMESTAMP.tar.gz" "s3://${AWS_BUCKET}/vps-backups/backup_$TIMESTAMP.tar.gz"
fi

rm -f "$TAR_FILE"
echo "✓ Sync operation completed successfully."
