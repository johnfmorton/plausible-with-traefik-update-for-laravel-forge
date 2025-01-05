# Plausible Analytics hosting for Laravel Forge using Traefik

[![Laravel Forge Site Deployment Status](https://img.shields.io/endpoint?url=https%3A%2F%2Fforge.laravel.com%2Fsite-badges%2F695965e9-3e86-4ebf-92e4-39ea173070f3%3Fdate%3D1%26commit%3D1&style=plastic)](https://forge.laravel.com/servers/699880/sites/2038760)

This repo is a fork of Plausible's hosting repo,[https://github.com/plausible/hosting](https://github.com/plausible/hosting).

It contains modifications to the original repo to make it work with Laravel Forge and Traefik. Modifications are primarily in the [`/reverse-proxy/traefik/docker-compose.traefik.yml`](/reverse-proxy/traefik/docker-compose.traefik.yml) file. There are a few changes in the main [`docker-compose.yml`](/docker-compose.yml) file to use `.env` for environmental variables. Using the `.env` file allows you to use Laravel Forge's built-in environmental variables editor. I've also removed exposing ports that were not needed when using Traefik.

The `clickhouse/clickhouse-config.xml` file has been modified from the original to allow the included backup scripts to work.

Here is a link to the Traefik repo used in conjunction with this repo:

https://github.com/johnfmorton/traefik-for-laravel-forge

## The accompanying blog post

For a complete write-up on using this repo, read [*Analytics a different way. Plausible Analytics on Laravel Forge with Traefik and Docker.*](https://supergeekery.com/blog/plausible-analytics-on-laravel-forge-with-traefik-and-docker)

## Laravel Forge preparation

The repo assumes you have Docker installed already. See the [johnfmorton/traefik-for-laravel-forge repo](https://github.com/johnfmorton/traefik-for-laravel-forge#laravel-forge-preparation) for more information.

## DNS setup

You will need to set up DNS to point your domain name with an A record to your server you've created with Laravel Forge. For example, `analytics.yourdomain.com` should point to your server's IP address.

## Setting up the `.env` file

In the .env file, set `BASE_URL` to this domain name. For example, `https://analytics.yourdomain.com`. You *must* include the protocol, either `https://` or `http://` is required by Plausible for this setting.

Use the [`example.env`](/example.env) for reference in setting up the additional environmental variables.

## Laravel Forge Deployment script

Here is a basic version of the deployment script.

```
cd /home/forge/analytics

git pull origin $FORGE_SITE_BRANCH

docker-compose -f docker-compose.yml -f reverse-proxy/traefik/docker-compose.traefik.yml up -d -remove-orphans
```

For a more complete version of the deployment script, see the [`forge-deployment-script.sh`](./forge-deployment-script.sh) file in this repo.

## Backup and restore

In January 2025, I rebuilt the backup and restore scripts entirely. The new scripts are

* data-volume-backup.sh
* data-volume-restore.sh

You MUST set the following environmental variables in the `.env` file for the backup and restore scripts to work.

```
RETENTION_DAYS=7
BACKUP_DIR="/home/forge/backups"
EMAIL="your_email@example.com"
```

The backup script can be run from the command line, or in a cron job. The backup script will back up the Postgres and Clickhouse databases in the [`/backup`](/backup) directory.

The restore script can be run from the command line. It will restore the Postgres and Clickhouse databases from the backup files in the [`/backup`](/backup) directory. The script will look for the most recent backup files in the directory. If you want to specify a different backup file, you can pass the file name as an argument to the script.

```
./data-volume-restore.sh [-d database_backup_file] [-e event_data_backup_file]
```


## Reference links

I referenced and borrowed from all of the following links. I'm grateful the authors have all shared their knowledge.

* https://blog.jpat.dev/how-to-deploy-docker-applications-with-laravel-forge
* https://putyourlightson.com/articles/replacing-google-analytics-with-self-hosted-analytics
* https://plausible.io/docs/self-hosting
* https://www.digitalocean.com/community/tutorials/how-to-use-traefik-as-a-reverse-proxy-for-docker-containers-on-ubuntu-20-04
* https://macarthur.me/posts/back-up-plausible-to-bucket/
* https://plausiblebootstrapper.com/posts/back-up-plausible
* https://plausiblebootstrapper.com/posts/back-up-plausible-to-bucket


## Troubleshooting

During my tests of this repo, I ran into a few issues. I would test building and deploying contains from the command line and also from with the Forge control panel. This caused my server to have a lot of containers and images. I had to remove them a few times.

I'm documenting them here in case they are helpful to others.

I pruned the networks, images and containers on my server like this.

```
docker network prune
```

```
docker image prune
```

```
docker container prune
```

At one point, I needed to stop all the containers so I could start everything again from scratch. Here's how to do that.

```
docker stop $(docker ps -aq)
```

## License

The source code for the site is licensed under the MIT license, which you can find in
the MIT-LICENSE.txt file.
