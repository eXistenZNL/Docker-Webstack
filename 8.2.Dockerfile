FROM alpine:3.19

LABEL maintainer="docker@stefan-van-essen.nl"

ARG S6_OVERLAY_VERSION=1.22.1.0
ARG BUILDPLATFORM

# Install webserver packages
RUN apk -U upgrade && apk add --no-cache \
    curl \
    nginx \
    php82-fpm \
    tzdata \
    && ln -s /usr/sbin/php-fpm82 /usr/sbin/php-fpm \
    && addgroup -S php \
    && adduser -S -G php php \
    && rm -rf /var/cache/apk/* /etc/nginx/http.d/* /etc/php82/conf.d/* /etc/php82/php-fpm.d/*

# Install and verify SHA256 for S6-overlay
RUN set -eux; \
    export S6_ARCH=''; \
    case "${BUILDPLATFORM}" in \
        "linux/amd64") S6_ARCH="amd64"; ;; \
        "linux/arm64") S6_ARCH="arm"; ;; \
        *) echo "Cannot build, missing valid build platform for S6 init system!"; exit 1; \
    esac; \
    wget -P /tmp https://github.com/just-containers/s6-overlay/releases/download/v${S6_OVERLAY_VERSION}/s6-overlay-${S6_ARCH}.tar.gz; \
    wget -P /tmp https://github.com/just-containers/s6-overlay/releases/download/v${S6_OVERLAY_VERSION}/s6-overlay-${S6_ARCH}.tar.gz.sha256; \
    cd /tmp;  \
    sha256sum -c *.sha256; \
    gunzip -c /tmp//tmp/s6-overlay-${S6_ARCH}.tar.xz | tar -xf - -C /; \
    rm -rf /tmp/*; \
    unset S6_ARCH;

COPY files/general files/php82 /

WORKDIR /www

ENTRYPOINT ["/init"]

EXPOSE 80

HEALTHCHECK --interval=5s --timeout=5s CMD curl -f http://127.0.0.1/php-fpm-ping || exit 1
