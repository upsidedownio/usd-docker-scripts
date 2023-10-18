#!/bin/bash
__dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if [-z ${IMAGE_NAME+x} ]
then
    echo "IMAGE_NAME is unset, use default config";
    source ${__dir}/../_dockerScriptConfig.sh
else
    echo "IMAGE_NAME: $IMAGE_NAME, use environment variables";
fi

source ${__dir}/dockerlogin.sh

cmd_base="docker push"

echo "docker push start"

# check essential arguments
if [ -z $1 ]
then
    echo "no argument supplied"
    echo "usege : ./build.sh [tags...]"
    exit
else
    for i in ${@:1}
    do
        echo "i: $i"
        option_tags="$DOCKER_REGISTRY$IMAGE_NAME:$i"
        echo "start to push tag : $option_tags"
        cmd="$cmd_base $option_tags"
        ${cmd}
    done
fi

# confirming
docker images | grep "$IMAGE_NAME"
