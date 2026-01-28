#!/bin/sh

set -e

# Ensure both source and backup directories are passed
if [ "$#" -ne 2 ]; then
  echo "Usage: $0 <source_dir> <backup_dir>"
  exit 1
fi

SOURCE_DIR="$1"
BACKUP_DIR="$2"

# Normalize directory paths (remove trailing slashes)
SOURCE_DIR="${SOURCE_DIR%/}"
BACKUP_DIR="${BACKUP_DIR%/}"

# Check if the paths exist and are directories
if [ ! -d "$SOURCE_DIR" ]; then
  echo "Source directory does not exist: $SOURCE_DIR"
  exit 1
fi

if [ ! -d "$BACKUP_DIR" ]; then
  echo "Backup directory does not exist: $BACKUP_DIR"
  exit 1
fi

# Print operation details and get user confirmation
echo "\nWARNING: This operation will delete duplicate files in the backup directory!"
echo "Source Directory: $SOURCE_DIR"
echo "Backup Directory: $BACKUP_DIR"
echo "\nThis operation is NOT REVERSIBLE. Files in the backup directory that match"
echo "files in the source directory will be permanently deleted."
printf "\nAre you sure you want to proceed? [y/N]: "
read CONFIRM

case "$CONFIRM" in
Y | y)
  echo "\nProceeding with deduplication..."
  ;;
*)
  echo "\nOperation cancelled by user."
  exit 0
  ;;
esac

# Detect hash command: sha256sum (Linux/QNAP) or shasum -a 256 (macOS)
if command -v sha256sum >/dev/null 2>&1; then
  HASH_CMD="sha256sum"
elif command -v shasum >/dev/null 2>&1; then
  HASH_CMD="shasum -a 256"
else
  echo "No SHA256 hash command found. Please install 'sha256sum' or 'shasum'."
  exit 1
fi

echo "Using hash command: $HASH_CMD"
echo "Comparing and cleaning backup directory..."

# Loop through all files (including hidden ones) in source
# Use LC_ALL=C to avoid locale issues
LC_ALL=C find "$SOURCE_DIR" -type f | while IFS= read -r SOURCE_FILE; do
  REL_PATH="${SOURCE_FILE#$SOURCE_DIR/}"
  BACKUP_FILE="$BACKUP_DIR/$REL_PATH"

  if [ -f "$BACKUP_FILE" ]; then
    SOURCE_HASH=$(eval "$HASH_CMD \"\$SOURCE_FILE\" | awk '{ print \$1 }'")
    BACKUP_HASH=$(eval "$HASH_CMD \"\$BACKUP_FILE\" | awk '{ print \$1 }'")

    if [ "$SOURCE_HASH" = "$BACKUP_HASH" ]; then
      echo "Match found and deleting: $BACKUP_FILE"
      rm -f "$BACKUP_FILE"
    fi
  fi
done

echo ""
printf "Do you want to delete empty folders in backup directory? [Y/n]: "
read RESP
RESP=${RESP:-Y}

case "$RESP" in
Y | y)
  echo "Deleting empty directories in backup..."
  find "$BACKUP_DIR" -type d -empty -exec rmdir {} \;
  echo "Cleanup complete."
  ;;
*)
  echo "Skipping folder cleanup."
  ;;
esac
