FROM alpine:3.23 AS base

LABEL maintainer="docker@stefan-van-essen.nl"

ARG S6_OVERLAY_VERSION=3.2.2.0
ARG TARGETPLATFORM

# Install webserver packages
RUN apk -U upgrade && apk add --no-cache \
    curl \
    nginx \
    php85-fpm \
    tzdata \
    && ln -s /usr/sbin/php-fpm85 /usr/sbin/php-fpm \
    && addgroup -S php \
    && adduser -S -G php php \
    && rm -rf /var/cache/apk/* /etc/nginx/http.d/* /etc/php85/conf.d/* /etc/php85/php-fpm.d/*

# Install S6 overlay
RUN wget -P /tmp https://github.com/just-containers/s6-overlay/releases/download/v${S6_OVERLAY_VERSION}/s6-overlay-noarch.tar.xz; \
    tar -C / -Jxpf /tmp/s6-overlay-noarch.tar.xz; \
    wget -P /tmp https://github.com/just-containers/s6-overlay/releases/download/v${S6_OVERLAY_VERSION}/s6-overlay-symlinks-noarch.tar.xz; \
    tar -C / -Jxpf /tmp/s6-overlay-symlinks-noarch.tar.xz; \
    wget -P /tmp https://github.com/just-containers/s6-overlay/releases/download/v${S6_OVERLAY_VERSION}/s6-overlay-symlinks-arch.tar.xz; \
    tar -C / -Jxpf /tmp/s6-overlay-symlinks-arch.tar.xz; \
    case "${TARGETPLATFORM}" in \
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

COPY files/general files/php85 /

WORKDIR /www

ENTRYPOINT ["/init"]

# =========================================================
# Default mode
# ==========================================================

FROM base AS default

EXPOSE 80

HEALTHCHECK --interval=5s --timeout=5s CMD curl -f http://127.0.0.1/php-fpm-ping || exit 1

# =========================================================
# Rootless mode
# =========================================================

FROM default AS rootless

# Modify configurations and set permissions for rootless operation
RUN sed -i '/^user nginx;/d' /etc/nginx/nginx.conf \
    && sed -i 's|listen 80 default_server;|listen 8080 default_server;|' /etc/nginx/nginx.conf \
    && sed -i '/^user = php$/d; /^group = php$/d' /etc/php85/php-fpm.conf \
    && mkdir -p /var/run/s6 /run/nginx /var/lib/nginx/tmp \
    && chown -R nobody:nobody /var/run/s6 /run /var/lib/nginx /var/log/nginx /www

EXPOSE 8080

HEALTHCHECK --interval=5s --timeout=5s CMD curl -f http://127.0.0.1:8080/php-fpm-ping || exit 1
