#!/usr/bin/env bash
# ============================================================================
# JourneyPlan H5 上线（H5 静态站 + nginx + 后端 CORS 放行）
#
# 为什么有这个脚本：
#   文档里那段命令是「多行 heredoc + 手动粘贴」，很容易在复制时漏行、
#   被终端的自动缩进/换行搞乱。这个脚本把整件事封成一个文件，跑一次就好。
#
# 用法：
#   1. 把这两个文件传到服务器 /root
#        h5-dist.zip
#        journey-plan-api.tar.gz
#      （本脚本 deploy-h5.sh 也放 /root）
#   2. sudo bash /root/deploy-h5.sh
#
# HTTPS：脚本会**自动识别证书**
#   - 若 /etc/nginx/ssl/app.journey-plan.cn.{crt,key} 已存在 → 配 443 + 80 跳转
#   - 否则在 /root 下找带 "app" 的证书文件，并**用 openssl 校验它确实覆盖
#     app.journey-plan.cn**（防止误用 api 那张证书）→ 找到就装上并启用 HTTPS
#   - 都没有 → 先配成 HTTP，照样能用
#   所以你以后申请完证书，只需把 .crt/.key 传到 /root 再跑一次本脚本即可。
#
# 幂等：重复跑不会弄丢 .env（先备份再还原）、CORS 不会重复写、nginx 覆盖重写。
# ============================================================================
set -e
trap 'printf "\n\033[1;31m!! 脚本在第 %s 行出错，已中止\033[0m\n" "$LINENO" >&2' ERR

log() { printf '\n\033[1;36m==> %s\033[0m\n' "$*"; }
die() { printf '\n\033[1;31m!! %s\033[0m\n' "$*" >&2; exit 1; }

[ "$(id -u)" = "0" ] || die "请用 sudo 运行：sudo bash /root/deploy-h5.sh"

H5_DIR=/var/www/h5
NGINX_CONF=/etc/nginx/conf.d/app-h5.conf
APP_DIR=/opt/journey-api
CERT_DIR=/etc/nginx/ssl
CRT="$CERT_DIR/app.journey-plan.cn.crt"
KEY="$CERT_DIR/app.journey-plan.cn.key"
DOMAIN=app.journey-plan.cn

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
[ -d "$H5_DIR/static/icons" ] || die "没有 static/icons —— 这是修复前的旧产物，请重新下载 h5-dist.zip"
echo "  顶层内容: $(ls -A "$H5_DIR" | tr '\n' ' ')"
echo "  static/ 文件数: $(find "$H5_DIR/static" -type f 2>/dev/null | wc -l)  (应为 45)"

# ---------------------------------------------------------------- 2. 证书识别
log "2/4 检查 HTTPS 证书"
HTTPS=0
if [ -f "$CRT" ] && [ -f "$KEY" ]; then
  HTTPS=1
  echo "  ✓ 已安装：$CRT"
