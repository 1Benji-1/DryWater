"""Schemas de propiedades/inmuebles."""

from pydantic import BaseModel, Field

from app.schemas.common import PaginationMeta


PLACEHOLDER_IMAGE_URL = "https://via.placeholder.com/800x600.png?text=Rent+App"


def _to_float(value: object, default: float = 0.0) -> float:
    """Convierte un valor numérico a float sin romper la API."""

    try:
        return float(value)  # type: ignore[arg-type]
    except (TypeError, ValueError):
        return default


def _to_string_list(value: object) -> list[str]:
    """Convierte arrays de Supabase o strings heredados a lista limpia."""

    if isinstance(value, list):
        return [str(item).strip() for item in value if str(item).strip()]

    if isinstance(value, str):
        if "|" in value:
            return [item.strip() for item in value.split("|") if item.strip()]
        if value.strip():
            return [value.strip()]

    return []


class PropertySummaryResponse(BaseModel):
    """Propiedad resumida para tarjetas y listados."""

    id: str = Field(..., examples=["b8ebc4f0-1234-1234-1234-123456789000"])
    title: str = Field(..., examples=["Departamento en Equipetrol"])
    description: str = Field(..., examples=["Piscina, Gimnasio, Amoblado"])
    price: float = Field(..., ge=0, examples=[3500])
    currency: str = Field(default="BOB", examples=["BOB"])
    operation_type: str = Field(..., examples=["Alquiler"])
    property_type: str = Field(..., examples=["Departamento"])
    zone: str = Field(..., examples=["Equipetrol"])
    image_url: str = Field(..., examples=[PLACEHOLDER_IMAGE_URL])
    amenities: list[str] = Field(default_factory=list)

    @classmethod
    def from_supabase_row(cls, row: dict) -> "PropertySummaryResponse":
        """Crea una respuesta limpia desde la view `property_cards`."""

        property_type = str(row.get("property_type") or "Inmueble")
        zone = str(row.get("zone") or "Sin zona")
        amenities = _to_string_list(row.get("amenities"))
        image_url = str(row.get("image_url") or PLACEHOLDER_IMAGE_URL)

        return cls(
            id=str(row.get("id")),
            title=str(row.get("title") or f"{property_type} en {zone}"),
            description=str(
                row.get("description")
                or (", ".join(amenities) if amenities else "Sin descripción")
            ),
            price=_to_float(row.get("price")),
            currency=str(row.get("currency") or "BOB"),
            operation_type=str(row.get("operation_type") or "Alquiler"),
            property_type=property_type,
            zone=zone,
            image_url=image_url,
            amenities=amenities,
        )


class PropertyDetailResponse(PropertySummaryResponse):
    """Propiedad detallada para pantalla de detalle."""

    owner_id: str | None = Field(default=None)
    owner_name: str | None = Field(default=None)
    owner_phone: str | None = Field(default=None)
    status: str | None = Field(default=None)
    images: list[str] = Field(default_factory=list)

    @classmethod
    def from_supabase_row(cls, row: dict) -> "PropertyDetailResponse":
        """Crea una respuesta detallada desde la view `property_cards`."""

        summary = PropertySummaryResponse.from_supabase_row(row)
        images = _to_string_list(row.get("images"))

        return cls(
            **summary.model_dump(),
            owner_id=row.get("owner_id"),
            owner_name=row.get("owner_name"),
            owner_phone=row.get("owner_phone"),
            status=row.get("status"),
            images=images or [summary.image_url],
        )


class PropertyListResponse(BaseModel):
    """Respuesta paginada para propiedades."""

    items: list[PropertySummaryResponse]
    pagination: PaginationMeta
