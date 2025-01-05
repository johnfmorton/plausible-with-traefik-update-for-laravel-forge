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
REQUIRED_VARS=("RETENTION_DAYS" "BACKUP_DIR" "EMAIL")
for VAR in "${REQUIRED_VARS[@]}"; do
  if [ -z "${!VAR}" ]; then
    echo "Error: Required variable $VAR is not set in $CONFIG_FILE" >&2
    exit 1
  fi
done

# Variables
TIMESTAMP=$(date +"%Y%m%d%H%M%S")
LOG_FILE="$BACKUP_DIR/backup_log_$TIMESTAMP.log"

# Create "backups" directory if it doesn't already exist.
echo "Creating backups directory if it does not exist..." | tee -a "$LOG_FILE"
mkdir -p "$BACKUP_DIR" >/dev/null 2>&1
if [ $? -eq 0 ]; then
  echo "Backups directory is ready." | tee -a "$LOG_FILE"
else
  echo "Failed to create backups directory." | tee -a "$LOG_FILE"
  echo -e "Subject: Backup Script Failure\n\nThe backup script failed to create the backups directory. Check log file at $LOG_FILE." | sendmail "$EMAIL"
  exit 1
fi

# Turn off docker containers. Important!
docker compose down
if [ $? -eq 0 ]; then
  echo "Containers are now offline for the backup process." | tee -a "$LOG_FILE"
else
  echo "Failed to stop containers. Please check manually." | tee -a "$LOG_FILE"
  echo -e "Subject: Backup Script Failure\n\nThe backup script failed to stop containers. Check log file at $LOG_FILE." | sendmail "$EMAIL"
  exit 1
fi

# Back up the data volumes

echo "Backing up data volumes..." | tee -a "$LOG_FILE"
docker run -v analytics_db-data:/volume --rm --log-driver none loomchild/volume-backup backup > "$BACKUP_DIR/analytics_db-data_$TIMESTAMP.tar.bz2"
if [ $? -eq 0 ]; then
  echo "Successfully backed up analytics_db-data to $BACKUP_DIR/analytics_db-data_$TIMESTAMP.tar.bz2." | tee -a "$LOG_FILE"
else
  echo "Failed to back up analytics_db-data. Please check the logs for details." | tee -a "$LOG_FILE" >&2
fi

docker run -v analytics_event-data:/volume --rm --log-driver none loomchild/volume-backup backup > "$BACKUP_DIR/analytics_event-data_$TIMESTAMP.tar.bz2"
if [ $? -eq 0 ]; then
  echo "Successfully backed up analytics_event-data to $BACKUP_DIR/analytics_event-data_$TIMESTAMP.tar.bz2." | tee -a "$LOG_FILE"
else
  echo "Failed to back up analytics_event-data. Please check the logs for details." | tee -a "$LOG_FILE" >&2
fi

# If you have a volume for logs, you would back it up with the following syntax.
# docker run -v analytics_event-logs:/volume --rm --log-driver none loomchild/volume-backup backup > "$BACKUP_DIR/analytics_event-logs_$TIMESTAMP.tar.bz2"

# Remove backups older than the retention period
echo "Cleaning up backups older than $RETENTION_DAYS days..." | tee -a "$LOG_FILE"
find "$BACKUP_DIR" -type f -mtime +$RETENTION_DAYS -exec sh -c 'echo "Deleting: {}" | tee -a '"$LOG_FILE"' && rm -f {}' \;
if [ $? -eq 0 ]; then
  echo "Cleanup complete." | tee -a "$LOG_FILE"
else
  echo "Failed to clean up old backups. Please check manually." | tee -a "$LOG_FILE" >&2
  echo -e "Subject: Backup Script Failure\n\nThe backup script failed to clean up old backups. Check log file at $LOG_FILE." | sendmail "$EMAIL"
fi


# Turn on containers again.
# Ensure the docker-compose configuration is up to date before starting
CONFIG_FILES="docker-compose.yml reverse-proxy/traefik/docker-compose.traefik.yml"
echo "Validating docker-compose configuration files: $CONFIG_FILES" | tee -a "$LOG_FILE"
for CONFIG in $CONFIG_FILES; do
  if [ ! -f "$CONFIG" ]; then
    echo "Error: Missing configuration file: $CONFIG" | tee -a "$LOG_FILE" >&2
    echo -e "Subject: Backup Script Failure\n\nThe backup script failed due to a missing configuration file: $CONFIG. Check log file at $LOG_FILE." | sendmail "$EMAIL"
    exit 1
  fi
  echo "Configuration file exists: $CONFIG" | tee -a "$LOG_FILE"
done

docker-compose -f docker-compose.yml -f reverse-proxy/traefik/docker-compose.traefik.yml up -d --remove-orphans
if [ $? -eq 0 ]; then
  echo "Containers are back online." | tee -a "$LOG_FILE"
else
  echo "Failed to bring containers back online. Please check manually." | tee -a "$LOG_FILE"
  echo -e "Subject: Backup Script Failure\n\nThe backup script failed to bring containers back online. Check log file at $LOG_FILE." | sendmail "$EMAIL"
fi
