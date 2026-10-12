# 部署说明（真实环境记录）

本项目已在**腾讯云轻量应用服务器（OpenCloudOS 9）**上完成部署。下面的脚本与配置即当时实际使用的版本，可直接复用。

> ⚠️ 脚本里的域名（`api.journey-plan.cn`）与证书路径是**本项目的环境**，换环境请自行替换。
> 脚本中**不含任何密码**：MySQL root 密码在运行时由你输入，JWT 密钥在部署时随机生成并写入服务器 `.env`。

## 最终形态

| 项 | 值 |
|---|---|
| 公网入口 | nginx 监听 `80` / `443` |
| 应用 | uvicorn（FastAPI）只监听 `127.0.0.1:8000`，由 nginx 反向代理 |
| 数据库 | MySQL 8.4，只监听 `127.0.0.1:3306` |
| 进程守护 | systemd 服务 `journey-api`（开机自启、崩溃自动拉起） |
| Python | Miniconda 环境 `journey-api`（Python 3.13），依赖按 `requirements.lock.txt` 安装 |
| 证书 | 腾讯云免费 DV 证书（有效期 90 天，需续期） |

**云安全组只放行 `80` / `443`** —— `8000` 与 `3306` 不对公网开放。

## 前置条件

1. **域名解析**：`api` 的 A 记录指向服务器公网 IP
2. **安全组**：放行 `80`、`443`（TCP，来源 `0.0.0.0/0`）
3. **nginx** 已安装（若系统默认源没有 nginx，可加 nginx 官方源安装）

## 步骤

### 1. 部署后端

把以下文件放到服务器 `/root`：

- `journey-plan-api.tar.gz` —— 代码包（含 `requirements.lock.txt`）
- `journey-base.sql` —— 数据库 dump（可选，用于迁移本地数据）
- `deploy-api.sh`

然后执行：

```bash
cd /root && sudo bash deploy-api.sh
```

脚本依次完成：安装 MySQL → 建库并导入 → 创建 Miniconda 环境与依赖 → 写 `.env`（自动生成随机 JWT 密钥）→ 写 systemd unit → 配 nginx 反代 → 自检。

### 2. 启用 HTTPS

把证书（Nginx 格式的 `.crt` + `.key`）传到 `/root`，然后执行：

```bash
cd /root && sudo bash enable-https.sh
```

它会校验证书与私钥是否匹配、写入 `nginx/api.journey-plan.cn.conf` 的内容、`nginx -t` 后 reload，并做一次自检。

### 3. 后续更新代码

```bash
cp /opt/journey-api/.env /root/.env.server.bak     # ① 备份（含服务器专用库密码 + JWT 密钥）

rm -rf /opt/journey-api
tar -xzf /root/journey-plan-api.tar.gz -C /opt
mv /opt/journey-plan-api /opt/journey-api

cp /root/.env.server.bak /opt/journey-api/.env     # ② 还原

systemctl restart journey-api
systemctl is-active journey-api                    # 期望输出 active
```

> 第 ①、② 步**不能省**：包里的 `.env` 是开发机环境（连本机 MySQL），直接覆盖会导致线上连不上数据库。

## 域名备案

大陆服务器上的域名需完成**两项**备案，缺一不可：

1. **ICP 备案**（工信部）—— 网站开通前办理，通过后在首页底部悬挂备案号
2. **公安联网备案** —— 网站开通后 **30 日内**在 <https://beian.mps.gov.cn> 办理

未备案的域名会被运营商拦截。备案页配置见 [`nginx/icp.conf`](nginx/icp.conf)：域名首页需可访问，且**底部同时悬挂 ICP 备案号与公安备案号**，其中 ICP 备案号须链接到 <https://beian.miit.gov.cn/>。

## 排障

| 现象 | 先查什么 |
|---|---|
| 外网打不开 | ① 域名解析是否生效 ② 安全组是否放行 80 / 443 |
| 502 Bad Gateway | `systemctl status journey-api`（多半是应用挂了） |
| 应用起不来 | `tail -80 /var/log/journey-api.log` |
| 连不上数据库 | `grep DATABASE_URL /opt/journey-api/.env`，核对密码是否与设置的一致 |
| AI 接口 502 | 检查 `DASHSCOPE_API_KEY` 是否有效；确认 `agents/config/rag.yml` 里的模型名在 DashScope 上存在 |
