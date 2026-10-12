#!/usr/bin/env bash
# JourneyPlan 后端一键部署（腾讯云 OpenCloudOS 9）
#
# 前置：把下面 3 个文件传到服务器 /root
#   1) journey-plan-api.tar.gz   （本地打包产物，内含 requirements.lock.txt）
#   2) journey-base.sql          （本地 mysqldump 产物）
#
# 运行： sudo bash deploy-journey-api.sh
#
# 本脚本做：装 MySQL 8.4 → 建库/导数据 → 装 Miniconda + Python3.13 → 装依赖
#          → 写 .env（自动生成 JWT 密钥）→ systemd 常驻 → nginx 反代 → 自检
set -euo pipefail

APP_DIR="/opt/journey-api"
DB_NAME="journey-base"
DOMAIN="api.journey-plan.cn"
APP_PORT="8000"
CONDA_DIR="/opt/miniconda3"
ENV_NAME="journey-api"
TARBALL="/root/journey-plan-api.tar.gz"
DUMPFILE="/root/journey-base.sql"
PIP_MIRROR="https://pypi.tuna.tsinghua.edu.cn/simple"

log() { printf '\n\033[1;36m==> %s\033[0m\n' "$*"; }
die() { printf '\n\033[1;31m!! %s\033[0m\n' "$*" >&2; exit 1; }

# set -e 下出错会「静默退出」，这里兜一层，至少告诉你卡在哪一行
trap 'printf "\n\033[1;31m!! 脚本在第 %s 行出错并中止。把上面最后几行输出发我。\033[0m\n" "$LINENO" >&2' ERR

[ "$(id -u)" = "0" ] || die "请用 root 运行：sudo bash $0"
[ -f "$TARBALL" ] || die "找不到 $TARBALL"
[ -f "$DUMPFILE" ] || die "找不到 $DUMPFILE"
log "磁盘剩余空间"; df -h /opt 2>/dev/null | tail -1 || true
df -P /opt 2>/dev/null | awk 'NR==2{ if ($4+0 < 3*1024*1024) print "警告：/opt 剩余不足 3GB，可能装不下" }' || true

# ------------------------------------------------ 1. 解包
log "解包到 $APP_DIR"
rm -rf "$APP_DIR"
ROOT_IN_TAR="$(tar -tzf "$TARBALL" 2>/dev/null | sed -n '1p' | cut -d/ -f1 || true)"
tar -xzf "$TARBALL" -C /opt
if [ "$ROOT_IN_TAR" != "$(basename "$APP_DIR")" ]; then
  mv "/opt/$ROOT_IN_TAR" "$APP_DIR"
fi
[ -f "$APP_DIR/requirements.lock.txt" ] || die "包内缺少 requirements.lock.txt（本地打包前要放进项目目录）"

# ------------------------------------------------ 2. MySQL 8.4
if [ ! -x /usr/sbin/mysqld ] && [ ! -x /usr/bin/mysqld ]; then
  log "安装 MySQL 8.4（先试默认源，失败则用 MySQL 官方 el9 仓库）"
  if ! dnf install -y mysql-server --disableexcludes=all; then
    log "默认源无 mysql-server，改用官方仓库"
    dnf install -y https://dev.mysql.com/get/mysql84-community-release-el9-1.noarch.rpm
    dnf install -y mysql-community-server --nogpgcheck
  fi
fi
log "启动 mysqld"
systemctl enable --now mysqld
systemctl is-active --quiet mysqld || die "mysqld 启动失败，看 journalctl -u mysqld"

# ------------------------------------------------ 3. root 密码
# 三种情况都要能过：全新未设密码 / 刚装完只有临时密码 / 已经设过密码（重跑）
log "配置 MySQL root 密码"
ask_new_pass() {
  echo "→ 请为 MySQL root 设置一个新密码（建议 12 位以上，含大小写+数字+符号）"
  echo "  （输入时不显示字符，这是正常的）"
  read -rs NEWPASS; echo
  [ -n "$NEWPASS" ] || die "密码不能为空"
}
ask_old_pass() {
  echo "→ 请输入 MySQL root 的【现有密码】"
  echo "  它是你上次运行本脚本时设置的那个，不是你登录 Linux 的用户名 root。"
  echo "  （输入时不显示字符；想先验证，可另开一个终端执行 mysql -uroot -p）"
  local i
  for i in 1 2 3; do
    read -rs DB_PASS; echo
    if mysql -uroot -p"$DB_PASS" -e "SELECT 1" >/dev/null 2>&1; then return 0; fi
    echo "  ✗ 密码不对，再试一次（$i/3）"
  done
  die "root 密码连续 3 次不正确。忘了密码时，见《部署执行清单》底部的重置步骤"
}
if mysql -uroot -e "SELECT 1" >/dev/null 2>&1; then
  ask_new_pass
  mysql -uroot -e "ALTER USER 'root'@'localhost' IDENTIFIED BY '${NEWPASS}'; FLUSH PRIVILEGES;"
  DB_PASS="$NEWPASS"
