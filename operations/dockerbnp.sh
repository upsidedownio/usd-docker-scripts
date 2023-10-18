#!/bin/bash

echo "start building and pushing docker image"

$(dirname "$0")/dockerbuild.sh $@
$(dirname "$0")/dockerpush.sh $@
