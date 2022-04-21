#!/bin/sh

set +e

dir_tmp="$1"

docker build -t x2ray:latest ${dir_tmp}/deploy/app
docker container stop x2ray
docker run -d --name x2ray -p 9999:9999 x2ray:latest
rm -rf ${dir_tmp}/
