FROM alpine:edge

WORKDIR /app

COPY entrypoint.sh /app/entrypoint.sh

ENV AID="76368476-74b1-41fb-aebe-faa77bdc7e95"
ENV PORT=80
ENV X2RAY_URL="https://github.com/XTLS/Xray-core/releases/download/v1.5.10/Xray-linux-64.zip"

RUN apk update && apk add --no-cache --virtual .build-deps ca-certificates curl caddy\
 && chmod +x /app/entrypoint.sh

ENTRYPOINT ["/app/entrypoint.sh"]

