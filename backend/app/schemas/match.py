"""Schemas para matches y cálculo de compatibilidad."""

from pydantic import BaseModel, Field

from app.schemas.common import PaginationMeta
from app.schemas.property import PropertySummaryResponse


class MatchRequest(BaseModel):
    """Solicitud académica para calcular mejores opciones por requisitos."""

    presupuesto_max: float = Field(..., gt=0, examples=[4000])
    requisitos: list[str] = Field(default_factory=list, examples=[["Piscina", "Gimnasio"]])


class MatchListResponse(BaseModel):
    """Respuesta paginada de propiedades gustadas/matcheadas."""

    items: list[PropertySummaryResponse]
    pagination: PaginationMeta
