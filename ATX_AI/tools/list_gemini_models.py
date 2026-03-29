from __future__ import annotations

import os

from pathlib import Path


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

    from google import genai

    client = genai.Client(api_key=api_key)
    try:
        pager = client.models.list()
    except Exception as exc:
        raise SystemExit(f"Failed to list models: {exc}")

    found = False
    for m in pager:
        name = getattr(m, "name", None) or ""
        # В новом SDK поле может называться supported_actions / supported_methods в зависимости от версии.
        supported = (
            getattr(m, "supported_generation_methods", None)
            or getattr(m, "supported_methods", None)
            or getattr(m, "supported_actions", None)
            or []
        )
        if not supported or "generateContent" in supported:
            print(f"{name}  supported={supported}")
            found = True

    if not found:
        print("No models printed (API returned none or schema differs).")


if __name__ == "__main__":
    main()
