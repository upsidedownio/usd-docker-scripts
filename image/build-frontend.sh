#!/bin/bash

export CONTAINER_NAME="salkka-frontend"
export DOCKERFILE_NAME="frontend.dockerfile"
#export IMAGE_NAME="upsidedown/salkka-frontend"
#export DEFAULT_TAG="latest"
#export DOCKER_REGISTRY="registry.upsidedown.io/"

$(dirname "$0")/docker/dockerbuild.sh $@
