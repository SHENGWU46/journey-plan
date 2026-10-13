import os
from pathlib import Path

from dotenv import load_dotenv
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from app.routers import auth_router, plans, user_router
from app.routers.assistant import router as assistant_router

# 显式加载 .env，供下面读 CORS_ORIGINS 使用。
# 不能只依赖 app.settings 里的 load_dotenv —— 那要靠 import 顺序「顺带」触发；
# 一旦 import 结构变动，CORS 白名单会静默变空（接口全被浏览器拦掉，且没有任何报错）。
# 用「相对本文件的路径」而不是 cwd，保证从任何目录启动都读到同一份 .env。
load_dotenv(Path(__file__).resolve().parent / ".env")

app = FastAPI()

# 设计决策 11：开发期 CORS 放行本地来源（http://localhost:*、http://127.0.0.1:*），
# 供 uni-app dev:h5 直连联调；生产再收紧为明确域名。
# 注：Starlette 的 allow_origins 为精确字符串匹配，不支持 `:*` 端口通配，
# 故用 allow_origin_regex 实现「本地任意端口」语义（决策 11 意图）。
#
# 生产来源通过环境变量 CORS_ORIGINS 注入（逗号分隔的完整来源，含协议，如
#   CORS_ORIGINS=https://app.journey-plan.cn,https://foo.example.com
# ）。用环境变量而非硬编码，是为了让「H5 部署在哪个域名」这件事只改 .env、不碰代码。
_LOCAL_ORIGIN_REGEX = r"^http://(localhost|127\.0\.0\.1)(:\d+)?$"
_EXTRA_ORIGINS = [o.strip() for o in os.environ.get("CORS_ORIGINS", "").split(",") if o.strip()]

app.add_middleware(
    CORSMiddleware,
    allow_origins=_EXTRA_ORIGINS,
    allow_origin_regex=_LOCAL_ORIGIN_REGEX,
    allow_credentials=False,
    allow_methods=["*"],
    allow_headers=["*"],
)

app.include_router(auth_router.router)
app.include_router(plans.router)
app.include_router(user_router.router)
app.include_router(assistant_router)

# 数据库建表由 Alembic 迁移管理（alembic/versions/），不在应用启动时 create_all。
# 首次运行：pip install alembic && alembic upgrade head
