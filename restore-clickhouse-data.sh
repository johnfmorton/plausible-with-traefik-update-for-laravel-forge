#!/bin/bash

# Get the directory of the script
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"

# Load the environment variables
source "$DIR/.env"

# Define the container name
# Look for POSTGRES_CONTAINER_NAME and set to default if not found
if [ -z ${CLICKHOUSE_CONTAINER_NAME+x} ]; then
    CLICKHOUSE_CONTAINER_NAME="analytics-plausible_events_db-1"
fi

# create a timestamp variable
timestamp=$(date +%Y-%m-%d-%H-%M-%S)

# Extract the file name from the backup file path
BACKUP_FILE_PATH=$1
BACKUP_FILE_NAME=$(basename $BACKUP_FILE_PATH)
# using a timestamp in the file name prevents overwriting other possible files in the container backup directory with the same name
BACKUP_FILE_NAME_TIMESTAMPED=${timestamp}-$(basename $BACKUP_FILE_PATH)

if [ -z ${LOCAL_BACKUP_PATH+x} ]; then
    echo "CLICKHOUSE_CONTAINER_NAME is unset in your .env file. Using default of analytics-plausible_events_db-1."
fi

CONTAINER_NAME=${CLICKHOUSE_CONTAINER_NAME}

# copy the BACKUP_FILE_NAME_TIMESTAMPED to the container /tmp directory

docker cp ${BACKUP_FILE_PATH} ${CONTAINER_NAME}:/backups/${BACKUP_FILE_NAME_TIMESTAMPED}

# restore the database from the backup file
# working example
# docker exec hosting-plausible_events_db-1 clickhouse-client --query "RESTORE DATABASE plausible_events_db FROM Disk('backups', 'plausible_events_db_backup.zip') SETTINGS allow_non_empty_tables=true"
docker exec $CONTAINER_NAME clickhouse-client --query "RESTORE DATABASE plausible_events_db FROM Disk('backups', '${BACKUP_FILE_NAME_TIMESTAMPED}') SETTINGS allow_non_empty_tables=true"

# remove the backup file from the container
docker exec $CONTAINER_NAME /bin/bash -c "rm /backups/${BACKUP_FILE_NAME_TIMESTAMPED}"

# check for success
if [ $? -eq 0 ]; then
  echo "Successfully restored the Plausible Event database from ${BACKUP_FILE_PATH}."
else
  echo "Failed to restore the Plausible Event database from ${BACKUP_FILE_PATH}."
  exit 1
fi
