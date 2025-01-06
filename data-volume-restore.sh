#!/bin/bash

# reference:
# https://macarthur.me/posts/back-up-plausible-to-bucket/
# https://plausiblebootstrapper.com/posts/back-up-plausible
# https://plausiblebootstrapper.com/posts/back-up-plausible-to-bucket

# Load configuration variables
# RETENTION_DAYS, BACKUP_DIR, EMAIL must be present
CONFIG_FILE=".env"
if [ -f "$CONFIG_FILE" ]; then
  source "$CONFIG_FILE"
else
  echo "Configuration file not found: $CONFIG_FILE" >&2
  exit 1
fi

# Confirm required variables are set
REQUIRED_VARS=("RETENTION_DAYS" "BACKUP_DIR")
for VAR in "${REQUIRED_VARS[@]}"; do
  if [ -z "${!VAR}" ]; then
    echo "Error: Required variable $VAR is not set in $CONFIG_FILE" >&2
    exit 1
  fi
done

# Variables
TIMESTAMP=$(date +"%Y%m%d%H%M%S")
LOG_FILE="$BACKUP_DIR/restore_log_$TIMESTAMP.log"

# Parse script arguments
while getopts "d:e:" opt; do
  case $opt in
    d) DB_BACKUP="$OPTARG" ;;
    e) EVENT_BACKUP="$OPTARG" ;;
    *)
      echo "Usage: $0 [-d database_backup_file] [-e event_data_backup_file]" >&2
      exit 1
      ;;
  esac
done

# Locate the latest backup files if not provided
if [ -z "$DB_BACKUP" ]; then
  echo -e "\033[1;32mTip: You can specify filenames with arguments. Usage: $0 [-d database_backup_file] [-e event_data_backup_file]\033[0m" | tee -a "$LOG_FILE"
  DB_BACKUP=$(ls -t "$BACKUP_DIR"/analytics_db-data_*.tar.bz2 2>/dev/null | head -n 1)
fi
if [ -z "$EVENT_BACKUP" ]; then
  EVENT_BACKUP=$(ls -t "$BACKUP_DIR"/analytics_event-data_*.tar.bz2 2>/dev/null | head -n 1)
fi

# Check if backups are found
if [ -z "$DB_BACKUP" ] || [ -z "$EVENT_BACKUP" ]; then
  echo "Error: Backup files not found in $BACKUP_DIR. Ensure backups are available." | tee -a "$LOG_FILE"
  exit 1
fi

if [ -z "$OPTARG" ]; then
  echo "Found backup files: $DB_BACKUP, $EVENT_BACKUP" | tee -a "$LOG_FILE"
fi

# Confirm with user before restoring
echo "Do you want to restore the following backup files?" | tee -a "$LOG_FILE"
echo -e "Database backup: \033[1;34m$DB_BACKUP\033[0m" | tee -a "$LOG_FILE"
echo -e "Event data backup: \033[1;34m$EVENT_BACKUP\033[0m" | tee -a "$LOG_FILE"
read -t 30 -p "Type 'yes' to confirm, or anything else to cancel (timeout in 30 seconds): " CONFIRMATION
if [ "$CONFIRMATION" != "yes" ]; then
  echo "Restore process canceled by user or timed out." | tee -a "$LOG_FILE"
  exit 0
fi

# Turn off docker containers. Important!
docker compose down
if [ $? -eq 0 ]; then
  echo "Containers are now offline for the restore process." | tee -a "$LOG_FILE"
else
  echo "Failed to stop containers. Please check manually." | tee -a "$LOG_FILE"
  exit 1
fi

# Restore the data volumes
echo "Restoring database volume from $DB_BACKUP..." | tee -a "$LOG_FILE"
docker run -i -v analytics_db-data:/volume --rm loomchild/volume-backup restore -f < "$DB_BACKUP"
if [ $? -eq 0 ]; then
  echo "Database volume restored successfully." | tee -a "$LOG_FILE"
else
  echo "Failed to restore database volume. Check logs for details." | tee -a "$LOG_FILE" >&2
  exit 1
fi

echo "Restoring event data volume from $EVENT_BACKUP..." | tee -a "$LOG_FILE"
docker run -i -v analytics_event-data:/volume --rm loomchild/volume-backup restore -f < "$EVENT_BACKUP"
if [ $? -eq 0 ]; then
  echo "Event data volume restored successfully." | tee -a "$LOG_FILE"
else
  echo "Failed to restore event data volume. Check logs for details." | tee -a "$LOG_FILE" >&2
  exit 1
fi

# Turn on containers again.
# Ensure the docker-compose configuration is up to date before starting
CONFIG_FILES="docker-compose.yml reverse-proxy/traefik/docker-compose.traefik.yml"
echo "Validating docker-compose configuration files: $CONFIG_FILES" | tee -a "$LOG_FILE"
for CONFIG in $CONFIG_FILES; do
  if [ ! -f "$CONFIG" ]; then
    echo "Error: Missing configuration file: $CONFIG" | tee -a "$LOG_FILE" >&2
    exit 1
  fi
  echo "Configuration file exists: $CONFIG" | tee -a "$LOG_FILE"
done

docker-compose -f docker-compose.yml -f reverse-proxy/traefik/docker-compose.traefik.yml up -d --remove-orphans
if [ $? -eq 0 ]; then
  echo "Containers are back online." | tee -a "$LOG_FILE"
else
  echo "Failed to bring containers back online. Please check manually." | tee -a "$LOG_FILE"
fi
