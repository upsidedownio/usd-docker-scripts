#!/bin/bash

help()
{
    echo "Usage: weather [ -c | --city1 ]
               [ -d | --city2 ]
               [ -h | --help  ]"
    exit 2
}

SHORT=c:,d:,h
LONG=city1:,city2:,help
OPTS=$(getopt -a -n weather --options $SHORT --longoptions $LONG -- "$@")

VALID_ARGUMENTS=$# # Returns the count of arguments that are in short or long options

if [ "$VALID_ARGUMENTS" -eq 0 ]; then
  help
fi

eval set -- "$OPTS"

while :
do
  case "$1" in
    -c | --city1 )
      city1="$2"
      shift 2
      ;;
    -d | --city2 )
      city2="$2"
      shift 2
      ;;
    -h | --help)
      help
      ;;
    --)
      shift;
      break
      ;;
    *)
      echo "Unexpected option: $1"
      help
      ;;
  esac
done

if [ "$city1" ] && [ -z "$city2" ]
then
    curl -s "https://wttr.in/${city1}"
elif [ -z "$city1" ] && [ "$city2" ]
then
    curl -s "https://wttr.in/${city2}"
elif [ "$city1" ] && [ "$city2" ]
then
    diff -Naur <(curl -s "https://wttr.in/${city1}" ) <(curl -s "https://wttr.in/${city2}" )
else
    curl -s https://wttr.in
fi


# ======================================

# this script requires fallow variables
# * DOCKER_LOGIN_TYPE = dockerhub or empty
# * DOCKER_LOGIN_ACCOUNT
# * DOCKER_LOGIN_SECRET

# by login types
# * dockerhub(default)
# * registry : require DOCKER_REGISTRY
# * ECR : requires...
#   * (optional) DOCKER_ECR_PROFILE
#   * AWS_ECR_ACCOUNT_ID
#   * AWS_ECR_REGION
#   * DOCKER_REGISTRY

# use here your expected variables
echo "STEPS = $STEPS"
echo "REPOSITORY_NAME = $REPOSITORY_NAME"
echo "EXTRA_VALUES = $EXTRA_VALUES"

: "${DOCKER_LOGIN_TYPE:="dockerhub"}"
DOCKER_LOGIN_TYPE="ECR"

# for debug
echo $DOCKER_LOGIN_TYPE


DOCKER_REGISTRY="108610677506.dkr.ecr.ap-northeast-2.amazonaws.com/upsidedown"
if [ -z "$1" ]
then
    if [ -z "$DOCKER_REGISTRY" ]
    then
        echo "docker registry is not set. please set DOCKER_REGISTRY variable first"
    else
        echo "use registry from environment variable"        
    fi
else
    echo "use registry from argument (overwrite)"
fi

echo "login into registry: $DOCKER_REGISTRY"
echo "using login method: $DOCKER_LOGIN_TYPE"

if [ "$DOCKER_LOGIN_TYPE" = "ECR" ]
then
    echo "type is ECR"
fi
# __dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# if [ -z ${IMAGE_NAME+x} ]
# then
#     echo "IMAGE_NAME is unset, use default config";
#     source ${__dir}/../_dockerScriptConfig.sh
# else
#     echo "IMAGE_NAME: $IMAGE_NAME, use environment variables";
# fi

# cmd="docker login $DOCKER_REGISTRY -u $CREDENTIAL_RW_USER --password $CREDENTIAL_RW_PASS"
# ${cmd}

# aws ecr get-login-password --region ap-northeast-2 | \
# docker login --username AWS --password-stdin 108610677506.dkr.ecr.ap-northeast-2.amazonaws.com/upsidedown

