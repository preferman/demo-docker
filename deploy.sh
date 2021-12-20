key_location="~/.ssh/dev-amazon.pem"
dir_tmp="$(mktemp -d)"

mkdir -p app
cp app.json app/app.json
cp Dockerfile app/Dockerfile
cp entrypoint.sh app/entrypoint.sh
tar -czvf app.tar.gz app/
rm -rf app
ssh -i ${key_location} root@3.129.128.14 mkdir ${dir_tmp}
scp -i  ${key_location} app.tar.gz root@3.129.128.14:${dir_tmp}/app.tar.gz
rm -rf app.tar.gz
#ssh -i ${key_location} root@3.129.128.14 tar -xzvf ${dir_tmp}/app.tar.gz -C ~/
