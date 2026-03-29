from __future__ import annotations

from fastapi import APIRouter, Depends, Request, Response

from app.core.config import settings
from app.core.rate_limit import limiter
from app.core.security import require_jwt
from app.llm.client import llm_client
from app.rag.knowledge_base import kb
from app.schemas import ChatRequest, ChatResponse
from app.utils.text import truncate


router = APIRouter(prefix="/v1", tags=["chat"])


def _build_rag_prompt(user_question: str) -> str:
    candidates = kb.retrieve(user_question, top_k=settings.rag_top_k)
    context_lines: list[str] = []
    for score, item in candidates:
        context_lines.append(f"- Q: {item.q}\n  A: {item.a}\n  (score={score})")

    context = "\n".join(context_lines)
    user_q = truncate(user_question.strip(), 2000)

    return (
        "Используй контекст базы знаний ниже, если он релевантен. "
        "Если контекст не помогает — ответь своими словами, но безопасно и без запроса секретов.\n\n"
        f"КОНТЕКСТ (Q&A):\n{context}\n\n"
        f"ВОПРОС ПОЛЬЗОВАТЕЛЯ: {user_q}\n"
    )


@router.post("/chat", response_model=ChatResponse)
@limiter.limit(settings.rate_limit)
def chat(
    body: ChatRequest,
    request: Request,
    response: Response,
    _claims: dict = Depends(require_jwt),
):
    match = kb.find_exact(body.message)
    if match:
        return ChatResponse(answer=match.a, source="kb", matched_question=match.q)

    prompt = _build_rag_prompt(body.message)
    try:
        answer, provider = llm_client.answer(prompt)
    except RuntimeError:
        answer = (
            "Ответ не найден в базе знаний, а LLM сейчас не настроен. "
            "Проверьте GROQ_API_KEY (или LLM_PROVIDER) или добавьте этот вопрос в data/knowledge_base.json."
        )
        provider = "none"
    return ChatResponse(answer=answer, source=provider)
