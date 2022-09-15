#!/bin/sh


# Global variables
DIR_XRAY_CONFIG="/etc/xray"
DIR_XRAY="/usr/local/xray"
DIR_TMP="$(mktemp -d)"


mkdir -p ${DIR_XRAY_CONFIG} ${DIR_XRAY}

# Write V2Ray configuration
cat << EOF > ${DIR_XRAY_CONFIG}/xray.json
{
  "log": {
    "loglevel": "warning"
  },
  "inbounds": [
    {
      "port": ${PORT},
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



curl --retry 5 --retry-max-time 10 -H "Cache-Control: no-cache" -fsSL ${X2RAY_URL} -o ${DIR_TMP}/Xray-linux-64.zip

busybox unzip ${DIR_TMP}/Xray-linux-64.zip -d ${DIR_XRAY}

rm -rf ${DIR_TMP}

${DIR_XRAY}/xray -config ${DIR_XRAY_CONFIG}/xray.json

