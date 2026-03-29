from __future__ import annotations

import json
import re
import urllib.error
import urllib.request
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


class GroqClient:
    @staticmethod
    def _safe_error_summary(exc: Exception) -> str:
        raw = str(exc) or type(exc).__name__
        raw = re.sub(r"(authorization: bearer\s+)(\S+)", r"\1***", raw, flags=re.IGNORECASE)
        status = getattr(exc, "status_code", None) or getattr(exc, "code", None)
        parts: list[str] = [type(exc).__name__]
        if status:
            parts.append(f"status={status}")
        if raw:
            msg = raw.strip().replace("\n", " ")
            if len(msg) > 240:
                msg = msg[:240] + "…"
            parts.append(f"msg={msg}")
        return " ".join(parts)

    def _candidate_models(self) -> list[str]:
        if settings.groq_model and settings.groq_model.strip():
            return [settings.groq_model.strip()]
        # Набор популярных моделей Groq. Если какая-то недоступна в аккаунте — попробуем следующую.
        return [
            "llama-3.1-8b-instant",
            "llama-3.3-70b-versatile",
            "llama-3.1-70b-versatile",
            "mixtral-8x7b-32768",
        ]

    def answer(self, prompt: str) -> str:
        if not settings.groq_api_key:
            raise RuntimeError("GROQ_API_KEY is not set")

        url = "https://api.groq.com/openai/v1/chat/completions"
        headers = {
            "Authorization": f"Bearer {settings.groq_api_key}",
            "Content-Type": "application/json; charset=utf-8",
            "Accept": "application/json",
        }

        last_error: Exception | None = None
        last_error_summary: str | None = None

        for model in self._candidate_models():
            payload = {
                "model": model,
                "messages": [
                    {"role": "system", "content": _system_instruction()},
                    {"role": "user", "content": prompt},
                ],
                "temperature": 0.2,
            }
            data = json.dumps(payload, ensure_ascii=False).encode("utf-8")
            req = urllib.request.Request(url, data=data, headers=headers, method="POST")

            try:
                with urllib.request.urlopen(req, timeout=30) as resp:
                    body = resp.read().decode("utf-8")
                    obj: Any = json.loads(body)

                choices = obj.get("choices") or []
                if choices:
                    msg = (choices[0] or {}).get("message") or {}
                    content = msg.get("content")
                    if content:
                        return str(content).strip()

                raise RuntimeError("Groq: empty response")

            except urllib.error.HTTPError as http_err:
                last_error = http_err
                api_message = ""
                raw_snippet = ""
                try:
                    err_body = http_err.read().decode("utf-8", errors="replace")
                    raw_snippet = err_body.strip().replace("\n", " ")
                    if len(raw_snippet) > 300:
                        raw_snippet = raw_snippet[:300] + "…"
                    err_json: Any = json.loads(err_body)
                    api_message = (err_json.get("error") or {}).get("message") or ""
                    last_error_summary = (
                        f"HTTP {http_err.code}: {api_message}" if api_message else f"HTTP {http_err.code}"
                    )
                except Exception:
                    last_error_summary = self._safe_error_summary(http_err)

                # 401/403 — ключ/права; дальше пробовать модели нет смысла
                if http_err.code in (401, 403):
                    details = f"HTTP {http_err.code}: {api_message}" if api_message else f"HTTP {http_err.code}"
                    if http_err.code == 403:
                        # Часто 403 — это запрет на использование конкретной модели в проекте.
                        hint = (
                            "Проверьте, что GROQ_MODEL соответствует разрешённой модели в проекте "
                            "(например, openai/gpt-oss-120b)."
                        )
                        extra = f" body={raw_snippet}" if raw_snippet and not api_message else ""
                        return f"Groq запретил запрос. {hint} ({details}{extra})"

                    extra = f" body={raw_snippet}" if raw_snippet and not api_message else ""
                    return f"Groq не авторизован. Проверьте GROQ_API_KEY и права доступа. ({details}{extra})"
                # 404/400 — модель может быть недоступна/не поддерживается → пробуем следующую
                if http_err.code in (400, 404):
                    continue
                # 429 — лимит/квота
                if http_err.code == 429:
                    return "Groq вернул 429 (слишком много запросов). Подождите и попробуйте снова."

                continue

            except Exception as exc:
                last_error = exc
                last_error_summary = self._safe_error_summary(exc)
                continue

        if last_error is not None:
            raise RuntimeError(f"Groq request failed ({last_error_summary or type(last_error).__name__})")

        raise RuntimeError("Groq is unavailable")


groq_client = GroqClient()