else
  echo "  未安装，尝试在 /root 里找带 app 的证书文件…"
  src_crt=""; src_key=""
  for c in /root/${DOMAIN}_bundle.crt /root/${DOMAIN}.crt /root/*app*.crt; do
    [ -f "$c" ] || continue
    for k in "${c%.crt}.key" /root/${DOMAIN}.key /root/*app*.key; do
      [ -f "$k" ] || continue
      if command -v openssl >/dev/null 2>&1; then
        if openssl x509 -in "$c" -noout -checkhost "$DOMAIN" >/dev/null 2>&1; then
          src_crt="$c"; src_key="$k"; break 2
        fi
      else
        src_crt="$c"; src_key="$k"; break 2
      fi
    done
  done
  if [ -n "$src_crt" ]; then
    mkdir -p "$CERT_DIR"
    cp "$src_crt" "$CRT"; cp "$src_key" "$KEY"
    chmod 644 "$CRT"; chmod 600 "$KEY"
    HTTPS=1
    echo "  ✓ 已安装证书（源：$src_crt）"
  else
    echo "  · 没找到覆盖 $DOMAIN 的证书 → 先按 HTTP 配置"
    echo "    （以后申请到证书，传 .crt/.key 到 /root 再跑一次本脚本即可自动启用 HTTPS）"
  fi
fi

log "3/4 写 nginx 配置并 reload"
if [ "$HTTPS" = 1 ]; then
  cat > "$NGINX_CONF" <<'NGINXEOF'
# H5 站点（HTTPS）—— 由 deploy-h5.sh 生成
server {
    listen 80;
    server_name app.journey-plan.cn;
    return 301 https://$host$request_uri;
}
server {
    listen 443 ssl;
    http2 on;
    server_name app.journey-plan.cn;

    ssl_certificate     /etc/nginx/ssl/app.journey-plan.cn.crt;
    ssl_certificate_key /etc/nginx/ssl/app.journey-plan.cn.key;
    ssl_protocols       TLSv1.2 TLSv1.3;

    root /var/www/h5;
    index index.html;

    location /        { try_files $uri $uri/ /index.html; }
    location /assets/ { expires 30d; add_header Cache-Control "public, immutable"; }
    location /static/ { expires 7d;  add_header Cache-Control "public"; }

    gzip on;
    gzip_types text/css application/javascript image/svg+xml;
    gzip_min_length 1024;
}
NGINXEOF
  echo "  ✓ 已写入（HTTPS + 80 跳转）"
else
  cat > "$NGINX_CONF" <<'NGINXEOF'
# H5 站点（HTTP 版）—— 由 deploy-h5.sh 生成；以后有证书重跑脚本会自动升级
server {
    listen 80;
    server_name app.journey-plan.cn;

    root /var/www/h5;
    index index.html;

    location /        { try_files $uri $uri/ /index.html; }
    location /assets/ { expires 30d; add_header Cache-Control "public, immutable"; }
    location /static/ { expires 7d;  add_header Cache-Control "public"; }

    gzip on;
    gzip_types text/css application/javascript image/svg+xml;
    gzip_min_length 1024;
}
NGINXEOF
  echo "  ✓ 已写入（HTTP）"
fi
nginx -t
systemctl reload nginx
echo "  ✓ nginx 已 reload"

# ---------------------------------------------------------------- 3. 后端
log "4/4 更新后端（先备份 .env，再解包覆盖）"
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

# CORS：http 与 https 两个来源都加上（HTTPS 生效后浏览器用 https，来源会变）
CUR=$(grep -m1 '^CORS_ORIGINS=' "$APP_DIR/.env" | cut -d= -f2- || true)
MISSING=""
for o in "http://$DOMAIN" "https://$DOMAIN"; do
  case ",$CUR," in
    *",$o,"*) ;;
    *) MISSING="$MISSING,$o" ;;
  esac
done
NEW="${CUR}${MISSING}"; NEW="${NEW#,}"
if [ -n "$MISSING" ]; then
  if [ -n "$CUR" ]; then
    sed -i "s|^CORS_ORIGINS=.*|CORS_ORIGINS=$NEW|" "$APP_DIR/.env"
  else
    printf '\nCORS_ORIGINS=%s\n' "$NEW" >> "$APP_DIR/.env"   # printf：避开「末尾无换行」拼坏上一行
  fi
  echo "  ✓ CORS_ORIGINS = $NEW"
else
  echo "  CORS_ORIGINS 已包含所需来源，跳过"
fi
echo "  .env 末尾 3 行（核对没被拼坏）:"
tail -3 "$APP_DIR/.env" | sed 's/^/    /'

systemctl restart journey-api
sleep 3
systemctl is-active --quiet journey-api || die "journey-api 没起来 —— 看 tail -50 /var/log/journey-api.log"
echo "  ✓ journey-api 正在运行"

# ---------------------------------------------------------------- 自检
log "自检（用 Host 头绕开 DNS，直接打本机 nginx）"
chk() { printf '  %-16s ' "$1"; shift
        curl -sS -m 8 -o /dev/null -w "HTTP %{http_code}\n" "$@" 2>/dev/null || echo "连接失败"; }
chk "H5 首页"  -H "Host: $DOMAIN" http://127.0.0.1/
chk "H5 图标"  -H "Host: $DOMAIN" http://127.0.0.1/static/icons/pin-78716c.svg
chk "后端 docs" http://127.0.0.1:8000/docs
chk "备案页"    -H "Host: www.journey-plan.cn" http://127.0.0.1/
if [ "$HTTPS" = 1 ]; then
  printf '  %-16s ' "80 跳转 443"
  code=$(curl -sS -m 8 -o /dev/null -w "%{http_code}" -H "Host: $DOMAIN" http://127.0.0.1/ 2>/dev/null || echo "?")
  [ "$code" = "301" ] && echo "✓ 301" || echo "✗ 得到 $code"
fi
printf '  %-16s ' "CORS 预检"
cors=$(curl -sS -m 8 -X OPTIONS http://127.0.0.1:8000/auth/login \
        -H "Origin: http://$DOMAIN" -H "Access-Control-Request-Method: POST" \
        -D - -o /dev/null 2>/dev/null | grep -i 'access-control-allow-origin' | tr -d '\r' || true)
[ -n "$cors" ] && echo "✓ $cors" || echo "✗ 未放行！检查 $APP_DIR/.env 的 CORS_ORIGINS"

cat <<EOT

--------------------------------------------------------------------
脚本部分完成。HTTPS 状态：$([ "$HTTPS" = 1 ] && echo "已启用" || echo "未启用（先按 HTTP 跑）")

还差两件只有你能做的：
  1) DNSPod 加一条 A 记录：主机记录 app  →  记录值 43.136.185.171
     （80 端口安全组早就放行了，不用再动；若启用 HTTPS，还要放行 443）

  2) 解析生效后（几分钟），浏览器打开：
       $([ "$HTTPS" = 1 ] && echo "https" || echo "http")://$DOMAIN
     注册一个账号，把流程走一遍

想启用 HTTPS：腾讯云申请免费 DV 证书（域名填 $DOMAIN 整串，
注意 api 那张证书不覆盖它），把 .crt/.key 传到 /root 后**重跑本脚本**即可。
--------------------------------------------------------------------
EOT
