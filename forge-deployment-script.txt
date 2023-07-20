cd /home/forge/analytics

# Echo out the git commit and git commit message
# note that APP_NAME is from the .env file. To get this to work,
# you need to add the APP_NAME to the .env file and also to allow
# "Make .env varialbes available to deply script" is checked in
# the forge deploy script settings.

echo "Deploying: ${APP_NAME}"
echo "@${FORGE_DEPLOY_COMMIT} -- ${FORGE_DEPLOY_MESSAGE}"

if [[ $FORGE_MANUAL_DEPLOY -eq 1 ]]; then
    echo "This deploy was triggered manually."
fi

git pull origin $FORGE_SITE_BRANCH

docker-compose -f docker-compose.yml -f reverse-proxy/traefik/docker-compose.traefik.yml up -d --remove-orphans

echo "Deploy complete."
