#!/usr/bin/env bash
# ============================================================================
# JourneyPlan：修「H5 页面提示网络异常」
#
# 病因：浏览器把 H5 调接口的请求拦了 —— 后端 CORS 白名单里没有 app.journey-plan.cn。
#       （前端那句“网络异常，请检查后端服务”就是 uni.request 的 fail 回调文案，
#         CORS 被拦、DNS 失败、超时都会走到它。）
#
# 本脚本只做一件事：让后端放行 http(s)://app.journey-plan.cn
#   - 不动 H5 静态文件、不动 nginx（那两块已经是好的）
#   - 自动判断线上后端代码是否已支持 CORS_ORIGINS：
#       已支持 → 只改 .env 再重启（连 tarball 都不用）
#       不支持 → 需要 /root/journey-plan-api.tar.gz，先更新代码再改 .env
#
# 用法：
#   sudo bash /root/fix-app-cors.sh
#
# 幂等：重复跑不会重复写入；改 .env 前自动备份。
# ============================================================================
set -e
trap 'printf "\n\033[1;31m!! 脚本在第 %s 行出错，已中止\033[0m\n" "$LINENO" >&2' ERR

log() { printf '\n\033[1;36m==> %s\033[0m\n' "$*"; }
die() { printf '\n\033[1;31m!! %s\033[0m\n' "$*" >&2; exit 1; }

[ "$(id -u)" = "0" ] || die "请用 sudo 运行：sudo bash /root/fix-app-cors.sh"

APP_DIR=/opt/journey-api
TARBALL=/root/journey-plan-api.tar.gz
ENVF="$APP_DIR/.env"
DOMAIN=app.journey-plan.cn
WANT="http://$DOMAIN,https://$DOMAIN"

[ -d "$APP_DIR" ] || die "找不到 $APP_DIR —— 后端还没部署过，请先跑 deploy-journey-api.sh"
[ -f "$ENVF" ]    || die "找不到 $ENVF —— 后端 .env 缺失"

# ---------------------------------------------------------------- 1. 现状诊断
log "1/4 诊断当前状况"
CUR=$(grep -m1 '^CORS_ORIGINS=' "$ENVF" | cut -d= -f2- || true)
echo "  .env 里现有 CORS_ORIGINS : ${CUR:-（没有这一行）}"
if grep -q 'CORS_ORIGINS' "$APP_DIR/main.py" 2>/dev/null; then
  CODE_OK=1
  echo "  线上 main.py 支持 CORS_ORIGINS : 是 ✓"
else
  CODE_OK=0
  echo "  线上 main.py 支持 CORS_ORIGINS : 否 ✗ （是旧代码，需要更新）"
fi
echo
echo "  预检实测（现在应该是被拒的）："
curl -sS -m 8 -X OPTIONS "http://127.0.0.1:8000/auth/login" \
  -H "Origin: http://$DOMAIN" -H "Access-Control-Request-Method: POST" \
  -H "Access-Control-Request-Headers: content-type" \
  -D - -o /dev/null 2>/dev/null | grep -iE '^HTTP|access-control-allow-origin' | sed 's/^/    /' || echo "    （后端没响应，检查 systemctl status journey-api）"

# ---------------------------------------------------------------- 2. 必要时更新代码
if [ "$CODE_OK" = 0 ]; then
  log "2/4 线上代码是旧的，需要更新"
  [ -f "$TARBALL" ] || die "缺少 $TARBALL —— 请把本地 deploy-upload/journey-plan-api.tar.gz 传到 /root 后重跑"
  cp "$ENVF" "/root/.env.server.bak"
  echo "  ✓ .env 已备份到 /root/.env.server.bak"
  systemctl stop journey-api 2>/dev/null || true
  rm -rf "$APP_DIR"
  tar -xzf "$TARBALL" -C /opt
  [ -d /opt/journey-plan-api ] || die "解包后没有 /opt/journey-plan-api"
  mv /opt/journey-plan-api "$APP_DIR"
  cp /root/.env.server.bak "$ENVF"
  echo "  ✓ 代码已更新，.env 已还原"
  grep -q 'CORS_ORIGINS' "$APP_DIR/main.py" || die "新代码里仍没有 CORS_ORIGINS —— tarball 是旧的，请重新下载"
else
  log "2/4 代码已支持，跳过更新（只改 .env）"
fi

