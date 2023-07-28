#!/bin/bash

# *This file is meant to be run as root or with sudo*
# It will backup the Postgres database to the local server

# confirm that use is root or sudo, if not exit
if [ "$EUID" -ne 0 ]
  then echo "Please run as root or with sudo"
  exit
fi

# Get the directory of the script
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"

# Load the environment variables
source "$DIR/.env"

# Look for LOCAL_CLICKHOUSE_PATH and exit if not found
if [ -z ${LOCAL_BACKUP_PATH+x} ]; then
    echo "LOCAL_BACKUP_PATH is unset. Please set this in your .env file."
    exit 1
fi
if [ -z ${LOCAL_POSTGRES_PATH+x} ]; then
    echo "LOCAL_POSTGRES_PATH is unset. Please set this in your .env file."
    exit 1
fi

# Create the local backup directory if is does not exist
mkdir -p ${LOCAL_BACKUP_PATH}${LOCAL_POSTGRES_PATH}

# create a timestamp variable
timestamp=$(date +%Y-%m-%d-%H-%M-%S)

# Define the container name
# Look for POSTGRES_CONTAINER_NAME and set to default if not found
if [ -z ${POSTGRES_CONTAINER_NAME+x} ]; then
    POSTGRES_CONTAINER_NAME="analytics-plausible_db-1"
fi

CONTAINER_NAME=${POSTGRES_CONTAINER_NAME}

# Look for env LOCAL_BACKUP_RETENTION_DAYS and set default if not found
if [ -z ${LOCAL_BACKUP_RETENTION_DAYS+x} ]; then
    LOCAL_BACKUP_RETENTION_DAYS=7
fi

docker exec $CONTAINER_NAME /bin/bash -c "mkdir -p /var/lib/postgresql/backups/ && PGPASSWORD=postgres pg_dump -h localhost -p 5432 -U postgres -F t -b -v -f /var/lib/postgresql/backups/plausible_db_backup_${timestamp}.tar plausible_db"

# Copy the backup file from Docker container to the server
echo "Copying the backup file, plausible_events_db_backup_${timestamp}.zip, from Docker container to the local backup directory."
docker cp $CONTAINER_NAME:/var/lib/postgresql/backups/plausible_db_backup_${timestamp}.tar ${LOCAL_BACKUP_PATH}${LOCAL_POSTGRES_PATH}

# Remove the backup file from inside the Docker container
echo "Removing the backup file, plausible_events_db_backup_${timestamp}.zip, from inside the Docker container."
docker exec $CONTAINER_NAME /bin/bash -c "rm /var/lib/postgresql/backups/plausible_db_backup_${timestamp}.tar"

echo 'Pruning old Plausible Primary database backups to max age of '${LOCAL_BACKUP_RETENTION_DAYS}' days.'
find ${LOCAL_BACKUP_PATH}${LOCAL_POSTGRES_PATH} -type f -mtime +${LOCAL_BACKUP_RETENTION_DAYS} -exec rm {} \;

# change the ownership of the created backup files to the forge user
echo "Changing the ownership of the created backup files to the forge user."
chown -R forge:forge ${LOCAL_BACKUP_PATH}

# check for success
if [ $? -eq 0 ]; then
    echo "Successfully backed up the Plausible Primary database to ${LOCAL_BACKUP_PATH}${LOCAL_POSTGRES_PATH}."
else
    echo "Failed to backup the Plausible Primary database."
    exit 1
fi
