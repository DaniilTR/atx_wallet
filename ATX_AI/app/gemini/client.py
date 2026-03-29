from __future__ import annotations

import json
import re
import urllib.error
import urllib.parse
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


class GeminiClient:
    def __init__(self) -> None:
        self._client: Any | None = None

    @staticmethod
    def _safe_error_summary(exc: Exception) -> str:
        # Не светим ключи/токены даже в диагностике
        raw = str(exc) or type(exc).__name__
        raw = re.sub(r"(key=)([^&\s]+)", r"\1***", raw, flags=re.IGNORECASE)
        raw = re.sub(r"(authorization: bearer\s+)(\S+)", r"\1***", raw, flags=re.IGNORECASE)

        status = getattr(exc, "status_code", None) or getattr(exc, "code", None)
        parts: list[str] = [type(exc).__name__]
        if status:
            parts.append(f"status={status}")
        # Сообщение обрезаем, чтобы не тащить потенциальные URL/ключи
        if raw:
            msg = raw.strip().replace("\n", " ")
            if len(msg) > 240:
                msg = msg[:240] + "…"
            parts.append(f"msg={msg}")
        return " ".join(parts)

    @staticmethod
    def _normalize_model_candidates(names: list[str]) -> list[str]:
        out: list[str] = []
        seen: set[str] = set()
        for n in names:
            n = (n or "").strip()
            if not n:
                continue
            for cand in (n, n.removeprefix("models/") if n.startswith("models/") else f"models/{n}"):
                if cand and cand not in seen:
                    out.append(cand)
                    seen.add(cand)
        return out

    def _rest_list_models(self) -> list[str]:
        if not settings.gemini_api_key:
            return []
        base = "https://generativelanguage.googleapis.com/v1beta/models"
        url = f"{base}?key={urllib.parse.quote(settings.gemini_api_key)}"
        req = urllib.request.Request(url, headers={"Accept": "application/json"})
        try:
            with urllib.request.urlopen(req, timeout=15) as resp:
                data = json.loads(resp.read().decode("utf-8"))
        except Exception:
            return []

        models = data.get("models") or []
        names: list[str] = []
        for m in models:
            name = (m or {}).get("name")
            supported = (m or {}).get("supportedGenerationMethods") or []
            if name and (not supported or "generateContent" in supported):
                names.append(str(name))

        # flash сначала
        flash = [n for n in names if "flash" in n]
        return flash + [n for n in names if n not in flash]

    def _rest_generate(self, model_name: str, prompt: str) -> str:
        assert settings.gemini_api_key
        model_path = model_name.strip()
        if not model_path.startswith("models/"):
            model_path = f"models/{model_path}"

        base = "https://generativelanguage.googleapis.com/v1beta"
        url = f"{base}/{model_path}:generateContent?key={urllib.parse.quote(settings.gemini_api_key)}"
        # Самый совместимый формат: складываем system instruction прямо в текст.
        body = {
            "contents": [
                {
                    "parts": [
                        {
                            "text": f"{_system_instruction()}\n\n{prompt}",
                        }
                    ]
                }
            ],
            "generationConfig": {"temperature": 0.2},
        }
        payload = json.dumps(body, ensure_ascii=False).encode("utf-8")
        req = urllib.request.Request(
            url,
            data=payload,
            headers={
                "Content-Type": "application/json; charset=utf-8",
                "Accept": "application/json",
            },
            method="POST",
        )

        try:
            with urllib.request.urlopen(req, timeout=25) as resp:
                data = json.loads(resp.read().decode("utf-8"))
        except urllib.error.HTTPError as http_err:
            # Пытаемся вытащить внятную причину, но без утечки ключа
            try:
                err_body = http_err.read().decode("utf-8", errors="replace")
                err_json = json.loads(err_body)
                message = (((err_json or {}).get("error") or {}).get("message")) or ""
                raise RuntimeError(f"REST HTTP {http_err.code}: {message}") from http_err
            except Exception:
                raise RuntimeError(f"REST HTTP {http_err.code}") from http_err
        except Exception as exc:
            raise RuntimeError("REST request failed") from exc

        candidates = data.get("candidates") or []
        if candidates:
            content = (candidates[0] or {}).get("content") or {}
            parts = content.get("parts") or []
            if parts and isinstance(parts[0], dict):
                text = parts[0].get("text")
                if text:
                    return str(text).strip()

        # Иногда API возвращает promptFeedback с причиной блокировки
        fb = data.get("promptFeedback") or {}
        block_reason = fb.get("blockReason")
        if block_reason:
            return f"Gemini отклонил запрос (blockReason={block_reason})."

        raise RuntimeError("REST: empty response")

    def _ensure_configured(self) -> None:
        if not settings.gemini_api_key:
            raise RuntimeError("GEMINI_API_KEY is not set")
        if self._client is not None:
            return

        # Новый SDK
        from google import genai

        self._client = genai.Client(api_key=settings.gemini_api_key)

    def _list_candidate_models(self) -> list[str]:
        """Пробует получить список моделей из API и вернуть имена.

        Важно: схема ответа может отличаться между версиями SDK, поэтому делаем максимально терпимо.
        """
        assert self._client is not None
        names: list[str] = []
        try:
            pager = self._client.models.list()
            for m in pager:
                name = getattr(m, "name", None) or ""
                if name:
                    names.append(str(name))
        except Exception:
            return []

        # Предпочитаем flash, затем любые
        flash = [n for n in names if "flash" in n]
        return flash + [n for n in names if n not in flash]

    def answer(self, prompt: str) -> str:
        self._ensure_configured()

        # Кандидаты модели:
        # 1) если задано явно — используем только его
        # 2) если не задано — сначала пробуем list() из API (самый надёжный способ)
        # 3) если list() не получилось — пробуем небольшой набор популярных имён
        candidates: list[str]
        if settings.gemini_model and settings.gemini_model.strip():
            candidates = self._normalize_model_candidates([settings.gemini_model.strip()])
        else:
            candidates = self._normalize_model_candidates(self._list_candidate_models())
            if not candidates:
                # Попробуем сначала REST-листинг (часто работает стабильнее, чем SDK)
                rest = self._normalize_model_candidates(self._rest_list_models())
                candidates = rest or self._normalize_model_candidates(
                    [
                        "gemini-2.0-flash",
                        "gemini-1.5-flash",
                        "gemini-1.5-pro",
                        "gemini-1.0-pro",
                    ]
                )

        last_error: Exception | None = None
        last_error_summary: str | None = None

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
                last_error_summary = self._safe_error_summary(exc)
                msg = str(exc).lower()
                # Если модель не найдена/не поддерживается — пробуем следующую
                if "not found" in msg or "is not found" in msg or "404" in msg or "not supported" in msg:
                    continue
                # Неправильный ключ/нет доступа
                if "permission" in msg or "unauthorized" in msg or "api key" in msg:
                    return "Gemini не авторизован. Проверьте GEMINI_API_KEY и права доступа."
                continue

        # SDK не смог — пробуем REST как запасной путь
        for model_name in candidates:
            try:
                return self._rest_generate(model_name, prompt)
            except Exception as exc:
                last_error = exc
                last_error_summary = self._safe_error_summary(exc)
                continue

        # Если ни одна модель не подошла
        if last_error is not None:
            return (
                "Gemini сейчас не может обработать запрос (модель недоступна/не поддерживается). "
                "Укажите корректный GEMINI_MODEL в .env или оставьте его пустым и попробуйте снова. "
                f"(last_error={last_error_summary or type(last_error).__name__})"
            )

        return "Gemini сейчас недоступен. Попробуйте позже."


gemini_client = GeminiClient()
