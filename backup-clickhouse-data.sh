#!/bin/bash

# I have run into instances where clickhouse would not allow me to backup the database. Restarting the docker containers fixed this.
# docker-compose down && docker-compose -f docker-compose.yml -f reverse-proxy/traefik/docker-compose.traefik.yml up -d --remove-orphans

# *This file is meant to be run as root or with sudo*
# It will create a backup of the clickhouse data and store it in the local backup directory
# It will also change the ownership of the backup files to the forge user which is why it requires sudo or root privilages
# The script is intended to be run as a cron job

# confirm that use is root or sudo, if not exit
if [ "$EUID" -ne 0 ]
  then echo "Please run as root or with sudo"
  exit
fi

# Load the environment variables
source .env

# Look for LOCAL_CLICKHOUSE_PATH and exit if not found
if [ -z ${LOCAL_BACKUP_PATH+x} ]; then
    echo "LOCAL_BACKUP_PATH is unset. Please set this in your .env file."
    exit 1
fi
if [ -z ${LOCAL_CLICKHOUSE_PATH+x} ]; then
    echo "LOCAL_CLICKHOUSE_PATH is unset. Please set this in your .env file."
    exit 1
fi

# Create the local backup directory if is does not exist
mkdir -p ${LOCAL_BACKUP_PATH}${LOCAL_CLICKHOUSE_PATH}

# create a timestamp variable
timestamp=$(date +%Y-%m-%d-%H-%M-%S)


# Define the container name
# Look for POSTGRES_CONTAINER_NAME and set to default if not found
if [ -z ${CLICKHOUSE_CONTAINER_NAME+x} ]; then
    CLICKHOUSE_CONTAINER_NAME="analytics-plausible_events_db-1"
fi

CONTAINER_NAME=${CLICKHOUSE_CONTAINER_NAME}

# Look for env LOCAL_BACKUP_RETENTION_DAYS and set default if not found
if [ -z ${LOCAL_BACKUP_RETENTION_DAYS+x} ]; then
    LOCAL_BACKUP_RETENTION_DAYS=7
fi


# clickhouse-client --query "BACKUP DATABASE plausible_events_db TO Disk('backups', 'plausible_events_db_backup.zip')"
docker exec -it $CONTAINER_NAME clickhouse-client --query "BACKUP DATABASE plausible_events_db TO Disk('backups', 'plausible_events_db_backup_${timestamp}.zip')"


# Copy the backup filec from Docker container to the server
echo "Copying the backup file, plausible_events_db_backup_${timestamp}.zip, from Docker container to the local backup directory."
docker cp $CONTAINER_NAME:/backups/plausible_events_db_backup_${timestamp}.zip ${LOCAL_BACKUP_PATH}${LOCAL_CLICKHOUSE_PATH}plausible_events_db_backup_${timestamp}.zip

#docker cp analytics-plausible_events_db-1:/backups/test.txt /home/forge/analytics/backups/clickhouse-data/clickhouse-data/

## check for success
if [ $? -eq 0 ]; then
  echo "Successfully copied up the Plausible Event database to ${LOCAL_BACKUP_PATH}${LOCAL_CLICKHOUSE_PATH}plausible_events_db_backup_${timestamp}.zip."
else
  echo "Failed to copy the Plausible Event database."
  exit 1
fi

# Remove the backup file from inside the Docker container
echo "Removing the backup file, plausible_events_db_backup_${timestamp}.zip, from inside the Docker container."
docker exec $CONTAINER_NAME /bin/bash -c "rm ./backups/plausible_events_db_backup_${timestamp}.zip"
# I need to change the ownership of the backups directory back to root:root
docker exec $CONTAINER_NAME /bin/bash -c "chown -R root:root /backups"


echo 'Pruning old Plausible Event database backups to max age of '${LOCAL_BACKUP_RETENTION_DAYS}' days.'
find ${LOCAL_BACKUP_PATH}${LOCAL_POSTGRES_PATH} -type f -mtime +${LOCAL_BACKUP_RETENTION_DAYS} -exec rm {} \;

# change the ownership of the created backup files to the forge user
echo "Changing the ownership of the created backup files to the forge user."
chown -R forge:forge ${LOCAL_BACKUP_PATH}

# check for success
if [ $? -eq 0 ]; then
    echo "Successfully backed up the Plausible Event database to ${LOCAL_BACKUP_PATH}${LOCAL_POSTGRES_PATH}."
else
    echo "Failed to backup the Plausible Event database."
    exit 1
fi
