#!/bin/sh


# Global variables
DIR_XRAY_CONFIG="/etc/xray"
DIR_XRAY="/usr/local"
DIR_CADDY_CONFIG="/etc/caddy"
DIR_CADDY_RESOURCE="/usr/share/caddy"
DIR_TMP="$(mktemp -d)"


mkdir -p ${DIR_XRAY_CONFIG} ${DIR_CADDY_CONFIG} ${DIR_CADDY_RESOURCE} ${DIR_XRAY}

# Write V2Ray configuration
cat << EOF > ${DIR_XRAY_CONFIG}/xray.json
{
  "inbounds": [
    {
      "listen": "/etc/caddy/vmess",
      "protocol": "vmess",
      "settings": {
        "clients": [
          {
            "id": "$AID"
          }
        ]
      },
      "streamSettings": {
        "network": "ws",
        "wsSettings": {
          "path": "/$AID-vmess"
        }
      }
    },
    {
      "listen": "/etc/caddy/vless",
      "protocol": "vless",
      "settings": {
        "clients": [
          {
            "id": "$AID"
          }
        ],
        "decryption": "none"
      },
      "streamSettings": {
        "network": "ws",
        "wsSettings": {
          "path": "/$AID-vless"
        }
      }
    },
    {
      "listen": "/etc/caddy/trojan",
      "protocol": "trojan",
      "settings": {
        "clients": [
          {
            "password": "$AID"
          }
        ]
      },
      "streamSettings": {
        "network": "ws",
        "wsSettings": {
          "path": "/$AID-trojan"
        }
      }
    },
    {
      "port": 4234,
      "listen": "127.0.0.1",
      "tag": "onetag",
      "protocol": "dokodemo-door",
      "settings": {
        "address": "v1.mux.cool",
        "network": "tcp",
        "followRedirect": false
      },
      "streamSettings": {
        "security": "none",
        "network": "ws",
        "wsSettings": {
          "path": "/$AID-ss"
        }
      }
    },
    {
      "port": 4324,
      "listen": "127.0.0.1",
      "protocol": "shadowsocks",
      "settings": {
        "method": "$SS_ENCYPT",
        "password": "$AID"
      },
      "streamSettings": {
        "security": "none",
        "network": "domainsocket",
        "dsSettings": {
          "path": "apath",
          "abstract": true
        }
      }
    },
    {
      "port": 5234,
      "listen": "127.0.0.1",
      "protocol": "socks",
      "settings": {
        "auth": "password",
        "accounts": [
          {
            "user": "$AID",
            "pass": "$AID"
          }
        ]
      },
      "streamSettings": {
        "network": "ws",
        "wsSettings": {
          "path": "/$AID-socks"
        }
      }
    }
  ],
  "outbounds": [
    {
      "protocol": "freedom",
      "tag": "direct",
      "settings": {}
    },
    {
      "protocol": "blackhole",
      "tag": "blocked",
      "settings": {}
    },
    {
      "protocol": "socks",
      "tag": "sockstor",
      "settings": {
        "servers": [
          {
            "address": "127.0.0.1",
            "port": 9050
          }
        ]
      }
    },
    {
      "protocol": "freedom",
      "tag": "twotag",
      "streamSettings": {
        "network": "domainsocket",
        "dsSettings": {
          "path": "apath",
          "abstract": true
        }
      }
    }
  ],
  "routing": {
    "rules": [
      {
        "type": "field",
        "inboundTag": [
          "onetag"
        ],
        "outboundTag": "twotag"
      },
      {
        "type": "field",
        "outboundTag": "sockstor",
        "domain": [
          "geosite:tor"
        ]
      },
      {
        "type": "field",
        "outboundTag": "blocked",
        "domain": [
          "geosite:category-ads-all"
        ]
      }
    ]
  }
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
    $AID key
}


@websocket_xray_vmess {
	header Connection *Upgrade*
	header Upgrade    websocket
	path /$AID-vmess
}
reverse_proxy @websocket_xray_vmess unix//etc/caddy/vmess


@websocket_xray_vless {
	header Connection *Upgrade*
	header Upgrade    websocket
	path /$AID-vless
}
reverse_proxy @websocket_xray_vless unix//etc/caddy/vless

@websocket_xray_trojan {
	header Connection *Upgrade*
	header Upgrade    websocket
	path /$AID-trojan
}
reverse_proxy @websocket_xray_trojan unix//etc/caddy/trojan

@websocket_xray_ss {
	header Connection *Upgrade*
	header Upgrade    websocket
	path /$AID-ss
}
reverse_proxy @websocket_xray_ss 127.0.0.1:4234

@websocket_xray_socks {
	header Connection *Upgrade*
	header Upgrade    websocket
	path /$AID-socks
}
reverse_proxy @websocket_xray_socks 127.0.0.1:5234
EOF


curl --retry 5 --retry-max-time 10 -H "Cache-Control: no-cache" -fsSL https://github.com/XTLS/Xray-core/releases/latest/download/Xray-linux-64.zip -o ${DIR_TMP}/Xray-linux-64.zip

busybox unzip ${DIR_TMP}/Xray-linux-64.zip -d ${DIR_XRAY}

curl --retry 5 --retry-max-time 10 -H "Cache-Control: no-cache" -fsSL https://github.com/AYJCSGM/mikutap/archive/master.zip -o ${DIR_TMP}/mikutap-master.zip

busybox unzip ${DIR_TMP}/mikutap-master.zip -d ${DIR_CADDY_RESOURCE}
mv ${DIR_CADDY_RESOURCE}/*/* ${DIR_CADDY_RESOURCE}/

echo -e "User-agent: *\nDisallow: /" >${DIR_CADDY_RESOURCE}/robots.txt

cat ${DIR_CADDY_CONFIG}/Caddyfile | sed -e "s/key/$(caddy hash-password --plaintext $AID)/g" > ${DIR_CADDY_CONFIG}/Caddyfile


rm -rf ${DIR_TMP}

caddy fmt ${DIR_CADDY_CONFIG}/Caddyfile

${DIR_XRAY}/xray -config ${DIR_XRAY_CONFIG}/xray.json &
caddy run --config ${DIR_CADDY_CONFIG}/Caddyfile --adapter caddyfile

