#!/bin/sh

set +e

dir_tmp="$1"

docker build -t v2ray:latest ${dir_tmp}/deploy/app
docker container stop v2ray
docker run -d --name v2ray --rm -p 443:443 v2ray:latest
rm -rf ${dir_tmp}/
