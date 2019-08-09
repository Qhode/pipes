#!/bin/bash -e

login() {
  if [ ! -z "$RT_URL" ] && [ ! -z "$RT_USER" ] && [ ! -z "$RT_API_KEY" ]; then
    echo "Logging into artifactory"
    jfrog rt config --url $RT_URL --user $RT_USER --apikey $RT_API_KEY --interactive=false
  else
    echo "Login creds not present. Skipping login."
  fi
}

pull_images() {
  echo "SYSTEM_RUNTIME_LANGUAGE_VERSION=$SYSTEM_RUNTIME_LANGUAGE_VERSION"

  export IMAGE_NAMES_SPACED=$(eval echo $(tr '\n' ' ' < /tmp/images.txt))
  echo $IMAGE_NAMES_SPACED

  for IMAGE_NAME in $IMAGE_NAMES_SPACED; do
    echo "Pulling -------------------> $DOCKER_IMAGE_REGISTRY_URL/$IMAGE_NAME:$SYSTEM_RUNTIME_LANGUAGE_VERSION"
    sudo docker pull $IMAGE_NAME:$SYSTEM_RUNTIME_LANGUAGE_VERSION
  done

  # Clean up master images if we are not building master.
  if [[ $SYSTEM_RUNTIME_LANGUAGE_VERSION != "master" ]]; then
    sudo docker images | grep "master" | awk '{print $1 ":" $2}' | xargs -r sudo docker rmi
  fi
}

logout() {
  echo "Cleaning up jfrog credentials"
  rm -rf ~/.jfrog
}

login
pull_images
logout
