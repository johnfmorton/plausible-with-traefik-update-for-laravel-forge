cd /home/forge/analytics

# We are assuming Docker has been installed, which is installed upon server creation
# using the "Install Docker and Docker-Compose" recipe.

# the "Make .env variables available to deploy script" is check in Laravel Forge

echo "Deploying: ${APP_NAME} at ${BASE_URL}"
echo "commit @${FORGE_DEPLOY_COMMIT} -- ${FORGE_DEPLOY_MESSAGE}"

if [[ $FORGE_MANUAL_DEPLOY -eq 1 ]]; then
    echo "This deploy was triggered manually."
fi

git pull origin $FORGE_SITE_BRANCH

echo "Docker up with docker-compose.yml combined with reverse-proxy/traefik/docker-compose.traefik.yml"
docker-compose -f docker-compose.yml -f reverse-proxy/traefik/docker-compose.traefik.yml up -d --remove-orphans

echo "Deploy complete."
