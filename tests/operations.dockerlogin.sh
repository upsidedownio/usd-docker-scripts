#! /bin/bash

testTarget="operations/dockerlogin.sh"

echo "test"

sh $testTarget STEPS="ABC" REPOSITORY_NAME="stackexchange" \
           EXTRA_VALUES="KEY1=VALUE1 KEY2=VALUE2"
