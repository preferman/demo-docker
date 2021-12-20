FROM alpine:latest

WORKDIR /app

COPY entrypoint.sh /app/entrypoint.sh

RUN apk add --no-cache --virtual .build-deps ca-certificates curl \
 && chmod +x /app/entrypoint.sh

ENTRYPOINT ["/app/entrypoint.sh"]

CMD ["443","f6e0daef-3a42-4f1b-96ea-6269a7ff3a8a","4","/"]
