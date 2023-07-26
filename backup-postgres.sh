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
mkdir -p ${LOCAL_BACKUP_PATH}${LOCAL_POSTGRES_PATH}

# create a timestamp variable
timestamp=$(date +%Y-%m-%d-%H-%M-%S)

# The command must run as root to access the internal clickhouse data backup directory
# docker run --rm -it --network analytics_default -v "${LOCAL_BACKUP_PATH}${LOCAL_CLICKHOUSE_PATH}:/var/lib/clickhouse/backup/" \
#    -e CLICKHOUSE_HOST="plausible_events_db" \
#    altinity/clickhouse-backup create clickhouse-backup-${timestamp}

# change the ownership of the created backup files to the forge user
#chown -R forge:forge /home/forge/analytics/backups/clickhouse-data

# delete backups older than 30 days
#find ${LOCAL_BACKUP_PATH}${LOCAL_CLICKHOUSE_PATH} -type f -mtime +30 -name '*.tar' -delete

# The command to run inside the Docker container
# pg_dump -h plausible_db -p 5432 -U postgres -F t -b -v -f "/path/to/your/backup_file.tar" plausible_db
# mkdir -p /var/lib/postgresql/backups/
# pg_dump -h plausible_db -p 5432 -U postgres -F t -b -v -f "/var/lib/postgresql/backups/backup_file_2.tar" plausible_db


# The command must run as root to access the internal clickhouse data backup directory
# docker run --rm -it --network analytics_default -v "${LOCAL_BACKUP_PATH}${LOCAL_POSTGRES_PATH}:/var/lib/postgresql/backups/" \
#   pg_dump -h plausible_db -p 5432 -U postgres -F t -b -v -f "/var/lib/postgresql/backups/analytics_data_file-${timestamp}.tar" plausible_db

# Run Docker command
#docker run --rm -v ${LOCAL_BACKUP_PATH}${LOCAL_POSTGRES_PATH}:/var/lib/postgresql/backups postgres /bin/bash -c "mkdir -p /var/lib/postgresql/backups/ && PGPASSWORD=postgres pg_dump -h plausible_db -p 5432 -U postgres -F t -b -v -f /var/lib/postgresql/backups/backup_file_2.tar plausible_db"


docker exec analytics-plausible_db-1 /bin/bash -c "mkdir -p /var/lib/postgresql/backups/ && PGPASSWORD=postgres pg_dump -h localhost -p 5432 -U postgres -F t -b -v -f /var/lib/postgresql/backups/backup_f${timestamp}tar plausible_db"


# Copy the backup file from Docker container to the server
docker cp analytics-plausible_db-1:/var/lib/postgresql/backups/backup_${timestamp}.tar ${LOCAL_BACKUP_PATH}${LOCAL_POSTGRES_PATH}
