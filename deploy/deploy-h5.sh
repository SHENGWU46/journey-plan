#!/usr/bin/env bash
# ============================================================================
# JourneyPlan H5 上线（H5 静态站 + nginx + 后端 CORS 放行）
#
# 为什么有这个脚本：
#   文档里那段命令是「多行 heredoc + 手动粘贴」，很容易在复制时漏行、
#   被终端的自动缩进/换行搞乱。这个脚本把整件事封成一个文件，跑一次就好。
#
# 用法：
#   1. 把这三个文件传到服务器 /root
#        deploy-h5.sh
#        h5-dist.zip
#        journey-plan-api.tar.gz
#   2. sudo bash /root/deploy-h5.sh
#
# 幂等：重复跑不会重复追加 CORS、不会写坏 .env（.env 会先备份再还原）。
# ============================================================================
set -e
trap 'printf "\n\033[1;31m!! 脚本在第 %s 行出错，已中止\033[0m\n" "$LINENO" >&2' ERR

log() { printf '\n\033[1;36m==> %s\033[0m\n' "$*"; }
die() { printf '\n\033[1;31m!! %s\033[0m\n' "$*" >&2; exit 1; }

[ "$(id -u)" = "0" ] || die "请用 sudo 运行：sudo bash /root/deploy-h5.sh"

H5_DIR=/var/www/h5
NGINX_CONF=/etc/nginx/conf.d/app-h5.conf
APP_DIR=/opt/journey-api
H5_ORIGIN=http://app.journey-plan.cn

log "检查上传的文件"
for f in /root/h5-dist.zip /root/journey-plan-api.tar.gz; do
  [ -f "$f" ] || die "缺少 $f —— 先把 h5-dist.zip 和 journey-plan-api.tar.gz 传到 /root"
  printf '  ✓ %s (%s)\n' "$f" "$(du -h "$f" | cut -f1)"
done

# ---------------------------------------------------------------- 1. H5 文件
log "1/4 部署 H5 静态文件到 $H5_DIR"
mkdir -p "$H5_DIR"
rm -rf "${H5_DIR:?}/"*
unzip -oq /root/h5-dist.zip -d "$H5_DIR"
[ -f "$H5_DIR/index.html" ] || die "解压后没有 index.html —— h5-dist.zip 内容不对"
echo "  顶层内容:"; ls -A "$H5_DIR" | sed 's/^/    /'
echo "  static/ 文件数: $(find "$H5_DIR/static" -type f 2>/dev/null | wc -l)  (应为 45)"
[ -d "$H5_DIR/static/icons" ] || die "没有 static/icons —— 这个包是修复前的旧产物，请重新下载"

# ---------------------------------------------------------------- 2. nginx
log "2/4 写 nginx 配置并 reload"
cat > "$NGINX_CONF" <<'NGINXEOF'
server {
    listen 80;
    server_name app.journey-plan.cn;

    root /var/www/h5;
    index index.html;

    location /            { try_files $uri $uri/ /index.html; }
    location /assets/     { expires 30d; add_header Cache-Control "public, immutable"; }
    location /static/     { expires 7d;  add_header Cache-Control "public"; }

    gzip on;
    gzip_types text/css application/javascript image/svg+xml;
    gzip_min_length 1024;
}
NGINXEOF
nginx -t
systemctl reload nginx
echo "  ✓ $NGINX_CONF 已写入，nginx 已 reload"

# ---------------------------------------------------------------- 3. 后端
log "3/4 更新后端（先备份 .env，再解包覆盖）"
[ -f "$APP_DIR/.env" ] || die "找不到 $APP_DIR/.env —— 后端似乎没部署过，请先跑 deploy-journey-api.sh"
systemctl stop journey-api 2>/dev/null || true

cp "$APP_DIR/.env" /root/.env.server.bak
echo "  ✓ .env 已备份到 /root/.env.server.bak"

rm -rf "$APP_DIR"
tar -xzf /root/journey-plan-api.tar.gz -C /opt
[ -d /opt/journey-plan-api ] || die "解包后没有 /opt/journey-plan-api"
mv /opt/journey-plan-api "$APP_DIR"
cp /root/.env.server.bak "$APP_DIR/.env"
echo "  ✓ 代码已更新，.env 已还原"

# 追加 CORS 白名单：必须用 printf —— 若 .env 末尾没有换行，echo 会拼坏上一行
if grep -q '^CORS_ORIGINS=' "$APP_DIR/.env"; then
  echo "  CORS_ORIGINS 已存在，跳过追加"
else
  printf '\nCORS_ORIGINS=%s\n' "$H5_ORIGIN" >> "$APP_DIR/.env"
  echo "  ✓ 已追加 CORS_ORIGINS=$H5_ORIGIN"
fi
echo "  .env 末尾 3 行（核对没被拼坏）:"
tail -3 "$APP_DIR/.env" | sed 's/^/    /'

systemctl restart journey-api
sleep 3
if systemctl is-active --quiet journey-api; then
  echo "  ✓ journey-api 正在运行"
else
  die "journey-api 没起来 —— 看 tail -50 /var/log/journey-api.log"
fi

# ---------------------------------------------------------------- 4. 自检
log "4/4 自检（用 Host 头绕开 DNS，直接打本机 nginx）"
chk() { printf '  %-16s ' "$1"; shift; curl -sS -m 8 -o /dev/null -w "HTTP %{http_code}\n" "$@" 2>/dev/null || echo "连接失败"; }
chk "H5 首页"  -H "Host: app.journey-plan.cn" http://127.0.0.1/
chk "H5 图标"  -H "Host: app.journey-plan.cn" http://127.0.0.1/static/icons/pin-78716c.svg
chk "H5 主 JS" -H "Host: app.journey-plan.cn" "http://127.0.0.1/assets/$(ls /var/www/h5/assets 2>/dev/null | grep -m1 '^index-.*\.js$')"
chk "后端 docs" http://127.0.0.1:8000/docs
chk "备案页"    -H "Host: www.journey-plan.cn" http://127.0.0.1/

printf '  %-16s ' "CORS 预检"
cors=$(curl -sS -m 8 -X OPTIONS http://127.0.0.1:8000/auth/login \
        -H "Origin: $H5_ORIGIN" -H "Access-Control-Request-Method: POST" \
        -D - -o /dev/null 2>/dev/null | grep -i 'access-control-allow-origin' | tr -d '\r' || true)
if [ -n "$cors" ]; then echo "✓ $cors"; else echo "✗ 未放行！检查 $APP_DIR/.env 里的 CORS_ORIGINS"; fi

cat <<'EOT'

--------------------------------------------------------------------
脚本部分完成。还差两件只有你能做的：

  1) DNSPod 加一条 A 记录：主机记录 app  →  记录值 43.136.185.171
     （80 端口安全组早就放行了，不用再动）

  2) 解析生效后（几分钟），浏览器打开  http://app.journey-plan.cn
     注册一个账号，把流程走一遍

如果哪一步不对，把输出原样发我。
--------------------------------------------------------------------
EOT
