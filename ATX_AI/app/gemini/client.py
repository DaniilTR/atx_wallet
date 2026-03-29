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
        self._configured = False

    def _ensure_configured(self) -> None:
        if self._configured:
            return
        if not settings.gemini_api_key:
            raise RuntimeError("GEMINI_API_KEY is not set")
        import google.generativeai as genai

        genai.configure(api_key=settings.gemini_api_key)
        self._genai = genai
        self._configured = True

    def answer(self, prompt: str) -> str:
        self._ensure_configured()

        model = self._genai.GenerativeModel(
            model_name=settings.gemini_model,
            system_instruction=_system_instruction(),
        )
        resp: Any = model.generate_content(prompt)
        text = getattr(resp, "text", None)
        if not text:
            return "Извините, не удалось получить ответ. Попробуйте переформулировать вопрос."
        return str(text).strip()


gemini_client = GeminiClient()
