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
        raise SystemExit(f"Failed to list models (rest={type(exc).__name__})")

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
