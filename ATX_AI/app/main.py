from __future__ import annotations

from fastapi import FastAPI, Request
from slowapi.errors import RateLimitExceeded
from slowapi.middleware import SlowAPIMiddleware
from starlette.middleware.cors import CORSMiddleware
from starlette.responses import JSONResponse

from app.core.config import settings
from app.core.rate_limit import limiter
from app.routers.chat import router as chat_router


def create_app() -> FastAPI:
    app = FastAPI(title=settings.app_name)
    app.state.limiter = limiter

    cors = [o.strip() for o in (settings.cors_origins or "").split(",") if o.strip()]
    if cors:
        app.add_middleware(
            CORSMiddleware,
            allow_origins=cors,
            allow_credentials=True,
            allow_methods=["*"],
            allow_headers=["*"],
        )

    app.add_middleware(SlowAPIMiddleware)

    @app.exception_handler(RateLimitExceeded)
    def _rate_limit_handler(_request: Request, exc: RateLimitExceeded):
        return JSONResponse(status_code=429, content={"detail": "Rate limit exceeded"})

    @app.get("/health", tags=["health"])
    def health():
        return {"ok": True, "env": settings.app_env}

    app.include_router(chat_router)
    return app


app = create_app()
