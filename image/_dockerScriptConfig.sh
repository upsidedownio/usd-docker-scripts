#!/bin/bash

: "${CONTAINER_NAME:="salkka-"}"
: "${IMAGE_NAME:="upsidedown/salkka-frontend"}"
: "${DEFAULT_TAG:="latest"}"
: "${DOCKER_REGISTRY:="registry.upsidedown.io/"}"

CREDENTIAL_RW_USER=""
CREDENTIAL_RW_PASS="" # 사용시 입력하고 커밋하지 마세요
