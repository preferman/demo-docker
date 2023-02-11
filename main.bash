#！/bin/sh
# Gobal verbals
green(){ echo -e "\033[32m\033[01m$1\033[0m";}
yellow(){ echo -e "\033[33m\033[01m$1\033[0m";}
blue(){ echo -e "\033[36m\033[01m$1\033[0m";}


download_file(){
    # $1 is taget file, $2 is file download link, $3 is file type
    if ! wget -qO "$1" "$2"; then 
        echo "file download failed, file type is $3" 
        exit 1
    fi
    echo "file download successfully, file type is $3"
}


decompression() {
    # $1 is source file, $2 is dest directory
    busybox unzip -q "$1" -d "$2"
    # $? is last excution command
    if [ $? -ne 0 ]; then
        rm -r "$2"
        echo "decompress failed removed: $2"
        exit 1
    fi
    echo "decompress successfully dest directory: $2"
}

install_app() {
    # $1 is source file $2 is dest file
    install -m 755 $1 $2
    if [ $? -ne 0 ]; then
        echo "install is failed"
        exit 1
    fi
    echo "install successfully, dest dir: $2"
}


uuidgen_replit(){
    USER_UUID=$(curl -s $REPLIT_DB_URL/RE_UUID)
    if [ "${USER_UUID}" = "" ]; then
        USER_UUID="$(cat /proc/sys/kernel/random/uuid)"
        curl -sXPOST $REPLIT_DB_URL/RE_UUID="${USER_UUID}" 
    fi
    echo "${USER_UUID}"
}

run_xray() {
    # $1 is config file dir $2 is dest config dir $3 is app installed dir
    USER_UUID=`uuidgen_replit`
    cp -f $1 $2
    sed -i "s|uuid|${USER_UUID}|g" $2
    echo ""
    print_info
    "$3" -c "$2"
}


ssl_gen(){

  openssl req -newkey rsa:4096 \
            -x509 \
            -sha256 \
            -days 3650 \
            -nodes \
            -out $1/my.crt \
            -keyout $1/my.key \
            -subj "/C=SI/ST=Ljubljana/L=Ljubljana/O=Security/OU=IT Department/CN=${REPL_SLUG}.${REPL_OWNER}.repl.co"
}


print_info(){
    echo
    yellow "1.replit_xray_vmess=vmess://$(echo -n "\
{\
\"v\": \"2\",\
\"ps\": \"replit_xray_vmess\",\
\"add\": \"${REPL_SLUG}.${REPL_OWNER}.repl.co\",\
\"port\": \"443\",\
\"id\": \"$USER_UUID\",\
\"aid\": \"0\",\
\"net\": \"ws\",\
\"type\": \"none\",\
\"host\": \"${REPL_SLUG}.${REPL_OWNER}.repl.co\",\
\"path\": \"/$USER_UUID-vm\",\
\"tls\": \"tls\"\
}"\
    | base64 -w 0)" 
    blue "-------------------------------------------"
    yellow "2.replit_xray_vless=vless://${USER_UUID}@${REPL_SLUG}.${REPL_OWNER}.repl.co:443?encryption=none&security=tls&type=ws&host=${REPL_SLUG}.${REPL_OWNER}.repl.co&path=/$USER_UUID-vl#replit_xray_vless"
    blue "-------------------------------------------"
    yellow "3.replit_xray_trojan=trojan://${USER_UUID}@${REPL_SLUG}.${REPL_OWNER}.repl.co:443?security=tls&type=ws&host=${REPL_SLUG}.${REPL_OWNER}.repl.co&path=/$USER_UUID-tr#replit_xray_trojan"
    blue "-------------------------------------------"
    yellow "4.shadowsocks+ws+tls配置明文如下，相关参数可复制到客户端"
    echo "服务器地址：${REPL_SLUG}.${REPL_OWNER}.repl.co"
    echo "端口：443"
    echo "密码：$USER_UUID"
    echo "加密方式：chacha20-ietf-poly1305"
    echo "传输协议：ws"
    echo "host/sni：${REPL_SLUG}.${REPL_OWNER}.repl.co"
    echo "path路径：/$USER_UUID-ss"
    echo "tls：开启"
    blue "-------------------------------------------"
    yellow "5：socks+ws+tls配置明文如下，相关参数可复制到客户端"
    echo "服务器地址：${REPL_SLUG}.${REPL_OWNER}.repl.co"
    echo "端口：443"
    echo "用户名：$USER_UUID"
    echo "密码：$USER_UUID"
    echo "传输协议：ws"
    echo "host/sni：${REPL_SLUG}.${REPL_OWNER}.repl.co"
    echo "path路径：/$USER_UUID-so"
    echo "tls：开启"
    blue "-------------------------------------------"
    echo
}

TMP_DIRECTORY="$(mktemp -d)"
DIR_X2RAY="./app"
DIR_X2RAY_CONFIG="./app/config"
mkdir -p ${DIR_X2RAY} ${DIR_X2RAY_CONFIG}
URL_X2RAY="https://github.com/XTLS/Xray-core/releases/download/v1.7.2/Xray-linux-64.zip"
FILE_CONFIG="./config.json"
DIR_SSL_FILE="./"


if [ ! -e "${DIR_X2RAY}/xray" ]; then
    download_file ${TMP_DIRECTORY}/app.zip ${URL_X2RAY} x2ray
    decompression ${TMP_DIRECTORY}/app.zip ${TMP_DIRECTORY}/x2ray
    install_app ${TMP_DIRECTORY}/x2ray/xray ${DIR_X2RAY}/xray
    rm -r ${TMP_DIRECTORY}
fi
#ssl_gen ${DIR_SSL_FILE}
run_xray ${FILE_CONFIG} ${DIR_X2RAY_CONFIG}/config.json ${DIR_X2RAY}/xray
