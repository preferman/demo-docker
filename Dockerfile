FROM alpine:edge

WORKDIR /app

COPY entrypoint.sh /app/entrypoint.sh

ENV AID="76368476-74b1-41fb-aebe-faa77bdc7e95"
ENV SS_ENCYPT="chacha20-ietf-poly1305"
ENV PORT=80

RUN apk update && apk add --no-cache --virtual .build-deps ca-certificates curl caddy\
 && chmod +x /app/entrypoint.sh

ENTRYPOINT ["/app/entrypoint.sh"]

