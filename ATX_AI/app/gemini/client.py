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

    def _normalize_model_name(self, model_name: str) -> str:
        name = (model_name or "").strip()
        if name.startswith("models/"):
            name = name[len("models/") :]
        return name

    def _pick_fallback_model(self) -> str | None:
        """Подбирает первую подходящую модель, которая поддерживает generateContent."""
        try:
            models = list(self._genai.list_models())
        except Exception:
            return None

        def supports_generate(m: Any) -> bool:
            methods = getattr(m, "supported_generation_methods", None) or []
            return "generateContent" in methods

        # Prefer flash-like models
        for m in models:
            if not supports_generate(m):
                continue
            name = getattr(m, "name", "") or ""
            if "flash" in name:
                return self._normalize_model_name(name)

        for m in models:
            if not supports_generate(m):
                continue
            name = getattr(m, "name", "") or ""
            if name:
                return self._normalize_model_name(name)
        return None

    def answer(self, prompt: str) -> str:
        self._ensure_configured()

        model_name = self._normalize_model_name(settings.gemini_model)

        def run(name: str) -> str:
            model = self._genai.GenerativeModel(
                model_name=name,
                system_instruction=_system_instruction(),
            )
            resp: Any = model.generate_content(prompt)
            text = getattr(resp, "text", None)
            if not text:
                return "Извините, не удалось получить ответ. Попробуйте переформулировать вопрос."
            return str(text).strip()

        try:
            return run(model_name)
        except Exception as exc:
            # Частая проблема: модель недоступна/не поддерживается в текущей версии API.
            exc_text = str(exc)
            if "is not found" in exc_text or "not supported" in exc_text or "404" in exc_text:
                fallback = self._pick_fallback_model()
                if fallback and fallback != model_name:
                    try:
                        return run(fallback)
                    except Exception:
                        pass
                return (
                    "Gemini сейчас не может обработать запрос из-за несовместимой модели. "
                    "Проверьте GEMINI_MODEL в .env или оставьте его пустым и я подберу доступную модель."
                )

            # Любая другая ошибка Gemini: не валим сервис
            return (
                "Gemini сейчас временно недоступен. Попробуйте позже или переформулируйте вопрос."
            )


gemini_client = GeminiClient()
