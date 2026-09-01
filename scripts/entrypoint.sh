#!/usr/bin/env bash
# entrypoint.sh - 生成运行时配置并启动 sing-box + caddy
# 注意：不打印任何环境变量，避免 Secret 泄露

set -euo pipefail

# 1. 检查必须环境变量
: "${CLIENT_UUID:?CLIENT_UUID required}"
: "${WS_PATH:?WS_PATH required}"
: "${SUB_TOKEN:?SUB_TOKEN required}"
: "${RES_PROXY_HOST:?RES_PROXY_HOST required}"
: "${RES_PROXY_PORT:?RES_PROXY_PORT required}"
: "${RES_PROXY_USER:?RES_PROXY_USER required}"
: "${RES_PROXY_PASS:?RES_PROXY_PASS required}"

# 2. 创建工作目录并收紧权限
mkdir -p /run/app
chmod 700 /run/app

# 3. 模板替换函数（安全 envsubst，仅替换指定变量）
render() {
  local src="$1" dst="$2"
  sed \
    -e "s|\${CLIENT_UUID}|${CLIENT_UUID}|g" \
    -e "s|\${WS_PATH}|${WS_PATH}|g" \
    -e "s|\${SUB_TOKEN}|${SUB_TOKEN}|g" \
    -e "s|\${RES_PROXY_HOST}|${RES_PROXY_HOST}|g" \
    -e "s|\${RES_PROXY_PORT}|${RES_PROXY_PORT}|g" \
    -e "s|\${RES_PROXY_USER}|${RES_PROXY_USER}|g" \
    -e "s|\${RES_PROXY_PASS}|${RES_PROXY_PASS}|g" \
    -e "s|\${PUBLIC_HOST}|${PUBLIC_HOST:-localhost}|g" \
    "$src" > "$dst"
}

# 4. 生成 sing-box 配置
render /templates/sing-box.json.template /run/app/sing-box.json

# 5. 生成 Caddy 配置
render /templates/Caddyfile.template /run/app/Caddyfile

# 6. 生成 Mihomo 订阅
render /templates/mihomo.yaml.template /run/app/profile.yaml

# 7. 校验配置
sing-box check -c /run/app/sing-box.json
caddy validate --config /run/app/Caddyfile --adapter caddyfile

# 8. 启动 sing-box（后台）
sing-box run -c /run/app/sing-box.json &
SB_PID=$!

# 9. 启动 caddy（前台，作为主进程）
caddy run --config /run/app/Caddyfile --adapter caddyfile &
CADDY_PID=$!

# 10. 任一关键进程退出则容器退出
wait -n $SB_PID $CADDY_PID
