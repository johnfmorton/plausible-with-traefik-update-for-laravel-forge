cd /home/forge/analytics

# We assume Docker has already been installed using the "Install Docker and Docker-Compose" recipe.
# The "Make .env variables available to deploy script" must be checked in Laravel Forge

# Confirm Docker is installed and available
if ! command -v docker &> /dev/null; then
    echo "Docker is not installed. Please install Docker and try again."
    exit 1
fi

echo "Deploying: ${APP_NAME} at ${BASE_URL}"
echo "commit @${FORGE_DEPLOY_COMMIT} -- ${FORGE_DEPLOY_MESSAGE}"

if [[ $FORGE_MANUAL_DEPLOY -eq 1 ]]; then
    echo "This deploy was triggered manually."
fi

git pull origin $FORGE_SITE_BRANCH

echo "Docker up with docker-compose.yml combined with reverse-proxy/traefik/docker-compose.traefik.yml"
docker-compose -f docker-compose.yml -f reverse-proxy/traefik/docker-compose.traefik.yml up -d --remove-orphans

echo "Deploy complete."
