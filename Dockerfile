FROM alpine:latest

RUN apk add --no-cache curl bash jq

COPY rootscripts/docker-entrypoint.sh /usr/bin

ENTRYPOINT  ["/usr/bin/docker-entrypoint.sh"]