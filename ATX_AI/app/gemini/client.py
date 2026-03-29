from __future__ import annotations

from typing import Any

from app.core.config import settings


def _system_instruction() -> str:
    return (
        "Ты — безопасный ИИ-помощник криптокошелька. Отвечай по-русски, кратко и практично. "
        "Никогда не проси и не принимай сид-фразу, приватные ключи, пароль, 2FA-коды, секретные фразы или файлы кошелька. "
        "Если пользователь пытается прислать секреты — останови и предупреди. "
        "Не давай инструкций для мошенничества/взлома/обхода безопасности. "
        "Если вопрос про инвестирование/доходность — дай нейтральную справку и предложи проконсультироваться с профессионалами. "
        "Если данных недостаточно — уточни 1-2 вопроса."
    )


class GeminiClient:
    def __init__(self) -> None:
        self._client: Any | None = None

    def _ensure_configured(self) -> None:
        if not settings.gemini_api_key:
            raise RuntimeError("GEMINI_API_KEY is not set")
        if self._client is not None:
            return

        # Новый SDK
        from google import genai

        self._client = genai.Client(api_key=settings.gemini_api_key)

    def answer(self, prompt: str) -> str:
        self._ensure_configured()

        # Если GEMINI_MODEL пустой — пробуем несколько популярных имён.
        # У разных аккаунтов/регионов/квот доступность моделей может отличаться.
        candidates: list[str] = []
        if settings.gemini_model and settings.gemini_model.strip():
            candidates = [settings.gemini_model.strip()]
        else:
            candidates = [
                "gemini-2.0-flash",
                "gemini-1.5-flash",
                "gemini-1.5-pro",
                "gemini-1.0-pro",
            ]

        last_error: Exception | None = None

        # types.GenerateContentConfig есть в новом SDK
        from google.genai import types

        for model_name in candidates:
            try:
                resp: Any = self._client.models.generate_content(
                    model=model_name,
                    contents=prompt,
                    config=types.GenerateContentConfig(
                        system_instruction=_system_instruction(),
                        temperature=0.2,
                    ),
                )
                text = getattr(resp, "text", None)
                if text:
                    return str(text).strip()
            except Exception as exc:
                last_error = exc
                msg = str(exc).lower()
                # Если модель не найдена/не поддерживается — пробуем следующую
                if "not found" in msg or "is not found" in msg or "404" in msg or "not supported" in msg:
                    continue
                # Неправильный ключ/нет доступа
                if "permission" in msg or "unauthorized" in msg or "api key" in msg:
                    return "Gemini не авторизован. Проверьте GEMINI_API_KEY и права доступа."
                continue

        # Если ни одна модель не подошла
        if last_error is not None:
            return (
                "Gemini сейчас не может обработать запрос (модель недоступна/не поддерживается). "
                "Укажите корректный GEMINI_MODEL в .env или оставьте его пустым и попробуйте снова."
            )

        return "Gemini сейчас недоступен. Попробуйте позже."


gemini_client = GeminiClient()
