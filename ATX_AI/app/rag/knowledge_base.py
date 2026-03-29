from __future__ import annotations

import json
from dataclasses import dataclass
from pathlib import Path

from app.core.config import BASE_DIR, settings
from app.utils.text import normalize_question

try:
    from rapidfuzz import fuzz

    def similarity(a: str, b: str) -> int:
        return int(fuzz.token_set_ratio(a, b))


except Exception:  # pragma: no cover
    from difflib import SequenceMatcher

    def similarity(a: str, b: str) -> int:
        return int(100 * SequenceMatcher(None, a, b).ratio())


@dataclass(frozen=True)
class KBItem:
    q: str
    a: str
    q_norm: str


class KnowledgeBase:
    def __init__(self, items: list[KBItem]):
        self._items = items
        self._by_norm: dict[str, KBItem] = {i.q_norm: i for i in items}

    @staticmethod
    def load(path: str) -> "KnowledgeBase":
        file_path = Path(path)
        if not file_path.is_absolute():
            file_path = BASE_DIR / file_path

        raw = json.loads(file_path.read_text(encoding="utf-8"))
        items: list[KBItem] = []
        for entry in raw:
            q = str(entry.get("q", "")).strip()
            a = str(entry.get("a", "")).strip()
            if not q or not a:
                continue
            items.append(KBItem(q=q, a=a, q_norm=normalize_question(q)))
        return KnowledgeBase(items)

    def find_exact(self, question: str) -> KBItem | None:
        qn = normalize_question(question)
        if not qn:
            return None
        direct = self._by_norm.get(qn)
        if direct:
            return direct

        threshold = int(settings.fuzzy_exact_threshold or 0)
        if threshold <= 0:
            return None

        best: tuple[int, KBItem] | None = None
        for item in self._items:
            score = similarity(qn, item.q_norm)
            if best is None or score > best[0]:
                best = (score, item)
        if best and best[0] >= threshold:
            return best[1]
        return None

    def retrieve(self, question: str, top_k: int) -> list[tuple[int, KBItem]]:
        qn = normalize_question(question)
        scored: list[tuple[int, KBItem]] = []
        for item in self._items:
            scored.append((similarity(qn, item.q_norm), item))
        scored.sort(key=lambda x: x[0], reverse=True)
        return scored[: max(0, int(top_k))]


kb = KnowledgeBase.load(settings.knowledge_base_path)
