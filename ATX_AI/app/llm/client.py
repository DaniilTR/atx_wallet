from __future__ import annotations

from app.core.config import settings
from app.llm.groq_client import groq_client


class LLMClient:
    def answer(self, prompt: str) -> tuple[str, str]:
        provider = (settings.llm_provider or "auto").strip().lower()

        if provider in ("none", "off", "disabled"):
            raise RuntimeError("LLM provider disabled")

        if provider in ("auto", ""):
            if settings.groq_api_key:
                return groq_client.answer(prompt), "groq"
            if settings.gemini_api_key:
                from app.gemini.client import gemini_client

                return gemini_client.answer(prompt), "gemini"
            raise RuntimeError("No LLM provider configured")

        if provider == "groq":
            return groq_client.answer(prompt), "groq"

        if provider == "gemini":
            from app.gemini.client import gemini_client

            return gemini_client.answer(prompt), "gemini"

        raise RuntimeError(f"Unknown LLM provider: {provider}")


llm_client = LLMClient()
