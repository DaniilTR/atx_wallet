from __future__ import annotations

import json
import os
import urllib.parse
import urllib.request

from pathlib import Path


def _rest_list_models(api_key: str) -> list[dict]:
    url = (
        "https://generativelanguage.googleapis.com/v1beta/models"
        f"?key={urllib.parse.quote(api_key)}"
    )
    req = urllib.request.Request(url, headers={"Accept": "application/json"})
    with urllib.request.urlopen(req, timeout=15) as resp:
        data = json.loads(resp.read().decode("utf-8"))
    return data.get("models") or []


def _format_http_error(err: Exception) -> str:
    if not isinstance(err, urllib.error.HTTPError):
        return f"{type(err).__name__}: {err}"

    code = getattr(err, "code", None)
    try:
        body = err.read().decode("utf-8", errors="replace")
    except Exception:
        body = ""

    message = ""
    if body:
        try:
            data = json.loads(body)
            message = (((data or {}).get("error") or {}).get("message")) or ""
        except Exception:
            message = body.strip().replace("\n", " ")

    if message and len(message) > 400:
        message = message[:400] + "…"

    if code:
        return f"HTTP {code}: {message}" if message else f"HTTP {code}"
    return f"HTTPError: {message}" if message else "HTTPError"


def main() -> None:
    # Подхватываем .env, если переменные не экспортированы в окружение
    try:
        from dotenv import load_dotenv

        load_dotenv(dotenv_path=Path(__file__).resolve().parents[1] / ".env")
    except Exception:
        pass

    api_key = os.getenv("GEMINI_API_KEY", "").strip()
    if not api_key:
        raise SystemExit("GEMINI_API_KEY is not set")

    try:
        models = _rest_list_models(api_key)
    except Exception as exc:
        raise SystemExit(f"Failed to list models ({_format_http_error(exc)})")

    found = False
    for m in models:
        name = (m or {}).get("name") or ""
        supported = (m or {}).get("supportedGenerationMethods") or []
        if not supported or "generateContent" in supported:
            print(f"{name}  supported={supported}")
            found = True

    if not found:
        print("No models printed (REST returned none or schema differs).")


if __name__ == "__main__":
    main()
