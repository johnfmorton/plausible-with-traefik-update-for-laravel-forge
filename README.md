# Plausible Analytics hosting for Laravel Forge using Traefik

This repo is a fork of Plausible's hosting repo,[https://github.com/plausible/hosting](https://github.com/plausible/hosting).

It contains a few modifications to the original repo to make it work with Laravel Forge and Traefik. These modifications are primarily around getting Traefik and Plausible agree to use the same network.

Here is a link to the Traefik repo I use in conjunction with this repo:

https://github.com/johnfmorton/traefik-for-laravel-forge

## Laravel Forge preparation

The repo assumes you have Docker installed already. If you don't, you can install it with the following set of commands. You run them as `root` user. The commands are ideally set up as a Recipe in Laravel Forge so that you can reuse them across multiple servers.

```
# Recipe Name: Install Docker and Docker-Compose
# Run as user: root
# Recipe:
sudo apt update
sudo apt install -y apt-transport-https ca-certificates curl software-properties-common
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
UBUNTU_VERSION=$(lsb_release -cs)
sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $UBUNTU_VERSION stable"
apt-cache policy docker-ce
apt install -y docker-ce
systemctl status docker
usermod -aG docker forge
COMPOSE_VERSION=$(curl -s https://api.github.com/repos/docker/compose/releases/latest | grep 'tag_name' | cut -d\" -f4)
sh -c "curl -L https://github.com/docker/compose/releases/download/${COMPOSE_VERSION}/docker-compose-`uname -s`-`uname -m` > /usr/local/bin/docker-compose"
chmod +x /usr/local/bin/docker-compose
```

## Laravel Forge Deployment script


```
cd /home/forge/analytics

git pull origin $FORGE_SITE_BRANCH

docker-compose -f docker-compose.yml -f reverse-proxy/traefik/docker-compose.traefik.yml up -d -remove-orphans
```


## Reference links

I referenced and borrowed from all of the following links. I'm grateful the authors have all shared their knowledge.

* https://putyourlightson.com/articles/replacing-google-analytics-with-self-hosted-analytics
* https://plausible.io/docs/self-hosting
* https://blog.jpat.dev/how-to-deploy-docker-applications-with-laravel-forge
* https://www.digitalocean.com/community/tutorials/how-to-use-traefik-as-a-reverse-proxy-for-docker-containers-on-ubuntu-20-04
