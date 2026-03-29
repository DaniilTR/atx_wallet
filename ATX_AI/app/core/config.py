from __future__ import annotations

from pathlib import Path

from pydantic_settings import BaseSettings, SettingsConfigDict


BASE_DIR = Path(__file__).resolve().parents[2]


class Settings(BaseSettings):
    model_config = SettingsConfigDict(
        env_file=str(BASE_DIR / ".env"),
        env_file_encoding="utf-8",
        extra="ignore",
    )

    app_name: str = "ATX_AI"
    app_env: str = "dev"
    cors_origins: str = ""

    jwt_alg: str = "HS256"
    jwt_secret: str | None = None
    jwt_public_key: str | None = None
    jwt_issuer: str | None = None
    jwt_audience: str | None = None

    # MVP-режим без аккаунтов: один общий Bearer-токен для всех клиентов.
    # Если задан, то запрос считается авторизованным, когда Authorization: Bearer <token> совпал.
    shared_bearer_token: str | None = None

    rate_limit: str = "30/minute"

    knowledge_base_path: str = "data/knowledge_base.json"
    rag_top_k: int = 5
    fuzzy_exact_threshold: int = 95

    gemini_api_key: str | None = None
    # Если пусто/None — сервис сам попробует выбрать доступную модель.
    gemini_model: str | None = None


settings = Settings()