else
  # 注意：pipefail 下 grep 找不到时整条管道会返回非 0，若不加 || true 会被 set -e 静默杀掉
  TMPPW="$( { grep 'temporary password' /var/log/mysqld.log 2>/dev/null || true; } | tail -1 | awk '{print $NF}' || true)"
  if [ -n "$TMPPW" ] && mysql -uroot -p"$TMPPW" -e "SELECT 1" >/dev/null 2>&1; then
    ask_new_pass
    mysql -uroot -p"$TMPPW" -e "ALTER USER 'root'@'localhost' IDENTIFIED BY '${NEWPASS}'; FLUSH PRIVILEGES;"
    DB_PASS="$NEWPASS"
  else
    ask_old_pass
  fi
fi
MYSQL=(mysql -uroot -p"$DB_PASS")
"${MYSQL[@]}" -e "SELECT VERSION();"

# ------------------------------------------------ 4. 导入数据
log "导入 $DUMPFILE"
"${MYSQL[@]}" < "$DUMPFILE"
log "导入结果"
"${MYSQL[@]}" -e "USE \`$DB_NAME\`; SHOW TABLES; SELECT * FROM alembic_version;"

# ------------------------------------------------ 5. Python 3.13（Miniconda）
if [ ! -x "$CONDA_DIR/bin/conda" ]; then
  log "安装 Miniconda（清华镜像）"
  curl -fsSL -o /tmp/miniconda.sh \
    https://mirrors.tuna.tsinghua.edu.cn/anaconda/miniconda/Miniconda3-latest-Linux-x86_64.sh
  bash /tmp/miniconda.sh -b -p "$CONDA_DIR"
fi
log "创建环境 $ENV_NAME (Python 3.13)"
CONDA_BIN="$CONDA_DIR/bin/conda"
PYBIN="$CONDA_DIR/envs/$ENV_NAME/bin/python"
# 环境已存在就跳过创建（重跑时 conda create 会因 prefix 已存在而报错）
if [ -x "$PYBIN" ]; then
  log "已存在 conda 环境 $ENV_NAME，跳过创建"
else
  log "创建环境 $ENV_NAME (Python 3.13)"
  # 新版 conda 要求先接受 Anaconda 默认频道的 ToS，否则非交互下报
  # CondaToSNonInteractiveError。这里静默接受；老版本没有 tos 子命令，失败无妨。
  "$CONDA_BIN" tos accept --override-channels --channel https://repo.anaconda.com/pkgs/main >/dev/null 2>&1 || true
  "$CONDA_BIN" tos accept --override-channels --channel https://repo.anaconda.com/pkgs/r >/dev/null 2>&1 || true

  if ! "$CONDA_BIN" create -y -n "$ENV_NAME" python=3.13 >/dev/null 2>&1; then
    log "默认频道不可用，改用 conda-forge"
    if ! "$CONDA_BIN" create -y -n "$ENV_NAME" python=3.13 -c conda-forge --override-channels; then
      log "conda-forge 直连失败，改用清华镜像"
      "$CONDA_BIN" create -y -n "$ENV_NAME" python=3.13 --override-channels \
        -c https://mirrors.tuna.tsinghua.edu.cn/anaconda/cloud/conda-forge
    fi
  fi
  [ -x "$PYBIN" ] || die "conda 环境创建失败，请把上面的输出发我"
fi
"$PYBIN" -V

