#!/bin/bash

# This file is meant to be run as root or with sudo
# It will create a backup of the clickhouse data and store it in the local backup directory
# It will also change the ownership of the backup files to the forge user which is why it requires sudo or root privilages
# The script is intended to be run as a cron job

# The Postgres database backup directory backup script will be added in the next major update to this script

# Load the environment variables
source .env

# Create the local backup directory if is does not exist
mkdir -p ${LOCAL_BACKUP_PATH}${LOCAL_CLICKHOUSE_PATH}

# create a timestamp variable
timestamp=$(date +%Y-%m-%d-%H-%M-%S)


# Define the container name
# Look for POSTGRES_CONTAINER_NAME and set to default if not found
if [ -z ${CLICKHOUSE_CONTAINER_NAME+x} ]; then
    CLICKHOUSE_CONTAINER_NAME="analytics-plausible_events_db-1"
fi

# Look for env LOCAL_BACKUP_RETENTION_DAYS and set default if not found
if [ -z ${LOCAL_BACKUP_RETENTION_DAYS+x} ]; then
    LOCAL_BACKUP_RETENTION_DAYS=7
fi


# clickhouse-client --query "BACKUP DATABASE plausible_events_db TO Disk('backups', 'plausible_events_db_backup.zip')"
docker exec -it $CONTAINER_NAME clickhouse-client --query "BACKUP DATABASE plausible_events_db TO Disk('backups', 'plausible_events_db_backup_${timestamp}.zip')"

# Copy the backup file from Docker container to the server
docker cp $CONTAINER_NAME:/var/lib/clickhouse/backups/plausible_events_db_backup_${timestamp}.zip ${LOCAL_BACKUP_PATH}${LOCAL_CLICKHOUSE_PATH}

# Remove the backup file from inside the Docker container
docker exec $CONTAINER_NAME /bin/bash -c "rm /var/lib/clickhouse/backups/plausible_events_db_backup_${timestamp}.zip"

# change the ownership of the created backup files to the forge user
chown -R forge:forge ${LOCAL_BACKUP_PATH}${LOCAL_POSTGRES_PATH}

echo 'Pruning old Plausible Event database backups to max age of '${LOCAL_BACKUP_RETENTION_DAYS}' days.'
find ${LOCAL_BACKUP_PATH}${LOCAL_POSTGRES_PATH} -type f -mtime +${LOCAL_BACKUP_RETENTION_DAYS} -exec rm {} \;

# check for success
if [ $? -eq 0 ]; then
    echo "Successfully backed up the Plausible Event database to ${LOCAL_BACKUP_PATH}${LOCAL_POSTGRES_PATH}."
else
    echo "Failed to backup the Plausible Event database."
    exit 1
fi