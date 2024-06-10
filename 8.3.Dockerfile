FROM alpine:3.19 as base

LABEL maintainer="docker@stefan-van-essen.nl"

ARG S6_OVERLAY_VERSION=3.1.6.2
ARG BUILDPLATFORM

# Install webserver packages
RUN apk -U upgrade && apk add --no-cache \
    curl \
    nginx \
    php83-fpm \
    tzdata \
    && ln -s /usr/sbin/php-fpm83 /usr/sbin/php-fpm \
    && addgroup -S php \
    && adduser -S -G php php \
    && rm -rf /var/cache/apk/* /etc/nginx/http.d/* /etc/php83/conf.d/* /etc/php83/php-fpm.d/*

# Install S6 overlay
RUN wget -P /tmp https://github.com/just-containers/s6-overlay/releases/download/v${S6_OVERLAY_VERSION}/s6-overlay-noarch.tar.xz; \
    tar -C / -Jxpf /tmp/s6-overlay-noarch.tar.xz; \
    wget -P /tmp https://github.com/just-containers/s6-overlay/releases/download/v${S6_OVERLAY_VERSION}/s6-overlay-symlinks-noarch.tar.xz; \
    tar -C / -Jxpf /tmp/s6-overlay-symlinks-noarch.tar.xz; \
    wget -P /tmp https://github.com/just-containers/s6-overlay/releases/download/v${S6_OVERLAY_VERSION}/s6-overlay-symlinks-arch.tar.xz; \
    tar -C / -Jxpf /tmp/s6-overlay-symlinks-arch.tar.xz; \
    case "${BUILDPLATFORM}" in \
        "linux/amd64") \
            wget -P /tmp https://github.com/just-containers/s6-overlay/releases/download/v${S6_OVERLAY_VERSION}/s6-overlay-x86_64.tar.xz; \
            tar -C / -Jxpf /tmp/s6-overlay-x86_64.tar.xz; \
            ;; \
        "linux/arm64") \
            wget -P /tmp https://github.com/just-containers/s6-overlay/releases/download/v${S6_OVERLAY_VERSION}/s6-overlay-aarch64.tar.xz; \
            tar -C / -Jxpf /tmp/s6-overlay-aarch64.tar.xz; \
            ;; \
        *) \
          echo "Cannot build, missing valid build platform." \
          exit 1; \
    esac; \
    rm -rf /tmp/*;

COPY files/general files/php83 /

WORKDIR /www

ENTRYPOINT ["/init"]

EXPOSE 80

HEALTHCHECK --interval=5s --timeout=5s CMD curl -f http://127.0.0.1/php-fpm-ping || exit 1

FROM base as usermode

# Update user names, config files and access rights so the container can run in user mode
RUN apk -U add shadow \
    && usermod -l app php \
    && groupmod -n app php \
    && sed -i '/^user.*/d' /etc/nginx/nginx.conf \
    && sed -i '/^user.*/d' /etc/php83/php-fpm.conf \
    && sed -i '/^group.*/d' /etc/php83/php-fpm.conf \
    && chown app:app /var/lib/nginx \
    && chown app:app /var/log/nginx \
    && chown app:app /run/nginx \
    && chown app:app /var/lib/nginx/tmp

USER app