log "安装依赖（149 个包，耐心等几分钟）"
"$PYBIN" -m pip install -q -U pip -i "$PIP_MIRROR"
# 用 --no-deps 是关键：pip freeze 导出的是「实际装了什么」，未必是一组能通过
# 依赖解析的组合（本例 langchain-core==1.4.1 与 langchain==1.3.4 的约束冲突）。
# --no-deps 才能原样复刻本地环境；因为 freeze 已含全部传递依赖，不会缺包。
if ! "$PYBIN" -m pip install -q --no-deps -r "$APP_DIR/requirements.lock.txt" -i "$PIP_MIRROR"; then
  log "lock 原样安装失败，退回用 requirements.txt 让 pip 重新解析版本"
  "$PYBIN" -m pip install -q -r "$APP_DIR/requirements.txt" -i "$PIP_MIRROR"
fi

# ------------------------------------------------ 6. 写 .env
log "更新 .env（DATABASE_URL + 随机 JWT 密钥）"
if [ -f "$APP_DIR/.env" ]; then cp "$APP_DIR/.env" "$APP_DIR/.env.from-local.bak"; fi
JWT_SECRET="$("$PYBIN" -c 'import secrets;print(secrets.token_urlsafe(48))')"
APP_DIR="$APP_DIR" DB_NAME="$DB_NAME" DB_PASS="$DB_PASS" JWT_SECRET="$JWT_SECRET" \
"$PYBIN" - <<'PYEOF'
import os, pathlib
env = pathlib.Path(os.environ["APP_DIR"]) / ".env"
url = 'mysql+aiomysql://root:{}@127.0.0.1:3306/{}?charset=utf8mb4'.format(
    os.environ["DB_PASS"], os.environ["DB_NAME"])
lines = env.read_text(encoding="utf-8").splitlines() if env.exists() else []
out, seen_db, seen_jwt = [], False, False
for ln in lines:
    if ln.startswith("DATABASE_URL="):
        out.append('DATABASE_URL="%s"' % url); seen_db = True
    elif ln.startswith("JWT_SECRET_KEY="):
        out.append("JWT_SECRET_KEY=%s" % os.environ["JWT_SECRET"]); seen_jwt = True
    else:
        out.append(ln)
if not seen_db:
    out.append('DATABASE_URL="%s"' % url)
if not seen_jwt:
    out.append("JWT_SECRET_KEY=%s" % os.environ["JWT_SECRET"])
env.write_text("\n".join(out) + "\n", encoding="utf-8")
print("已写入:", env)
PYEOF

# ------------------------------------------------ 7. systemd
log "注册 systemd 服务"
cat > /etc/systemd/system/journey-api.service <<EOF
[Unit]
Description=JourneyPlan API (uvicorn)
After=network.target mysqld.service

[Service]
Type=simple
WorkingDirectory=$APP_DIR
ExecStart=$CONDA_DIR/envs/$ENV_NAME/bin/uvicorn main:app --host 127.0.0.1 --port $APP_PORT
Restart=always
RestartSec=3
StandardOutput=append:/var/log/journey-api.log
StandardError=append:/var/log/journey-api.log

[Install]
WantedBy=multi-user.target
EOF
systemctl daemon-reload
systemctl enable --now journey-api
sleep 4
systemctl is-active --quiet journey-api || {
  echo "--- 最近日志 ---"; tail -30 /var/log/journey-api.log || true
  die "服务启动失败（见上面日志）"
}
log "本机自检"
curl -s -o /dev/null -w "GET /docs  ->  HTTP %{http_code}\n" "http://127.0.0.1:$APP_PORT/docs" || true

# ------------------------------------------------ 8. nginx 反代
log "配置 nginx 反代 $DOMAIN"
cat > /etc/nginx/conf.d/journey-api.conf <<EOF
server {
    listen 80;
    server_name $DOMAIN;

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
if command -v nginx >/dev/null 2>&1; then
  nginx -t && systemctl reload nginx
else
  echo "!! 没检测到 nginx，请先装好 nginx 再手动 reload（/etc/nginx/conf.d/journey-api.conf 已写好）"
fi

# ------------------------------------------------ 9. 收尾
cat <<'DONE'

================================================================
 部署完成。还差两件「只有你能做」的事：

 1. 腾讯云 DNS 解析：加一条 A 记录
      api  ->  <你的服务器公网 IP>

 2. 腾讯云安全组：放行 80、443
      （不要放 8000，也不要放 3306）

 之后验证：浏览器打开  http://api.journey-plan.cn/docs
 日志：    tail -f /var/log/journey-api.log
 重启：    systemctl restart journey-api
 数据库：  /opt/journey-api/.env.from-local.bak 是本地原 .env 备份
================================================================
DONE
