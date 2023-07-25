#!/bin/bash

# This file is meant to be run as root or with sudo
# It will create a backup of the clickhouse data and store it in the local backup directory
# It will also change the ownership of the backup files to the forge user which is why it requires sudo or root privilages
# The script is intended to be run as a cron job

# The Postgres database backup directory backup script will be added in the next major update to this script

# Load the environment variables
source .env

# docker run -u $(id -u clickhouse) --rm -it --network host -v "/var/lib/clickhouse:/var/lib/clickhouse" \
#    -e CLICKHOUSE_PASSWORD="password" \
#    -e S3_BUCKET="clickhouse-backup" \
#    -e S3_ACCESS_KEY="access_key" \
#    -e S3_SECRET_KEY="secret" \
#    altinity/clickhouse-backup --help

# Create the local backup directory if is does not exist
mkdir -p ${LOCAL_BACKUP_PATH}

# create a timestamp variable
timestamp=$(date +%Y-%m-%d-%H-%M-%S)

# The command must run as root to access the internal clickhouse data backup directory
docker run --rm -it --network analytics_default -v "${LOCAL_BACKUP_PATH}:/var/lib/clickhouse/backup/" \
   -e CLICKHOUSE_HOST="plausible_events_db" \
   altinity/clickhouse-backup create clickhouse-backup-${timestamp}

# change the ownership of the created backup files to the forge user
chown -R forge:forge /home/forge/analytics/backups/clickhouse-data

# delete backups older than 30 days
find ${LOCAL_BACKUP_PATH} -type f -mtime +30 -name '*.tar' -delete
