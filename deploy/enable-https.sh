#!/usr/bin/env bash
# 给 api.journey-plan.cn 启用 HTTPS（腾讯云免费证书 / Nginx 格式）
#
# 用法：
#   1) 把证书的两个文件传到服务器 /root（证书 .crt/.pem + 私钥 .key）
#      腾讯云下载的压缩包里，Nginx 用那个 *_bundle.crt（含证书链）+ *.key
#   2) sudo bash enable-https.sh
#
# 脚本会自动在 /root 里找证书文件，放进 /etc/nginx/ssl/，
# 写好「80 跳 443 + 443 反代 8000」的配置并 reload，最后自检。
set -euo pipefail

DOMAIN="api.journey-plan.cn"
SSL_DIR="/etc/nginx/ssl"
CONF="/etc/nginx/conf.d/journey-api.conf"
APP_PORT="8000"

log() { printf '\n\033[1;36m==> %s\033[0m\n' "$*"; }
die() { printf '\n\033[1;31m!! %s\033[0m\n' "$*" >&2; exit 1; }
trap 'printf "\n\033[1;31m!! 脚本在第 %s 行出错并中止，把上面几行发我。\033[0m\n" "$LINENO" >&2' ERR

[ "$(id -u)" = "0" ] || die "请用 root 运行：sudo bash $0"

# ------------------------------------------------ 1. 找证书
log "在 /root 里找证书文件"
CERT_SRC=""
for p in /root/*_bundle.crt /root/*.pem /root/*.crt; do
  if [ -f "$p" ]; then CERT_SRC="$p"; break; fi
done
KEY_SRC=""
for p in /root/*.key; do
  if [ -f "$p" ]; then KEY_SRC="$p"; break; fi
done
[ -n "$CERT_SRC" ] || die "没在 /root 找到证书文件（*.crt / *.pem），请先上传"
[ -n "$KEY_SRC" ]  || die "没在 /root 找到私钥文件（*.key），请先上传"
echo "  证书：$CERT_SRC"
echo "  私钥：$KEY_SRC"

# ------------------------------------------------ 2. 摆好位置
log "放到 $SSL_DIR"
mkdir -p "$SSL_DIR"
cp "$CERT_SRC" "$SSL_DIR/$DOMAIN.crt"
cp "$KEY_SRC"  "$SSL_DIR/$DOMAIN.key"
chmod 644 "$SSL_DIR/$DOMAIN.crt"
chmod 600 "$SSL_DIR/$DOMAIN.key"

if command -v openssl >/dev/null 2>&1; then
  CM=$(openssl x509 -noout -modulus -in "$SSL_DIR/$DOMAIN.crt" 2>/dev/null | openssl md5 | awk '{print $2}')
  KM=$(openssl rsa  -noout -modulus -in "$SSL_DIR/$DOMAIN.key" 2>/dev/null | openssl md5 | awk '{print $2}')
  if [ -n "$CM" ] && [ "$CM" = "$KM" ]; then echo "  ✓ 证书与私钥匹配"; else echo "  ! 未能校验（可能缺 openssl），继续"; fi
fi

# ------------------------------------------------ 3. 写 nginx 配置
log "写 nginx 配置（80 跳转 + 443 反代）"
cat > "$CONF" <<EOF
server {
    listen 80;
    server_name $DOMAIN;
    return 301 https://\$host\$request_uri;
}

server {
    listen 443 ssl;
    http2 on;
    server_name $DOMAIN;

    ssl_certificate     $SSL_DIR/$DOMAIN.crt;
    ssl_certificate_key $SSL_DIR/$DOMAIN.key;
    ssl_protocols       TLSv1.2 TLSv1.3;
    ssl_ciphers         HIGH:!aNULL:!MD5;
    ssl_session_cache   shared:SSL:10m;
    ssl_session_timeout 10m;

    location / {
        proxy_pass http://127.0.0.1:$APP_PORT;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
        proxy_read_timeout 300s;
    }
}
EOF

nginx -t
systemctl reload nginx

# ------------------------------------------------ 4. 自检
log "自检"
curl -sS -m 10 -o /dev/null -w "  http://$DOMAIN/docs   -> %{http_code}   (期望 301)\n" "http://$DOMAIN/docs" || true
curl -sS -m 15 -o /dev/null -w "  https://$DOMAIN/docs  -> %{http_code}   (期望 200)\n" "https://$DOMAIN/docs" || true

if command -v openssl >/dev/null 2>&1; then
  echo | openssl s_client -connect "$DOMAIN:443" -servername "$DOMAIN" 2>/dev/null \
    | openssl x509 -noout -subject -dates 2>/dev/null || true
fi

cat <<'DONE'

================================================================
 HTTPS 配置完成。

 如果 https 自检不是 200，八成是云安全组还没放行 443：
   腾讯云控制台 → 该实例 → 安全组 → 入站规则 → 放行 TCP 443

 证书只覆盖 api.journey-plan.cn（单域名），www 与裸域仍是 http，属正常。
 证书 3 个月到期，记得在腾讯云开「自动续期」或到期前 15–30 天重新申请。
================================================================
DONE