# ---------------------------------------------------------------- 3. 写 CORS 白名单
log "3/4 把 $WANT 加进 CORS 白名单"
NORMS=""
for o in ${WANT//,/ }; do
  case ",$CUR," in
    *",$o,"*) echo "  · 已存在：$o" ;;
    *) NORMS="$NORMS,$o"; echo "  + 新增：$o" ;;
  esac
done
if [ -n "$NORMS" ]; then
  NEW="${CUR}${NORMS}"; NEW="${NEW#,}"
  if [ -n "$CUR" ]; then
    # 已有该行 → 原地替换，避免拼坏文件
    python3 - "$ENVF" "$NEW" <<'PYEOF' || sed -i "s|^CORS_ORIGINS=.*|CORS_ORIGINS=$NEW|" "$ENVF"
import sys, pathlib
p, v = pathlib.Path(sys.argv[1]), sys.argv[2]
lines = p.read_text(encoding='utf-8').splitlines()
out = []
done = False
for l in lines:
    if l.startswith('CORS_ORIGINS='):
        out.append('CORS_ORIGINS=' + v); done = True
    else:
        out.append(l)
if not done:
    out.append('CORS_ORIGINS=' + v)
p.write_text('\n'.join(out).rstrip('\n') + '\n', encoding='utf-8')
PYEOF
    echo "  ✓ 已更新现有行"
  else
    # 没有该行 → 追加。
    # 用 printf 且开头带 \n：即使 .env 末尾【没有换行符】也不会拼坏上一行
    # （这个坑踩过：echo 追加会把 AMAP_API_KEY 和 CORS_ORIGINS 拼成一行）
    printf '\nCORS_ORIGINS=%s\n' "$NEW" >> "$ENVF"
    echo "  ✓ 已追加新行"
  fi
else
  echo "  · 无需改动"
fi
echo "  --- .env 末尾 4 行（核对没被拼坏）---"
tail -4 "$ENVF" | sed 's/^/    /'
echo "  --- 解析校验 ---"
grep -c '^CORS_ORIGINS=' "$ENVF" | sed 's/^/    独占一行的 CORS_ORIGINS: /'
grep -c '^AMAP_API_KEY=' "$ENVF" | sed 's/^/    AMAP_API_KEY 完好: /'

# ---------------------------------------------------------------- 4. 重启 + 自检
log "4/4 重启后端并自检"
systemctl restart journey-api
sleep 3
systemctl is-active --quiet journey-api || die "journey-api 没起来 —— tail -50 /var/log/journey-api.log"
echo "  ✓ journey-api 正在运行"
echo
echo "  本机预检（来源 = http://$DOMAIN）："
r=$(curl -sS -m 8 -X OPTIONS http://127.0.0.1:8000/auth/login \
     -H "Origin: http://$DOMAIN" -H "Access-Control-Request-Method: POST" \
     -H "Access-Control-Request-Headers: content-type" \
     -D - -o /dev/null 2>/dev/null | grep -i 'access-control-allow-origin' | tr -d '\r')
[ -n "$r" ] && echo "    ✓ $r" || echo "    ✗ 仍未放行（检查上面的 .env 输出）"
echo
echo "  本机预检（来源 = https://$DOMAIN，为以后上 HTTPS 备好）："
r2=$(curl -sS -m 8 -X OPTIONS http://127.0.0.1:8000/auth/login \
      -H "Origin: https://$DOMAIN" -H "Access-Control-Request-Method: POST" \
      -H "Access-Control-Request-Headers: content-type" \
      -D - -o /dev/null 2>/dev/null | grep -i 'access-control-allow-origin' | tr -d '\r')
[ -n "$r2" ] && echo "    ✓ $r2" || echo "    ✗ 未放行"
echo
echo "  真实 POST（来源 = http://$DOMAIN）："
curl -sS -m 10 -X POST http://127.0.0.1:8000/auth/login \
  -H "Origin: http://$DOMAIN" -H "Content-Type: application/json" \
  -d '{"username":"probe_nobody","password":"probe123456"}' \
  -D - -o /dev/null 2>/dev/null | grep -iE '^HTTP|access-control-allow-origin' | sed 's/^/    /'
echo "    （HTTP 401 + 有 allow-origin = 正常：库通了、浏览器也放行了）"

cat <<EOT

--------------------------------------------------------------------
完成。现在用浏览器打开（硬刷新 Ctrl+F5 清缓存）：

    http://$DOMAIN

应该不再提示「网络异常」了。
--------------------------------------------------------------------
EOT
