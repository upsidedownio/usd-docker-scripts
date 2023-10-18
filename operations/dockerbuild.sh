#!/bin/bash
__dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

#if [-z ${IMAGE_NAME+x} ]
#then
#    echo "IMAGE_NAME is unset, use default config";
#    source ${__dir}/../_dockerScriptConfig.sh
#else
#    echo "IMAGE_NAME: ${IMAGE_NAME}, use environment variables";
#fi

source ${__dir}/../_dockerScriptConfig.sh

cmd_base="docker build"
dockerfile_path="$__dir/../$DOCKERFILE_NAME"
option_tags=""

echo "docker build start"

# check essential arguments
if [ -z $1 ]
then
    echo "no enough arguments supplied"
    echo "usege : ./build.sh [tags]"
    exit
fi

# check tag parameters
for i in "${@:1}"
do
    option_tags="$option_tags -t $DOCKER_REGISTRY$IMAGE_NAME:$i --build-arg BUILD_STREAM=${BUILD_STREAM}"
    echo "append tag $i"
done

# build command and execute
cmd="$cmd_base $option_tags -f $dockerfile_path --progress=plain . "
echo "$cmd"
${cmd}

# confirming
docker images | grep "$IMAGE_NAME"
