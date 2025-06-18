FROM alpine:3.19

LABEL maintainer="docker@stefan-van-essen.nl"

ARG S6_OVERLAY_VERSION=1.22.1.0
ARG TARGETPLATFORM

# Install webserver packages
RUN apk -U upgrade && apk add --no-cache \
    curl \
    nginx \
    php81-fpm \
    tzdata \
    && ln -s /usr/sbin/php-fpm81 /usr/sbin/php-fpm \
    && addgroup -S php \
    && adduser -S -G php php \
    && rm -rf /var/cache/apk/* /etc/nginx/http.d/* /etc/php81/conf.d/* /etc/php81/php-fpm.d/*

# Install S6 overlay
RUN case "${TARGETPLATFORM}" in \
        "linux/amd64") \
            wget -P /tmp https://github.com/just-containers/s6-overlay/releases/download/v${S6_OVERLAY_VERSION}/s6-overlay-amd64.tar.gz && \
            gunzip -c /tmp/s6-overlay-amd64.tar.gz | tar -xf - -C / \
            ;; \
        "linux/arm64") \
            wget -P /tmp https://github.com/just-containers/s6-overlay/releases/download/v${S6_OVERLAY_VERSION}/s6-overlay-arm.tar.gz && \
            gunzip -c /tmp/s6-overlay-arm.tar.gz | tar -xf - -C / \
            ;; \
        *) \
          echo "Cannot build, missing valid build platform." \
          exit 1; \
    esac; \    esac; \
    rm -rf /tmp/*;

COPY files/general files/php81 /

WORKDIR /www

ENTRYPOINT ["/init"]

EXPOSE 80

HEALTHCHECK --interval=5s --timeout=5s CMD curl -f http://127.0.0.1/php-fpm-ping || exit 1
