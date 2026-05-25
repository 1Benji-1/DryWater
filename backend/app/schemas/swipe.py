from typing import Literal

from pydantic import AliasChoices, BaseModel, ConfigDict, Field


class SwipeRequest(BaseModel):
    """Acción del usuario sobre una propiedad.

    En Fase 2 el user_id viene desde el token Supabase.
    """

    model_config = ConfigDict(populate_by_name=True)

    property_id: str = Field(
        ...,
        validation_alias=AliasChoices("property_id", "id_inmueble"),
        examples=["b8ebc4f0-1234-1234-1234-123456789000"],
    )
    action: Literal["like", "nope"] = Field(
        ...,
        validation_alias=AliasChoices("action", "accion"),
        examples=["like"],
    )


class SwipeResponse(BaseModel):
    """Resultado de procesar un swipe."""

    status: str = Field(default="success")
    message: str
    property_id: str
    action: Literal["like", "nope"]
    is_match: bool = Field(default=False)
