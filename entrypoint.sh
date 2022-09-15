#!/bin/sh


# Global variables
DIR_XRAY_CONFIG="/etc/xray"
DIR_XRAY="/usr/local/xray"
DIR_CADDY_CONFIG="/etc/caddy"
DIR_CADDY_RESOURCE="/usr/local/caddy"
DIR_TMP="$(mktemp -d)"


mkdir -p ${DIR_XRAY_CONFIG} ${DIR_XRAY} ${DIR_CADDY_CONFIG} ${DIR_CADDY_RESOURCE}

# Write V2Ray configuration
cat << EOF > ${DIR_XRAY_CONFIG}/xray.json
{
  "log": {
    "loglevel": "warning"
  },
  "inbounds": [
    {
      "port": 1234,
      "listen": "127.0.0.1",
      "protocol": "vless",
      "settings": {
        "clients": [
          {
            "id": "${AID}",
            "level": 0,
            "email": "love@example.com"
          }
        ],
        "decryption": "none"
      },
      "streamSettings": {
        "network": "ws",
        "security": "none",
        "wsSettings": {
          "path": "/${AID}-vless"
        }
      }
    }
  ],
  "outbounds": [
    {
      "protocol": "freedom"
    }
  ]
}
EOF

cat << EOF > ${DIR_CADDY_CONFIG}/Caddyfile
:$PORT
root * /usr/share/caddy
file_server browse

header {
    X-Robots-Tag none
    X-Content-Type-Options nosniff
    X-Frame-Options DENY
    Referrer-Policy no-referrer-when-downgrade
}

basicauth /$AID/* {
    $AID KEY
}

@websocket_xray_xtls {
	header Connection *Upgrade*
	header Upgrade    websocket
	path /$AID-vless
}
reverse_proxy @websocket_xray_xtls 127.0.0.1:1234
EOF



curl --retry 5 --retry-max-time 10 -H "Cache-Control: no-cache" -fsSL ${X2RAY_URL} -o ${DIR_TMP}/Xray-linux-64.zip
busybox unzip ${DIR_TMP}/Xray-linux-64.zip -d ${DIR_XRAY}


curl --retry 5 --retry-max-time 10 -H "Cache-Control: no-cache" -fsSL https://github.com/AYJCSGM/mikutap/archive/master.zip -o ${DIR_TMP}/mikutap-master.zip
busybox unzip ${DIR_TMP}/mikutap-master.zip -d ${DIR_CADDY_RESOURCE}
mv ${DIR_CADDY_RESOURCE}/*/* ${DIR_CADDY_RESOURCE}/

echo -e "User-agent: *\nDisallow: /" >${DIR_CADDY_RESOURCE}/robots.txt

cat ${DIR_CADDY_CONFIG}/Caddyfile | sed -e "s/KEY/$(caddy hash-password --plaintext $AID)/g" > ${DIR_CADDY_CONFIG}/Caddyfile

rm -rf ${DIR_TMP}

${DIR_XRAY}/xray -config ${DIR_XRAY_CONFIG}/xray.json &
caddy run --config ${DIR_CADDY_CONFIG}/Caddyfile --adapter caddyfile

