#!/bin/bash

# Load the environment variables
source .env

# Check if backup file was provided
if [ "$#" -ne 1 ]; then
    echo "Usage: $0 /path/to/your/backup_file.tar"
    exit 1
fi

# create a timestamp variable
timestamp=$(date +%Y-%m-%d-%H-%M-%S)

# Extract the file name from the backup file path
BACKUP_FILE_PATH=$1
BACKUP_FILE_NAME=$(basename $BACKUP_FILE_PATH)
# using a timestamp in the file name prevents overwriting other possible files in the container backup directory with the same name
BACKUP_FILE_NAME_TIMESTAMPED=${timestamp}-$(basename $BACKUP_FILE_PATH)

# Copy the backup file from the host to the Docker container
docker cp $BACKUP_FILE_PATH $CONTAINER_NAME:/var/lib/postgresql/backups/$BACKUP_FILE_NAME_TIMESTAMPED

# Restore the database from the backup file inside the Docker container
docker exec $CONTAINER_NAME /bin/bash -c "pg_restore -U postgres -d plausible_db -v -1 /var/lib/postgresql/backups/$BACKUP_FILE_NAME_TIMESTAMPED"

# Remove the backup file from inside the Docker container
docker exec $CONTAINER_NAME /bin/bash -c "rm /var/lib/postgresql/backups/$BACKUP_FILE_NAME_TIMESTAMPED"

# check for success
if [ $? -eq 0 ]; then
    echo "Successfully restored $BACKUP_FILE_NAME to the database"
else
    echo "Failed to restore $BACKUP_FILE_NAME to the database"
    exit 1
fi
