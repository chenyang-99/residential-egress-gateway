FROM alpine:3.20

# 安装运行时依赖
RUN apk add --no-cache ca-certificates curl openssl bash coreutils

# 固定版本 sing-box（稳定版，部署时确认最新 stable）
ARG SINGBOX_VERSION=1.11.0
RUN curl -fsSL "https://github.com/SagerNet/sing-box/releases/download/v${SINGBOX_VERSION}/sing-box-${SINGBOX_VERSION}-linux-amd64.tar.gz" \
    | tar -xz -C /usr/local/bin --strip-components=1 "sing-box-${SINGBOX_VERSION}-linux-amd64/sing-box" \
    && chmod +x /usr/local/bin/sing-box

# 固定版本 caddy
ARG CADDY_VERSION=2.8.4
RUN curl -fsSL "https://github.com/caddyserver/caddy/releases/download/v${CADDY_VERSION}/caddy_${CADDY_VERSION}_linux_amd64.tar.gz" \
    | tar -xz -C /usr/local/bin caddy \
    && chmod +x /usr/local/bin/caddy

WORKDIR /run/app

COPY scripts/entrypoint.sh /usr/local/bin/entrypoint.sh
COPY config/ /templates/
RUN chmod +x /usr/local/bin/entrypoint.sh

EXPOSE 3000

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
