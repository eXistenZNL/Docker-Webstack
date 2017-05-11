FROM alpine:latest

MAINTAINER docker@stefan-van-essen.nl

RUN apk -U upgrade && apk add \
    curl \
    nginx \
    php7 \
    php7-fpm \
    && rm -rf /var/cache/apk/* \
    && rm -rf /etc/nginx/conf.d \
    && rm -rf /etc/php7/php-fpm.d

ADD https://github.com/just-containers/s6-overlay/releases/download/v1.19.1.1/s6-overlay-amd64.tar.gz /tmp/
RUN gunzip -c /tmp/s6-overlay-amd64.tar.gz | tar -xf - -C /

COPY files /

WORKDIR /www

ENTRYPOINT ["/init"]

HEALTHCHECK --interval=5s --timeout=5s CMD curl -f http://127.0.0.1 || exit 1
