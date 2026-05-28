from typing import Literal

from pydantic import BaseModel, Field


class SwipeRequest(BaseModel):
    """Acción del usuario autenticado sobre una propiedad."""

    property_id: str = Field(
        ...,
        examples=["b8ebc4f0-1234-1234-1234-123456789000"],
    )
    action: Literal["like", "nope"] = Field(..., examples=["like"])


class SwipeResponse(BaseModel):
    """Resultado de procesar un swipe real."""

    status: str = Field(default="success")
    message: str
    property_id: str
    action: Literal["like", "nope"]
    is_match: bool = Field(default=False)
    created_match: bool = Field(default=False)
    match_id: str | None = Field(default=None)
