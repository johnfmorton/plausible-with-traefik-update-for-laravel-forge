#!/bin/bash

# Load the environment variables
source /path/to/.env

# docker run -u $(id -u clickhouse) --rm -it --network host -v "/var/lib/clickhouse:/var/lib/clickhouse" \
#    -e CLICKHOUSE_PASSWORD="password" \
#    -e S3_BUCKET="clickhouse-backup" \
#    -e S3_ACCESS_KEY="access_key" \
#    -e S3_SECRET_KEY="secret" \
#    altinity/clickhouse-backup --help

# Create the local backup directory if is does not exist
mkdir -p ${LOCAL_BACKUP_PATH}

# docker run -u $(id -u forge) --rm -it --network analytics_default -v "/home/forge/analytics/backups/clickhouse-data/:/var/lib/clickhouse/backup/" \
# -e CLICKHOUSE_HOST="plausible_events_db" \
#   altinity/clickhouse-backup create mybackup323pm

# create a timestamp variable
timestamp=$(date +%Y-%m-%d-%H-%M-%S)

# The command must run as root to access the internal clickhouse data backup directory
docker run --rm -it --network analytics_default -v "${LOCAL_BACKUP_PATH}:/var/lib/clickhouse/backup/" \
   -e CLICKHOUSE_HOST="plausible_events_db" \
   altinity/clickhouse-backup create clickhouse-backup-${timestamp}

# change the ownership of the created backup files to the forge user
chown -R forge:forge /home/forge/analytics/backups/clickhouse-data
