"""Schemas para matches y contacto.

Fase 7 centraliza el contrato de matches:
- Buyer ve matches reales, no solamente swipes likeados.
- Owner ve interesados.
- El estado del match solo puede ser active/contacted/archived.
"""

from typing import Literal

from pydantic import BaseModel, Field

from app.schemas.common import PaginationMeta
from app.schemas.property import PropertySummaryResponse

MatchStatus = Literal["active", "contacted", "archived"]


class MatchStatusUpdateRequest(BaseModel):
    """Cambio controlado de estado de match."""

    status: MatchStatus = Field(..., examples=["contacted"])


class MatchItemResponse(BaseModel):
    """Match visto desde el usuario comprador/inquilino."""

    match_id: str
    status: MatchStatus = "active"
    owner_id: str | None = None
    owner_name: str | None = None
    owner_phone: str | None = None
    property: PropertySummaryResponse


class MatchListResponse(BaseModel):
    """Respuesta paginada de matches del buyer."""

    items: list[MatchItemResponse]
    pagination: PaginationMeta


class OwnerMatchResponse(BaseModel):
    """Match/interesado visto desde el panel propietario."""

    match_id: str
    status: MatchStatus = "active"
    buyer_id: str
    buyer_name: str | None = None
    buyer_email: str | None = None
    buyer_phone: str | None = None
    property: PropertySummaryResponse


class OwnerMatchListResponse(BaseModel):
    """Listado paginado de interesados para owner/admin."""

    items: list[OwnerMatchResponse]
    pagination: PaginationMeta
