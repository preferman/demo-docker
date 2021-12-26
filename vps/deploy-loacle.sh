#!/bin/sh
key_location="~/.ssh/dev-amazon.pem"
dir_tmp="$(mktemp -d)"

mkdir -p deploy/app
cp Dockerfile deploy/app/Dockerfile
cp entrypoint.sh deploy/app/entrypoint.sh
cp deploy-server.sh deploy/deploy-server.sh

echo "uploading file"
ssh -i ${key_location} root@3.129.128.14 mkdir ${dir_tmp}
scp -i ${key_location} -r deploy/ root@3.129.128.14:${dir_tmp}/
echo "deploying"
ssh -i ${key_location} root@3.129.128.14 sh ${dir_tmp}/deploy/deploy-server.sh ${dir_tmp}
rm -rf deploy/
