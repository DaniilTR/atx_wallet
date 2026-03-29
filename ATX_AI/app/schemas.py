from __future__ import annotations

from pydantic import BaseModel, Field


class ChatRequest(BaseModel):
    message: str = Field(min_length=1, max_length=4000)
    session_id: str | None = Field(default=None, max_length=128)


class ChatResponse(BaseModel):
    answer: str
    source: str  # "kb" | "groq" | "gemini" | "none"
    matched_question: str | None = None
