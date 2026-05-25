"""Schemas para panel de propietario."""

from typing import Literal

from pydantic import BaseModel, Field

from app.schemas.common import PaginationMeta
from app.schemas.property import PropertySummaryResponse


class PropertyImageInput(BaseModel):
    """Imagen ya subida a Supabase Storage."""

    image_url: str = Field(..., min_length=1)
    storage_path: str | None = None


class OwnerPropertyCreateRequest(BaseModel):
    """Datos para publicar un inmueble."""

    title: str = Field(..., min_length=3, max_length=160)
    description: str = Field(default="", max_length=1000)
    price: float = Field(..., gt=0)
    operation_type: Literal["Alquiler", "Venta"]
    property_type: str = Field(..., min_length=2, max_length=80)
    zone: str = Field(..., min_length=2, max_length=80)
    amenities: list[str] = Field(default_factory=list)
    images: list[PropertyImageInput] = Field(default_factory=list)


class OwnerPropertyStatusRequest(BaseModel):
    """Cambio de estado de una propiedad del owner."""

    status: Literal["available", "reserved", "sold", "hidden"]


class OwnerPropertyListResponse(BaseModel):
    """Listado paginado de inmuebles del propietario."""

    items: list[PropertySummaryResponse]
    pagination: PaginationMeta


class OwnerMatchResponse(BaseModel):
    """Match/interesado visto desde el panel propietario."""

    match_id: str
    status: str
    buyer_id: str
    buyer_name: str | None = None
    buyer_email: str | None = None
    property: PropertySummaryResponse


class OwnerMatchListResponse(BaseModel):
    """Listado paginado de interesados."""

    items: list[OwnerMatchResponse]
    pagination: PaginationMeta


class MatchStatusUpdateRequest(BaseModel):
    """Cambio de estado de match."""

    status: Literal["active", "contacted", "archived"]
