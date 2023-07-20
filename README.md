# Plausible Analytics hosting for Laravel Forge using Traefik

[![Laravel Forge Site Deployment Status](https://img.shields.io/endpoint?url=https%3A%2F%2Fforge.laravel.com%2Fsite-badges%2F695965e9-3e86-4ebf-92e4-39ea173070f3%3Fdate%3D1%26commit%3D1&style=plastic)](https://forge.laravel.com/servers/699880/sites/2038760)

This repo is a fork of Plausible's hosting repo,[https://github.com/plausible/hosting](https://github.com/plausible/hosting).

It contains a modifications to the original repo to make it work with Laravel Forge and Traefik. Modifications are exclusively in the [`/reverse-proxy/traefik/docker-compose.traefik.yml`](/reverse-proxy/traefik/docker-compose.traefik.yml) file, except for a single change in the main [`docker-compose.yml`](/docker-compose.yml) file that tells Plausible to use `.env` for environmental variables. Using the `.env` file allows you to use Laravel Forge's built-in environmental variables editor.

Here is a link to the Traefik repo used in conjunction with this repo:

https://github.com/johnfmorton/traefik-for-laravel-forge

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


## Reference links

I referenced and borrowed from all of the following links. I'm grateful the authors have all shared their knowledge.

* https://blog.jpat.dev/how-to-deploy-docker-applications-with-laravel-forge
* https://putyourlightson.com/articles/replacing-google-analytics-with-self-hosted-analytics
* https://plausible.io/docs/self-hosting
* https://www.digitalocean.com/community/tutorials/how-to-use-traefik-as-a-reverse-proxy-for-docker-containers-on-ubuntu-20-04


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
