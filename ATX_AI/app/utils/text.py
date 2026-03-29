from __future__ import annotations

import re


_SPACE_RE = re.compile(r"\s+")
_PUNCT_RE = re.compile(r"[^0-9a-zA-Zа-яА-ЯёЁ\s]+", re.UNICODE)


def normalize_question(text: str) -> str:
    """Нормализация для детерминированного сопоставления вопросов."""

    if text is None:
        return ""
    lowered = text.strip().lower().replace("ё", "е")
    no_punct = _PUNCT_RE.sub(" ", lowered)
    collapsed = _SPACE_RE.sub(" ", no_punct).strip()
    return collapsed


def truncate(text: str, max_len: int) -> str:
    if len(text) <= max_len:
        return text
    return text[: max(0, max_len - 1)] + "…"
