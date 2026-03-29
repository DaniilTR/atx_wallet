from __future__ import annotations

from typing import Any

from fastapi import Depends, HTTPException, Request
from fastapi.security import HTTPAuthorizationCredentials, HTTPBearer
from jose import jwt
from jose.exceptions import ExpiredSignatureError, JWTError

from app.core.config import settings


bearer_scheme = HTTPBearer(auto_error=False)


def _get_verify_key() -> str:
    alg = (settings.jwt_alg or "").upper()
    if alg.startswith("HS"):
        if not settings.jwt_secret:
            raise RuntimeError("JWT_SECRET is required for HS* algorithms")
        return settings.jwt_secret

    if alg.startswith("RS"):
        if not settings.jwt_public_key:
            raise RuntimeError("JWT_PUBLIC_KEY is required for RS* algorithms")
        return settings.jwt_public_key

    raise RuntimeError(f"Unsupported JWT_ALG: {settings.jwt_alg}")


def verify_jwt_token(token: str) -> dict[str, Any]:
    try:
        options = {"verify_aud": bool(settings.jwt_audience)}
        payload = jwt.decode(
            token,
            _get_verify_key(),
            algorithms=[settings.jwt_alg],
            issuer=settings.jwt_issuer,
            audience=settings.jwt_audience,
            options=options,
        )
        return payload
    except RuntimeError as exc:
        raise HTTPException(status_code=503, detail=str(exc)) from exc
    except ExpiredSignatureError as exc:
        raise HTTPException(status_code=401, detail="JWT expired") from exc
    except JWTError as exc:
        raise HTTPException(status_code=401, detail="Invalid JWT") from exc


async def require_jwt(
    request: Request,
    credentials: HTTPAuthorizationCredentials | None = Depends(bearer_scheme),
) -> dict[str, Any]:
    if credentials is None or not credentials.credentials:
        raise HTTPException(status_code=401, detail="Missing Authorization Bearer token")

    # MVP: общий токен без JWT (когда нет логинов/аккаунтов)
    if settings.shared_bearer_token and credentials.credentials == settings.shared_bearer_token:
        request.state.user_id = "shared"
        return {"sub": "shared", "auth": "shared_bearer"}

    claims = verify_jwt_token(credentials.credentials)
    user_id = claims.get("sub") or claims.get("user_id")
    if user_id:
        request.state.user_id = str(user_id)
    return claims
