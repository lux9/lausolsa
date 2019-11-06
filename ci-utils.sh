#!/bin/sh

function fail(){
  echo "Exiting with error: $1"
  exit 1
}

function setup_ssh_agent(){
  which ssh-agent || ( apk add --update --no-cache openssh-client )
  eval `ssh-agent -s`
  mkdir -p ~/.ssh
  echo "${SSH_PRIVATE_KEY}" | tr -d '\r' | ssh-add - > /dev/null
  echo -e "Host *\n\tStrictHostKeyChecking no\n\n" > ~/.ssh/config
}

function build(){
  local IMAGE_TAG=$1

  docker login -u ${CI_REGISTRY_USER} -p ${CI_REGISTRY_PASSWORD} ${CI_REGISTRY}
  docker pull ${CI_REGISTRY_IMAGE}:${IMAGE_TAG} || true
  docker build --cache-from ${CI_REGISTRY_IMAGE}:${IMAGE_TAG} -t ${CI_REGISTRY_IMAGE}:${IMAGE_TAG} .
  docker push ${CI_REGISTRY_IMAGE}:${IMAGE_TAG}
}

function deploy(){
  local USER=$1
  local SERVER=$2

  setup_ssh_agent

  cat docker-compose.yml | ssh ${USER}@${SERVER} -T "cat > ./docker-compose.yml"
  cat traefik.toml | ssh ${USER}@${SERVER} -T "cat > ./traefik.toml"

  ssh ${USER}@${SERVER} "docker login -u gitlab-ci-token -p ${CI_BUILD_TOKEN} ${CI_REGISTRY}" || fail "Unable to login with docker"
  ssh ${USER}@${SERVER} "docker pull ${CI_REGISTRY_IMAGE}:${CI_COMMIT_REF_SLUG}" || fail "Unable to docker pull"
  ssh ${USER}@${SERVER} "docker-compose up -d" || fail "Unable to docker-compose"
  ssh ${USER}@${SERVER} "docker system prune -f --volumes" || echo "Unable to cleanup"
}
