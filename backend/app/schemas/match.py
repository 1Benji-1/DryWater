"""Schemas para matches."""

from pydantic import BaseModel

from app.schemas.common import PaginationMeta
from app.schemas.property import PropertySummaryResponse


class MatchListResponse(BaseModel):
    """Respuesta paginada de propiedades gustadas/matcheadas."""

    items: list[PropertySummaryResponse]
    pagination: PaginationMeta

