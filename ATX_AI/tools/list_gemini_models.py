from __future__ import annotations

import os


def main() -> None:
    api_key = os.getenv("GEMINI_API_KEY", "").strip()
    if not api_key:
        raise SystemExit("GEMINI_API_KEY is not set")

    import google.generativeai as genai

    genai.configure(api_key=api_key)

    models = list(genai.list_models())
    if not models:
        print("No models returned")
        return

    def supports_generate(m) -> bool:
        methods = getattr(m, "supported_generation_methods", None) or []
        return "generateContent" in methods

    for m in models:
        name = getattr(m, "name", "")
        methods = getattr(m, "supported_generation_methods", None) or []
        if supports_generate(m):
            print(f"{name}  methods={methods}")


if __name__ == "__main__":
    main()
